import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../constants/food_categories.dart';
import '../constants/ingredient_keywords.dart';
import '../models/product.dart';
import 'cache_service.dart';
import 'halal_rules_engine.dart';
import 'keyword_service.dart';
import 'test_product_repository.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  ProductService._internal();
  factory ProductService() => _instance;

  http.Client _httpClient = http.Client();

  @visibleForTesting
  void setHttpClientForTesting(http.Client client) => _httpClient = client;

  static const String _offBaseUrl =
      'https://world.openfoodfacts.org/api/v0/product';
  static const String _obfBaseUrl =
      'https://world.openbeautyfacts.org/api/v0/product';
  static const String _opfBaseUrl =
      'https://world.openproductsfacts.org/api/v0/product';

  final CacheService _cache = CacheService();
  final KeywordService _keywordService = KeywordService();

  final Map<String, String> _customHaramKeywords = {};
  final Map<String, String> _customSuspiciousKeywords = {};
  final Map<String, List<String>> _customHaramVariants = {};
  final Map<String, List<String>> _customSuspiciousVariants = {};
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
      final rawVariants = e['variants'];
      final variants = rawVariants is List && rawVariants.isNotEmpty
          ? List<String>.from(rawVariants)
          : [canonical];
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

  static String canonicalDisplay(String canonical, String locale) =>
      HalalRulesEngine.canonicalDisplay(canonical, locale);

  static bool isFattyAlcohol(String ingredient) =>
      HalalRulesEngine.isFattyAlcohol(ingredient);

  static bool matchesKeyword(String ingredient, String keyword) {
    return _rulesEngine.matchesKeyword(ingredient, keyword);
  }

  // Returns true when the product name suggests it is a meat/animal product,
  // used as a fallback when OFf category data is absent or unknown.
  static bool _nameIndicatesAnimalProduct(String nameLower) {
    return FoodCategories.animalProductNameTerms.any(
      (term) => RegExp(
        '(?<![a-zA-ZÀ-ɏ])${RegExp.escape(term)}(?![a-zA-ZÀ-ɏ])',
        caseSensitive: false,
      ).hasMatch(nameLower),
    );
  }

  static bool _nameIndicatesVeganOrVegetarian(String nameLower) {
    return FoodCategories.veganOrVegetarianNameTerms.any(
      (term) => RegExp(
        '(?<![a-zA-ZÀ-ɏ])${RegExp.escape(term)}(?![a-zA-ZÀ-ɏ])',
        caseSensitive: false,
      ).hasMatch(nameLower),
    );
  }

  // Returns true only when the ingredient text doesn't already contain the
  // canonical keyword — i.e. a translation label would actually add information.
  static ({
    bool isHalal,
    List<String> haram,
    List<String> suspicious,
    Map<String, String> warnings,
    Map<String, String> translations,
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
        explanation: explanation,
      );
    }
    if (allTranslations.isNotEmpty) {
      return product.copyWith(ingredientTranslations: allTranslations);
    }
    return product;
  }

  Future<Product?> refreshProduct(String barcode) async {
    // Managed products are never re-fetched from OFF.
    // Return the DB row directly so admin data is preserved.
    final dbProduct = await _fetchFromSharedDb(barcode);
    if (dbProduct != null && dbProduct.isManaged) {
      debugPrint('[Refresh $barcode] managed product — returning DB row as-is');
      await _cache.saveProduct(barcode, dbProduct);
      return dbProduct;
    }

    await _cache.removeProduct(barcode);
    return _getProduct(barcode, forceBackendRefresh: true);
  }

  // Read from the shared products table directly, bypassing the Edge Function.
  // This saves an invocation (Supabase free tier: 500K/month) for barcodes that
  // are already cached in the shared DB — no OFf fetch, no AI call needed.
  Future<Product?> _fetchFromSharedDb(String barcode) async {
    if (!AppConfig.hasSupabase) return null;
    try {
      final response = await _httpClient
          .get(
            Uri.parse(
              '${AppConfig.supabaseUrl}/rest/v1/products'
              '?barcode=eq.${Uri.encodeComponent(barcode)}&select=*&limit=1',
            ),
            headers: {
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'apikey': AppConfig.supabaseAnonKey,
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
        'requiresHalalCert': row['requires_halal_cert'] ?? false,
        'isManaged': row['is_managed'] ?? false,
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
  }) async {
    final result = await _fetchFromBackendOnce(barcode, force: force);
    if (result != null) return result;
    debugPrint('[Backend $barcode] retrying once...');
    return _fetchFromBackendOnce(barcode, force: force);
  }

  Future<Product?> _fetchFromBackendOnce(
    String barcode, {
    bool force = false,
  }) async {
    if (!AppConfig.hasSupabase) return null;
    try {
      final response = await _httpClient
          .post(
            Uri.parse('${AppConfig.supabaseUrl}/functions/v1/lookup-product'),
            headers: {
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'barcode': barcode, if (force) 'force': true}),
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
        if (!cached.isUnknown) return _mergeApprovedImages(cached, dbProduct);
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
      if (!dbProduct.isUnknown) {
        final safe = _applyKeywordSafety(dbProduct);
        await _cache.saveProduct(barcode, safe);
        return safe;
      }
      hadStaleUnknown = true;
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
      // Fall through to Step 4 only when the backend returned unknown —
      // OBF/OPF cross-check may confirm the product is non-food.
      if (!safe.isUnknown) {
        await _cache.saveProduct(barcode, safe);
        if (kDebugMode && hadStaleTestFixture) {
          await TestProductRepository.instance.upsert(safe);
        }
        return safe;
      }
      debugPrint(
        '[Lookup $barcode] Step 3 returned unknown — falling to Step 4',
      );
    }

    // Step 4: Fallback — try each open food database in order.
    // OBF (beauty) and OPF (general products) are non-food databases.
    //
    // Image URLs from Step 3 (edge function) are preserved here so that
    // approved community photos survive the raw OFF fetch, which has no
    // knowledge of our product_image_submissions table.
    const nonFoodUrls = {_obfBaseUrl, _opfBaseUrl};
    Product? offUnknown;
    for (final baseUrl in [_offBaseUrl, _obfBaseUrl, _opfBaseUrl]) {
      var product = await _fetchFromFoodApi(barcode, baseUrl);
      debugPrint(
        '[Lookup $barcode] Step 4 ($baseUrl): '
        'found=${product != null} name="${product?.name}" '
        'isUnknown=${product?.isUnknown} isNonFood=${product?.isNonFood} '
        'ingredients=${product?.ingredients.length ?? 0} '
        'labels=${product?.labels}',
      );
      if (product != null) {
        if (nonFoodUrls.contains(baseUrl)) {
          product = product.copyWith(
            isNonFood: true,
            isHalal: false,
            isUnknown: false,
            explanation:
                'This is a non-food product. Islamic dietary rules do not apply.',
          );
        }
        // If OFf returned unknown (no ingredient data, no category signal),
        // continue to OBF/OPF — a cross-listing there confirms it is non-food.
        if (product.isUnknown && baseUrl == _offBaseUrl) {
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
    return base.copyWith(
      imageUrl: approved.imageUrl ?? base.imageUrl,
      imageFrontUrl: approved.imageFrontUrl ?? base.imageFrontUrl,
      imageIngredientsUrl:
          approved.imageIngredientsUrl ?? base.imageIngredientsUrl,
      imageNutritionUrl: approved.imageNutritionUrl ?? base.imageNutritionUrl,
    );
  }

  Future<Product?> _fetchFromFoodApi(String barcode, String baseUrl) async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$baseUrl/$barcode.json'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data['status'] == 0) return null;

      final productData = data['product'] as Map<String, dynamic>;
      final name =
          (productData['product_name']?.toString() ?? '').trim().isEmpty
          ? (productData['product_name_en']?.toString() ??
                productData['abbreviated_product_name']?.toString() ??
                'Unknown Product')
          : productData['product_name'].toString();

      // Ingredient text — try multiple language fields and structured array
      String ingredientsText = (productData['ingredients_text'] ?? '')
          .toString()
          .trim();
      if (ingredientsText.isEmpty) {
        for (final lang in [
          'en',
          'nl',
          'de',
          'fr',
          'tr',
          'es',
          'it',
          'sr',
          'hu',
          'cs',
        ]) {
          final langText = (productData['ingredients_text_$lang'] ?? '')
              .toString()
              .trim();
          if (langText.isNotEmpty) {
            ingredientsText = langText;
            break;
          }
        }
      }
      if (ingredientsText.isEmpty) {
        final structured = productData['ingredients'];
        if (structured is List && structured.isNotEmpty) {
          ingredientsText = structured
              .whereType<Map>()
              .map((i) => i['text']?.toString() ?? '')
              .where((t) => t.isNotEmpty)
              .join(', ');
        }
      }
      ingredientsText = ingredientsText.toLowerCase();

      String? optimizeImageUrl(String? url) {
        if (url == null || url.isEmpty) return null;
        return url
            .replaceAll('.100.', '.400.')
            .replaceAll('.200.', '.400.')
            .replaceAll('.300.', '.400.');
      }

      // Images — prefer direct fields, fall back to selected_images
      String? resolveImage(String directField, String selectedKey) {
        final direct = optimizeImageUrl(productData[directField]?.toString());
        if (direct != null) return direct;
        final sel = productData['selected_images'];
        if (sel is Map) {
          final section = sel[selectedKey];
          if (section is Map) {
            final display = section['display'];
            if (display is Map && display.isNotEmpty) {
              return optimizeImageUrl(display.values.first?.toString());
            }
          }
        }
        return null;
      }

      final imageUrl = resolveImage('image_url', 'front');
      final imageFrontUrl = resolveImage('image_front_url', 'front');
      final imageIngredientsUrl = resolveImage(
        'image_ingredients_url',
        'ingredients',
      );
      final imageNutritionUrl = resolveImage(
        'image_nutrition_url',
        'nutrition',
      );

      final labelSet = <String>{};
      void addLabelValue(Object? value) {
        if (value == null) return;
        if (value is String) {
          for (final part in value.split(RegExp(r'[,;]'))) {
            final normalized = part.trim().toLowerCase();
            if (normalized.isNotEmpty) labelSet.add(normalized);
          }
        } else if (value is List) {
          for (final item in value) {
            if (item is String) {
              final normalized = item.trim().toLowerCase();
              if (normalized.isNotEmpty) labelSet.add(normalized);
            }
          }
        }
      }

      addLabelValue(productData['labels']);
      addLabelValue(productData['labels_tags']);
      addLabelValue(productData['labels_hierarchy']);
      addLabelValue(productData['labels_en']);
      final labels = labelSet.toList();

      final ingredients = ingredientsText
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Extract canonical IDs from the structured ingredients array for
      // supplementary keyword analysis. OFf normalises these (e.g. "en:pork")
      // so they catch matches that the label's free-form text may omit when
      // the language is not covered by our variant lists.
      final List<String> ingredientIds = [];
      void addId(Map<dynamic, dynamic> item) {
        final id = (item['id'] ?? '').toString();
        if (id.isNotEmpty) {
          final canonical = id
              .replaceFirst(RegExp(r'^[a-z]{2,3}:'), '')
              .replaceAll('-', ' ');
          if (canonical.isNotEmpty) ingredientIds.add(canonical);
        }
        final sub = item['ingredients'];
        if (sub is List) {
          for (final s in sub.whereType<Map<dynamic, dynamic>>()) {
            addId(s);
          }
        }
      }

      final rawStructuredIngredients = productData['ingredients'];
      if (rawStructuredIngredients is List) {
        for (final item
            in rawStructuredIngredients.whereType<Map<dynamic, dynamic>>()) {
          addId(item);
        }
      }

      final rawCategories = productData['categories_tags'];
      final bool isNonFoodByCategory =
          rawCategories is List &&
          rawCategories.any(
            (c) => FoodCategories.nonFood.contains(c.toString().toLowerCase()),
          );
      final bool haramByCategory =
          !isNonFoodByCategory &&
          rawCategories is List &&
          rawCategories.any(
            (c) => FoodCategories.haram.contains(c.toString().toLowerCase()),
          );
      final bool halalByCategory =
          !isNonFoodByCategory &&
          !haramByCategory &&
          rawCategories is List &&
          rawCategories.any(
            (c) => FoodCategories.halal.contains(c.toString().toLowerCase()),
          );

      final fallback = analyzeWithKeywords(ingredients);

      // Also analyse canonical IDs; merge extra matches the text analysis missed.
      final idAnalysis = analyzeWithKeywords(ingredientIds);
      final textHaramLower = fallback.haram.map((s) => s.toLowerCase()).toSet();
      final extraIdHaram = idAnalysis.haram
          .where((s) => !textHaramLower.contains(s.toLowerCase()))
          .toList();
      final textSuspiciousLower = fallback.suspicious
          .map((s) => s.toLowerCase())
          .toSet();
      final extraIdSuspicious = idAnalysis.suspicious
          .where((s) => !textSuspiciousLower.contains(s.toLowerCase()))
          .toList();

      // When no ingredient data at all, check the product name itself.
      // Names like "Wieselburger Bier" or "Rosé Wine" contain haram keywords
      // that make the verdict unambiguous without needing ingredient data.
      final nameCheck = ingredients.isEmpty && ingredientIds.isEmpty
          ? analyzeWithKeywords([name.toLowerCase()])
          : null;

      final List<String> haramIngredients = [
        ...(fallback.haram.isNotEmpty
            ? fallback.haram
            : (nameCheck?.haram ?? [])),
        ...extraIdHaram,
      ];
      final List<String> suspiciousIngredients = [
        ...(fallback.suspicious.isNotEmpty
            ? fallback.suspicious
            : (nameCheck?.suspicious ?? [])),
        ...extraIdSuspicious,
      ];
      final Map<String, String> ingredientWarnings = {
        ...(fallback.warnings.isNotEmpty
            ? fallback.warnings
            : (nameCheck?.warnings ?? {})),
        for (final id in extraIdHaram) id: idAnalysis.warnings[id] ?? '',
        for (final id in extraIdSuspicious) id: idAnalysis.warnings[id] ?? '',
      };

      if (isNonFoodByCategory) {
        return Product(
          barcode: barcode,
          name: name,
          ingredients: const [],
          isHalal: false,
          isUnknown: false,
          isNonFood: true,
          haramIngredients: const [],
          suspiciousIngredients: const [],
          ingredientWarnings: const {},
          ingredientTranslations: const {},
          labels: labels,
          imageUrl: imageUrl,
          imageFrontUrl: imageFrontUrl,
          imageIngredientsUrl: imageIngredientsUrl,
          imageNutritionUrl: imageNutritionUrl,
          explanation:
              'This is a non-food product. Islamic dietary rules do not apply.',
          analyzedByAI: false,
        );
      }

      // Halal-by-category overrides unknown when no ingredients are listed.
      final bool isHalalByCategory =
          halalByCategory && ingredients.isEmpty && haramIngredients.isEmpty;

      // Animal product without halal certification: flagged as not halal even
      // when no haram keywords are found. Detection uses OFf category tags
      // first; if those are absent/unknown the product name is checked as a
      // fallback (covers e.g. "Faschiertes" with sparse category data).
      final bool categoryIsAnimalProduct =
          rawCategories is List &&
          rawCategories.any(
            (c) => FoodCategories.animalProduct.contains(
              c.toString().toLowerCase(),
            ),
          );
      final bool nameIsAnimalProduct =
          !categoryIsAnimalProduct &&
          (rawCategories is! List ||
              (rawCategories).every(
                (c) => c.toString().toLowerCase().contains('unknown'),
              )) &&
          _nameIndicatesAnimalProduct(name.toLowerCase());
      final bool hasVeganOrVegetarianEvidence =
          labels.any(
            (l) => FoodCategories.veganOrVegetarianLabels.contains(
              l.toLowerCase(),
            ),
          ) ||
          _nameIndicatesVeganOrVegetarian(name.toLowerCase());
      final bool isAnimalProduct =
          (categoryIsAnimalProduct || nameIsAnimalProduct) &&
          !hasVeganOrVegetarianEvidence;
      final bool hasHalalCert = labels.any(
        (l) =>
            FoodCategories.halalCertificationLabels.contains(l.toLowerCase()),
      );
      // Only apply this rule when no haram ingredient was already found and the
      // product is not already in a haram/non-food category.
      final bool requiresHalalCert =
          isAnimalProduct &&
          !hasHalalCert &&
          !isNonFoodByCategory &&
          !haramByCategory &&
          !halalByCategory &&
          haramIngredients.isEmpty;

      final bool isUnknown =
          ingredients.isEmpty &&
          ingredientIds.isEmpty &&
          (nameCheck?.isHalal ?? true) &&
          !haramByCategory &&
          !isHalalByCategory &&
          !requiresHalalCert;

      final String explanation;
      if (haramByCategory &&
          fallback.haram.isEmpty &&
          extraIdHaram.isEmpty &&
          (nameCheck?.isHalal ?? true)) {
        explanation =
            'This product belongs to a category that is not permissible: '
            '${rawCategories.firstWhere((c) => FoodCategories.haram.contains(c.toString().toLowerCase()))}.';
      } else if (isHalalByCategory) {
        explanation =
            'This product is in an inherently halal category (e.g. water, salt). No harmful ingredients expected.';
      } else if (requiresHalalCert) {
        explanation = '';
      } else if (isUnknown) {
        explanation =
            'No ingredient data found. Halal status cannot be determined — check the packaging directly.';
      } else if (nameCheck != null && !nameCheck.isHalal) {
        explanation =
            'No ingredient list found, but the product name contains a haram indicator: '
            '${nameCheck.haram.join(', ')}.';
      } else {
        explanation = ingredients.isNotEmpty
            ? fallback.explanation
            : idAnalysis.explanation;
      }

      return Product(
        barcode: barcode,
        name: name,
        ingredients: ingredients,
        isHalal:
            isHalalByCategory ||
            (!isUnknown &&
                !haramByCategory &&
                haramIngredients.isEmpty &&
                !requiresHalalCert),
        isUnknown: isUnknown,
        haramIngredients: haramIngredients,
        suspiciousIngredients: suspiciousIngredients,
        ingredientWarnings: ingredientWarnings,
        ingredientTranslations: {
          ...fallback.translations,
          ...(nameCheck?.translations ?? {}),
        },
        labels: labels,
        imageUrl: imageUrl,
        imageFrontUrl: imageFrontUrl,
        imageIngredientsUrl: imageIngredientsUrl,
        imageNutritionUrl: imageNutritionUrl,
        explanation: explanation,
        analyzedByAI: false,
        requiresHalalCert: requiresHalalCert,
      );
    } catch (_) {
      return null;
    }
  }
}
