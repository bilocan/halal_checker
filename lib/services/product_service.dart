import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../constants/food_categories.dart';
import '../constants/ingredient_keywords.dart';
import '../models/product.dart';
import 'cache_service.dart';
import 'halal_rules_engine.dart';
import 'off_fetcher.dart';
import 'keyword_normalization.dart';
import 'keyword_service.dart';
import 'test_product_repository.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  ProductService._internal();
  factory ProductService() => _instance;

  http.Client _httpClient = http.Client();

  @visibleForTesting
  void setHttpClientForTesting(http.Client client) => _httpClient = client;

  String? _testSupabaseUrl;
  String? _testSupabaseKey;

  bool get _hasSupabase => _testSupabaseUrl != null || AppConfig.hasSupabase;
  String get _supabaseUrl => _testSupabaseUrl ?? AppConfig.supabaseUrl;
  String get _supabaseKey => _testSupabaseKey ?? AppConfig.supabaseAnonKey;

  @visibleForTesting
  void enableSupabaseForTesting({required String url, required String key}) {
    _testSupabaseUrl = url;
    _testSupabaseKey = key;
  }

  @visibleForTesting
  void resetForTesting() {
    _testSupabaseUrl = null;
    _testSupabaseKey = null;
    _customKeywordsFuture = null;
    _cachedCustomEngine = null;
    _customHaramKeywords.clear();
    _customSuspiciousKeywords.clear();
    _customHaramVariants.clear();
    _customSuspiciousVariants.clear();
    _customDisplayNames.clear();
  }

  final CacheService _cache = CacheService();
  final KeywordService _keywordService = KeywordService();

  final Map<String, String> _customHaramKeywords = {};
  final Map<String, String> _customSuspiciousKeywords = {};
  final Map<String, List<String>> _customHaramVariants = {};
  final Map<String, List<String>> _customSuspiciousVariants = {};
  static final Map<String, Map<String, String>> _customDisplayNames = {};
  Future<void>? _customKeywordsFuture;

  // Public aliases kept for callers that reference ProductService directly.
  static const haramKeywords = IngredientKeywords.haram;
  static const suspiciousKeywords = IngredientKeywords.suspicious;
  static const HalalRulesEngine _rulesEngine = HalalRulesEngine();
  static int get keywordRuleCount =>
      IngredientKeywords.haram.length + IngredientKeywords.suspicious.length;

  HalalRulesEngine? _cachedCustomEngine;

  Future<void> _loadCustomKeywords() async {
    _customKeywordsFuture ??= _doLoadCustomKeywords();
    await _customKeywordsFuture;
  }

  Future<void> _doLoadCustomKeywords() async {
    final entries = await _keywordService.fetchCustomKeywords();
    for (final e in entries) {
      final canonical = e['canonical'] as String;
      final reason = e['reason'] as String;
      final category = e['category'] as String;
      final translations = KeywordNormalization.parseTranslations(
        e['translations'],
      );
      if (translations.isNotEmpty) {
        _customDisplayNames[canonical] = translations;
      }
      final rawVariants = e['variants'];
      final variants = KeywordNormalization.mergeVariants(
        canonical: canonical,
        variants: rawVariants is List ? List<String>.from(rawVariants) : null,
        translations: translations,
      );
      if (category == 'haram') {
        _customHaramKeywords[canonical] = reason;
        _customHaramVariants[canonical] = variants;
      } else {
        _customSuspiciousKeywords[canonical] = reason;
        _customSuspiciousVariants[canonical] = variants;
      }
    }
    _cachedCustomEngine = HalalRulesEngine(
      rules: HalalKeywordRuleSet(
        haram: _customHaramKeywords,
        suspicious: _customSuspiciousKeywords,
        haramVariants: _customHaramVariants,
        suspiciousVariants: _customSuspiciousVariants,
      ),
    );
  }

  static String canonicalDisplay(String canonical, String locale) {
    final custom = _customDisplayNames[canonical]?[locale];
    if (custom != null) return custom;
    return HalalRulesEngine.canonicalDisplay(canonical, locale);
  }

  static bool isFattyAlcohol(String ingredient) =>
      HalalRulesEngine.isFattyAlcohol(ingredient);

  static bool matchesKeyword(String ingredient, String keyword) {
    return _rulesEngine.matchesKeyword(ingredient, keyword);
  }

  // A product is stale when its source data changed after the last analysis.
  // The DB trigger bumps updated_at on ingredient/name/label/is_non_food edits.
  static bool _isStale(Product? p) {
    if (p == null || p.updatedAt == null) return false;
    final analysed = p.lastAnalysedAt;
    return analysed == null || analysed.isBefore(p.updatedAt!);
  }

  // Returns true only when the ingredient text doesn't already contain the
  // canonical keyword — i.e. a translation label would actually add information.
  static ({
    bool isHalal,
    List<String> haram,
    List<String> suspicious,
    Map<String, String> warnings,
    Map<String, String> translations,
    Map<String, String> canonicals,
    String explanation,
  })
  analyzeWithKeywords(List<String> ingredients) {
    final result = _rulesEngine.analyzeIngredients(ingredients);

    return (
      isHalal: result.isHalal,
      haram: result.haram,
      suspicious: result.suspicious,
      warnings: result.warnings,
      translations: result.translations,
      canonicals: result.canonicals,
      explanation: result.explanation,
    );
  }

  ({
    bool isHalal,
    List<String> haram,
    List<String> suspicious,
    Map<String, String> warnings,
    Map<String, String> translations,
  })
  _customKeywordAnalysis(List<String> ingredients) {
    final engine = _cachedCustomEngine ?? const HalalRulesEngine();
    final result = engine.analyzeIngredients(ingredients);

    return (
      isHalal: result.isHalal,
      haram: result.haram,
      suspicious: result.suspicious,
      warnings: result.warnings,
      translations: result.translations,
    );
  }

  Product _applyKeywordSafety(Product product) {
    final kwCheck = analyzeWithKeywords(product.ingredients);
    final customCheck = _customKeywordAnalysis(product.ingredients);

    // Also analyze the already-flagged ingredients directly: their exact strings
    // (from AI) may differ in case/spacing from product.ingredients entries, so
    // a plain analyzeWithKeywords pass can miss them. This ensures every flagged
    // ingredient gets a canonical key that matches what the UI looks up.
    final flaggedIngredients = [
      ...product.haramIngredients,
      ...product.suspiciousIngredients,
    ];
    final flaggedCheck = flaggedIngredients.isEmpty
        ? null
        : analyzeWithKeywords(flaggedIngredients);

    final allHaram = {
      ...product.haramIngredients,
      ...kwCheck.haram,
      ...customCheck.haram,
    }.toList();
    final allWarnings = {
      ...product.ingredientWarnings,
      ...kwCheck.warnings,
      ...customCheck.warnings,
    };
    final allTranslations = {
      ...product.ingredientTranslations,
      ...kwCheck.translations,
      ...customCheck.translations,
    };
    final allCanonicals = {
      ...product.ingredientCanonicals,
      ...kwCheck.canonicals,
      if (flaggedCheck != null) ...flaggedCheck.canonicals,
    };
    final isNowHaram = allHaram.isNotEmpty;

    if (isNowHaram && product.isHalal) {
      final explanation = kwCheck.haram.isNotEmpty
          ? kwCheck.explanation
          : 'This product contains ingredient(s) that are not permissible: '
                '${customCheck.haram.join(', ')}. '
                'Flagged by custom keyword.';
      return product.copyWith(
        isHalal: false,
        haramIngredients: allHaram,
        ingredientWarnings: allWarnings,
        ingredientTranslations: allTranslations,
        ingredientCanonicals: allCanonicals,
        explanation: explanation,
      );
    }
    if (allTranslations.isNotEmpty || allCanonicals.isNotEmpty) {
      return product.copyWith(
        ingredientTranslations: allTranslations,
        ingredientCanonicals: allCanonicals,
      );
    }
    return product;
  }

  Future<Product?> refreshProduct(String barcode) async {
    await _loadCustomKeywords();
    await _cache.removeProduct(barcode);

    // Managed products: re-run keyword analysis on the stored ingredients and
    // write the updated verdict back to Supabase. No OFF re-fetch needed.
    final dbProduct = await _fetchFromSharedDb(barcode);
    if (dbProduct != null && dbProduct.isManaged) {
      final reanalyzed = _reanalyzeStoredProduct(dbProduct);
      await _patchManagedProductAnalysis(barcode, reanalyzed);
      await _cache.saveProduct(barcode, reanalyzed);
      if (kDebugMode) {
        await TestProductRepository.instance.upsert(reanalyzed);
      }
      debugPrint('[Refresh $barcode] managed product — re-analyzed and saved');
      return reanalyzed;
    }

    return _getProduct(barcode, forceBackendRefresh: true);
  }

  Product _reanalyzeStoredProduct(Product product) {
    if (product.ingredients.isEmpty) return product;
    final kwResult = analyzeWithKeywords(product.ingredients);
    final customResult = _customKeywordAnalysis(product.ingredients);
    final allHaram = {...kwResult.haram, ...customResult.haram}.toList();
    final allSuspicious = {
      ...kwResult.suspicious,
      ...customResult.suspicious,
    }.toList();

    // Re-derive requiresHalalCert from name + labels. OFF category data is not
    // stored, so we fall back to name-based detection only.
    final nameLower = product.name.toLowerCase();
    final nameIsAnimalProduct = OffFetcher.nameIndicatesAnimalProduct(
      nameLower,
    );
    final hasVeganOrVegetarianEvidence =
        product.labels.any(
          (l) =>
              FoodCategories.veganOrVegetarianLabels.contains(l.toLowerCase()),
        ) ||
        OffFetcher.nameIndicatesVeganOrVegetarian(nameLower);
    final hasHalalCert = product.labels.any(
      (l) => FoodCategories.halalCertificationLabels.contains(l.toLowerCase()),
    );
    final requiresHalalCert =
        nameIsAnimalProduct &&
        !hasVeganOrVegetarianEvidence &&
        !hasHalalCert &&
        allHaram.isEmpty;

    return product.copyWith(
      isHalal: allHaram.isEmpty && !requiresHalalCert,
      isUnknown: false,
      haramIngredients: allHaram,
      suspiciousIngredients: allSuspicious,
      ingredientWarnings: {...kwResult.warnings, ...customResult.warnings},
      ingredientTranslations: {
        ...kwResult.translations,
        ...customResult.translations,
      },
      ingredientCanonicals: kwResult.canonicals,
      explanation: kwResult.explanation,
      analyzedByAI: false,
      analysisMethod: 'keyword',
      requiresHalalCert: requiresHalalCert,
      lastAnalysedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> _patchManagedProductAnalysis(
    String barcode,
    Product product,
  ) async {
    if (!AppConfig.hasSupabase) return;
    try {
      await _httpClient
          .patch(
            Uri.parse(
              '${AppConfig.supabaseUrl}/rest/v1/products'
              '?barcode=eq.${Uri.encodeComponent(barcode)}',
            ),
            headers: {
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'apikey': AppConfig.supabaseAnonKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'is_halal': product.isHalal,
              'is_unknown': product.isUnknown,
              'haram_ingredients': jsonEncode(product.haramIngredients),
              'suspicious_ingredients': jsonEncode(
                product.suspiciousIngredients,
              ),
              'ingredient_warnings': jsonEncode(product.ingredientWarnings),
              'explanation': product.explanation,
              'analyzed_by_ai': false,
              'requires_halal_cert': product.requiresHalalCert,
              'last_analysed_at': DateTime.now().toIso8601String(),
              'fetched_at': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // Read from the shared products table directly, bypassing the Edge Function.
  // This saves an invocation (Supabase free tier: 500K/month) for barcodes that
  // are already cached in the shared DB — no OFf fetch, no AI call needed.
  Future<Product?> _fetchFromSharedDb(String barcode) async {
    if (!_hasSupabase) return null;
    try {
      final response = await _httpClient
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/products'
              '?barcode=eq.${Uri.encodeComponent(barcode)}&select=*&limit=1',
            ),
            headers: {
              'Authorization': 'Bearer $_supabaseKey',
              'apikey': _supabaseKey,
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final list = json.decode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;
      final row = list.first as Map<String, dynamic>;
      final fetchedAt = DateTime.tryParse(row['fetched_at'] as String? ?? '');
      if (fetchedAt == null) return null;
      return Product.fromJson({
        'barcode': row['barcode'],
        'name': row['name'],
        'ingredients': row['ingredients'],
        'isHalal': row['is_halal'],
        'isUnknown': row['is_unknown'] ?? false,
        'isNonFood': row['is_non_food'] ?? false,
        'haramIngredients': row['haram_ingredients'],
        'suspiciousIngredients': row['suspicious_ingredients'],
        'ingredientWarnings': row['ingredient_warnings'],
        'labels': row['labels'],
        'imageUrl': row['image_url'],
        'imageFrontUrl': row['image_front_url'],
        'imageIngredientsUrl': row['image_ingredients_url'],
        'imageNutritionUrl': row['image_nutrition_url'],
        'explanation': row['explanation'] ?? '',
        'analyzedByAI': row['analyzed_by_ai'] ?? false,
        'analysisMethod': (row['analyzed_by_ai'] as bool? ?? false)
            ? 'ai'
            : 'keyword',
        'ingredientSource': row['ingredient_source'],
        'requiresHalalCert': row['requires_halal_cert'] ?? false,
        'isManaged': row['is_managed'] ?? false,
        'updatedAt': row['updated_at'],
        'lastAnalysedAt': row['last_analysed_at'],
      });
    } catch (_) {
      return null;
    }
  }

  // Try the Supabase Edge Function. Retries once on failure before returning
  // null so the caller can fall back to direct OpenFoodFacts + keyword analysis.
  Future<Product?> _fetchFromBackend(
    String barcode, {
    bool force = false,
    bool fetchAiIngredients = false,
  }) async {
    final result = await _fetchFromBackendOnce(
      barcode,
      force: force,
      fetchAiIngredients: fetchAiIngredients,
    );
    if (result != null) return result;
    debugPrint('[Backend $barcode] retrying once...');
    return _fetchFromBackendOnce(
      barcode,
      force: force,
      fetchAiIngredients: fetchAiIngredients,
    );
  }

  Future<Product?> fetchIngredientsByAI(String barcode) async {
    final product = await _fetchFromBackend(barcode, fetchAiIngredients: true);
    if (product != null) await _cache.saveProduct(barcode, product);
    return product;
  }

  Future<Product?> _fetchFromBackendOnce(
    String barcode, {
    bool force = false,
    bool fetchAiIngredients = false,
  }) async {
    if (!_hasSupabase) return null;
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_supabaseUrl/functions/v1/lookup-product'),
            headers: {
              'Authorization': 'Bearer $_supabaseKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'barcode': barcode,
              if (force) 'force': true,
              if (fetchAiIngredients) 'fetchAiIngredients': true,
            }),
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('[Backend $barcode] HTTP ${response.statusCode}');
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['product'] == null) {
        debugPrint('[Backend $barcode] response had null product');
        return null;
      }
      final product = Product.fromJson(data['product'] as Map<String, dynamic>);
      debugPrint(
        '[Backend $barcode] images — '
        'front=${product.imageFrontUrl} '
        'ingredients=${product.imageIngredientsUrl} '
        'nutrition=${product.imageNutritionUrl}',
      );
      return product;
    } catch (e) {
      debugPrint('[Backend $barcode] exception: $e');
      return null;
    }
  }

  Future<Product?> fetchFromSharedDbForDebug(String barcode) =>
      _fetchFromSharedDb(barcode);

  Future<Product?> getProduct(String barcode) =>
      _getProduct(barcode, forceBackendRefresh: false);

  Future<Product?> _getProduct(
    String barcode, {
    required bool forceBackendRefresh,
  }) async {
    await _loadCustomKeywords();

    // Step 0 (debug only): return fixture from test DB without touching cache/network.
    // Skip stale "unknown" fixtures so they fall through to the live pipeline and get
    // resolved; the fresh result is written back to the test DB below.
    // Bypassed entirely on force-refresh so the refresh button always hits the network.
    var hadStaleTestFixture = false;
    if (kDebugMode && !forceBackendRefresh) {
      final fixture = await TestProductRepository.instance.getByBarcode(
        barcode,
      );
      debugPrint(
        '[Lookup $barcode] Step 0 (testDB): '
        'found=${fixture != null} isUnknown=${fixture?.isUnknown}',
      );
      if (fixture != null) {
        if (!fixture.isUnknown) return fixture;
        hadStaleTestFixture = true;
      }
    }

    // Fetch shared DB product first — a fast Supabase REST read (not the Edge
    // Function). Used for community-approved image URLs at every return point
    // so that approved images are always current, even on a cache hit.
    final dbProduct = await _fetchFromSharedDb(barcode);
    debugPrint(
      '[Lookup $barcode] sharedDB (imageSource): '
      'found=${dbProduct != null} isUnknown=${dbProduct?.isUnknown} '
      'front=${dbProduct?.imageFrontUrl} '
      'ingredients=${dbProduct?.imageIngredientsUrl}',
    );

    // Step 1: Check local cache (fast path — analysis data only).
    // Community image URLs from the DB are merged in before returning so that
    // approved images are applied even when the analysis result is cached.
    var hadStaleUnknown = false;
    if (!forceBackendRefresh) {
      final cached = await _cache.getProduct(barcode);
      debugPrint(
        '[Lookup $barcode] Step 1 (cache): '
        'found=${cached != null} isUnknown=${cached?.isUnknown}',
      );
      if (cached != null) {
        if (!cached.isUnknown) {
          // Managed (admin-curated) products always come from the DB so that
          // admin edits are reflected immediately instead of serving a stale
          // local cache entry that predates the curation.
          if (dbProduct != null && dbProduct.isManaged) {
            final safe = _applyKeywordSafety(dbProduct);
            await _cache.saveProduct(barcode, safe);
            return safe;
          }
          if (!_isStale(dbProduct)) {
            final merged = _mergeApprovedImages(cached, dbProduct);
            // Backfill ingredientCanonicals for products cached before that
            // field was introduced (they have warnings but empty canonicals).
            if (merged.ingredientCanonicals.isEmpty &&
                merged.ingredientWarnings.isNotEmpty) {
              final safe = _applyKeywordSafety(merged);
              await _cache.saveProduct(barcode, safe);
              return safe;
            }
            return merged;
          }
          // stale (updated_at > last_analysed_at): fall through so the EF re-analyses
        }
        hadStaleUnknown = true;
      }
    }

    // Step 2: Shared DB read — cheaper than an Edge Function invocation for
    // barcodes another user has already scanned (no AI, no OFf fetch needed).
    if (!forceBackendRefresh && dbProduct != null) {
      debugPrint(
        '[Lookup $barcode] Step 2 (sharedDB): '
        'isUnknown=${dbProduct.isUnknown} isNonFood=${dbProduct.isNonFood}',
      );
      if (!dbProduct.isUnknown && !_isStale(dbProduct)) {
        final safe = _applyKeywordSafety(dbProduct);
        await _cache.saveProduct(barcode, safe);
        return safe;
      }
      if (dbProduct.isUnknown) hadStaleUnknown = true;
    }

    debugPrint(
      '[Lookup $barcode] hadStaleUnknown=$hadStaleUnknown '
      'hadStaleTestFixture=$hadStaleTestFixture '
      'forceBackendRefresh=$forceBackendRefresh',
    );

    // Step 3: Edge Function (fetches OFf + runs AI + saves to shared DB).
    // Force a fresh fetch if we detected a stale "unknown" in Steps 1 or 2
    // so the Edge Function bypasses its own Supabase cache too.
    final backendProduct = await _fetchFromBackend(
      barcode,
      force: forceBackendRefresh || hadStaleUnknown || hadStaleTestFixture,
    );
    debugPrint(
      '[Lookup $barcode] Step 3 (edgeFn): '
      'found=${backendProduct != null} isUnknown=${backendProduct?.isUnknown} '
      'isNonFood=${backendProduct?.isNonFood}',
    );
    if (backendProduct != null) {
      final safe = _applyKeywordSafety(
        _mergeApprovedImages(backendProduct, dbProduct),
      );
      // Fall through to Step 4 only when the backend returned unknown AND has
      // no ingredients — OBF/OPF cross-check may confirm the product is non-food.
      // If the backend already found ingredients (e.g. via Gemini lookup), keep
      // that result even if the verdict is still unknown.
      if (!safe.isUnknown || safe.ingredients.isNotEmpty) {
        await _cache.saveProduct(barcode, safe);
        if (kDebugMode && hadStaleTestFixture) {
          await TestProductRepository.instance.upsert(safe);
        }
        return safe;
      }
      debugPrint(
        '[Lookup $barcode] Step 3 returned unknown with no ingredients — falling to Step 4',
      );
    }

    // Step 4: Fallback — try each open food database in order.
    // OBF (beauty) and OPF (general products) are non-food databases.
    //
    // Image URLs from Step 3 (edge function) are preserved here so that
    // approved community photos survive the raw OFF fetch, which has no
    // knowledge of our product_image_submissions table.
    Product? offUnknown;
    for (final baseUrl in OffFetcher.baseUrls) {
      var product = await OffFetcher(_httpClient).fetch(barcode, baseUrl);
      debugPrint(
        '[Lookup $barcode] Step 4 ($baseUrl): '
        'found=${product != null} name="${product?.name}" '
        'isUnknown=${product?.isUnknown} isNonFood=${product?.isNonFood} '
        'ingredients=${product?.ingredients.length ?? 0} '
        'labels=${product?.labels}',
      );
      if (product != null) {
        if (OffFetcher.nonFoodBaseUrls.contains(baseUrl)) {
          product = product.copyWith(
            isNonFood: true,
            isHalal: false,
            isUnknown: false,
            explanation: '',
          );
        }
        // If OFf returned unknown (no ingredient data, no category signal),
        // continue to OBF/OPF — a cross-listing there confirms it is non-food.
        if (product.isUnknown && baseUrl == OffFetcher.offBaseUrl) {
          offUnknown = product;
          debugPrint('[Lookup $barcode] Step 4: OFf unknown — probing OBF/OPF');
          continue;
        }
        debugPrint(
          '[Lookup $barcode] Step 4 merge: '
          'backendIngredients=${backendProduct?.imageIngredientsUrl} '
          'dbIngredients=${dbProduct?.imageIngredientsUrl}',
        );
        final safe = _applyKeywordSafety(
          _mergeApprovedImages(
            _mergeApprovedImages(product, backendProduct),
            dbProduct,
          ),
        );
        await _cache.saveProduct(barcode, safe);
        if (kDebugMode && hadStaleTestFixture) {
          await TestProductRepository.instance.upsert(safe);
        }
        return safe;
      }
    }
    debugPrint(
      '[Lookup $barcode] Step 4: OBF/OPF not found — '
      'returning offUnknown=${offUnknown != null}',
    );
    // OBF/OPF had no entry — return the OFf unknown result if we have one.
    if (offUnknown != null) {
      debugPrint(
        '[Lookup $barcode] Step 4 merge (offUnknown): '
        'backendIngredients=${backendProduct?.imageIngredientsUrl} '
        'dbIngredients=${dbProduct?.imageIngredientsUrl}',
      );
      final safe = _applyKeywordSafety(
        _mergeApprovedImages(
          _mergeApprovedImages(offUnknown, backendProduct),
          dbProduct,
        ),
      );
      await _cache.saveProduct(barcode, safe);
      if (kDebugMode && hadStaleTestFixture) {
        await TestProductRepository.instance.upsert(safe);
      }
      return safe;
    }
    return null;
  }

  static Product _mergeApprovedImages(Product base, Product? approved) {
    if (approved == null) return base;
    // Approved (community) images take priority over the base (OFF) image so
    // that a user-submitted replacement is always shown instead of the bad one.
    // Product name from the remote DB is also preferred to keep it in sync.
    return base.copyWith(
      name: approved.name,
      imageUrl: approved.imageUrl ?? base.imageUrl,
      imageFrontUrl: approved.imageFrontUrl ?? base.imageFrontUrl,
      imageIngredientsUrl:
          approved.imageIngredientsUrl ?? base.imageIngredientsUrl,
      imageNutritionUrl: approved.imageNutritionUrl ?? base.imageNutritionUrl,
      // Shared DB is authoritative for where ingredients came from; cache
      // entries written before ingredient_source existed may omit it.
      ingredientSource: approved.ingredientSource ?? base.ingredientSource,
    );
  }
}
