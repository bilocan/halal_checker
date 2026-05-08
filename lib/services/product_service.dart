import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../constants/food_categories.dart';
import '../constants/ingredient_display_names.dart';
import '../constants/ingredient_keywords.dart';
import '../models/product.dart';
import 'cache_service.dart';
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
  bool _customKeywordsLoaded = false;

  // Public aliases kept for callers that reference ProductService directly.
  static const haramKeywords = IngredientKeywords.haram;
  static const suspiciousKeywords = IngredientKeywords.suspicious;

  Future<void> _loadCustomKeywords() async {
    if (_customKeywordsLoaded) return;
    _customKeywordsLoaded = true;
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
  }

  static String canonicalDisplay(String canonical, String locale) =>
      IngredientDisplayNames.of(canonical, locale);

  static bool isFattyAlcohol(String ingredient) =>
      IngredientKeywords.fattyAlcoholPrefix.hasMatch(ingredient);

  static bool _matchesVariant(String ingredient, String variant) {
    if (variant.contains(' ')) {
      return ingredient.toLowerCase().contains(variant.toLowerCase());
    }
    final escaped = RegExp.escape(variant);
    if (IngredientKeywords.alcoholFamily.contains(variant.toLowerCase())) {
      if (IngredientKeywords.fattyAlcoholPrefix.hasMatch(ingredient)) {
        return false;
      }
      return RegExp(
        '${IngredientKeywords.wPre}$escaped${IngredientKeywords.wPost}(?![-\\s]*free)',
        caseSensitive: false,
      ).hasMatch(ingredient);
    }
    return RegExp(
      '${IngredientKeywords.wPre}$escaped${IngredientKeywords.wPost}',
      caseSensitive: false,
    ).hasMatch(ingredient);
  }

  static bool matchesKeyword(String ingredient, String keyword) {
    final variants =
        IngredientKeywords.haramVariants[keyword] ??
        IngredientKeywords.suspiciousVariants[keyword] ??
        [keyword];
    return variants.any((v) => _matchesVariant(ingredient, v));
  }

  // Returns true only when the ingredient text doesn't already contain the
  // canonical keyword — i.e. a translation label would actually add information.
  static bool _needsTranslation(String ingredient, String canonical) {
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[-\s]'), '');
    return !norm(ingredient).contains(norm(canonical));
  }

  static ({
    bool isHalal,
    List<String> haram,
    List<String> suspicious,
    Map<String, String> warnings,
    Map<String, String> translations,
    String explanation,
  })
  analyzeWithKeywords(List<String> ingredients) {
    final Map<String, String> warnings = {};
    final Map<String, String> translations = {};
    final List<String> haram = [];
    final List<String> suspicious = [];

    for (final ingredient in ingredients) {
      final lower = ingredient.toLowerCase();

      bool foundHaram = false;
      for (final entry in IngredientKeywords.haram.entries) {
        if (matchesKeyword(lower, entry.key)) {
          warnings[ingredient] = entry.value;
          if (_needsTranslation(ingredient, entry.key)) {
            translations[ingredient] = entry.key;
          }
          haram.add(ingredient);
          foundHaram = true;
          break;
        }
      }
      if (foundHaram) continue;

      for (final entry in IngredientKeywords.suspicious.entries) {
        if (matchesKeyword(lower, entry.key)) {
          warnings[ingredient] = entry.value;
          if (_needsTranslation(ingredient, entry.key)) {
            translations[ingredient] = entry.key;
          }
          suspicious.add(ingredient);
          break;
        }
      }
    }

    String explanation;
    if (haram.isNotEmpty) {
      explanation =
          'This product contains ingredient(s) that are not permissible: '
          '${haram.join(', ')}. '
          'Assessed by keyword matching against known haram ingredients.';
    } else if (suspicious.isNotEmpty) {
      explanation =
          'No definitively haram ingredients were found, but the following '
          'may be animal-derived and require verification: '
          '${suspicious.join(', ')}. '
          'Assessed by keyword matching.';
    } else if (ingredients.isEmpty) {
      explanation = 'No ingredient data available to analyze.';
    } else {
      explanation =
          'No haram or suspicious ingredients were detected in the ingredient '
          'list. Assessed by keyword matching against known haram ingredients.';
    }

    return (
      isHalal: haram.isEmpty,
      haram: haram,
      suspicious: suspicious,
      warnings: warnings,
      translations: translations,
      explanation: explanation,
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
    final Map<String, String> warnings = {};
    final Map<String, String> translations = {};
    final List<String> haram = [];
    final List<String> suspicious = [];

    for (final ingredient in ingredients) {
      bool foundHaram = false;
      for (final entry in _customHaramKeywords.entries) {
        final variants = _customHaramVariants[entry.key] ?? [entry.key];
        if (variants.any((v) => _matchesVariant(ingredient, v))) {
          warnings[ingredient] = entry.value;
          if (_needsTranslation(ingredient, entry.key)) {
            translations[ingredient] = entry.key;
          }
          haram.add(ingredient);
          foundHaram = true;
          break;
        }
      }
      if (foundHaram) continue;
      for (final entry in _customSuspiciousKeywords.entries) {
        final variants = _customSuspiciousVariants[entry.key] ?? [entry.key];
        if (variants.any((v) => _matchesVariant(ingredient, v))) {
          warnings[ingredient] = entry.value;
          if (_needsTranslation(ingredient, entry.key)) {
            translations[ingredient] = entry.key;
          }
          suspicious.add(ingredient);
          break;
        }
      }
    }

    return (
      isHalal: haram.isEmpty,
      haram: haram,
      suspicious: suspicious,
      warnings: warnings,
      translations: translations,
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
      if (DateTime.now().difference(fetchedAt) > const Duration(days: 30)) {
        return null;
      }
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
      });
    } catch (_) {
      return null;
    }
  }

  // Try the Supabase Edge Function. Returns null on any failure so the caller
  // can fall back to direct OpenFoodFacts + keyword analysis.
  Future<Product?> _fetchFromBackend(
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
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['product'] == null) return null;
      return Product.fromJson(data['product'] as Map<String, dynamic>);
    } catch (_) {
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
      if (fixture != null) {
        if (!fixture.isUnknown) return fixture;
        hadStaleTestFixture = true;
      }
    }

    // Step 1: Check local cache (fast path — no network).
    // Skip stale "unknown" entries — they may predate category-based analysis.
    var hadStaleUnknown = false;
    if (!forceBackendRefresh) {
      final cached = await _cache.getProduct(barcode);
      if (cached != null) {
        if (!cached.isUnknown) return cached;
        hadStaleUnknown = true;
      }
    }

    // Step 2: Shared DB read — cheaper than an Edge Function invocation for
    // barcodes another user has already scanned (no AI, no OFf fetch needed).
    // Skip stale "unknown" entries — they may predate category-based analysis.
    if (!forceBackendRefresh) {
      final dbProduct = await _fetchFromSharedDb(barcode);
      if (dbProduct != null) {
        if (!dbProduct.isUnknown) {
          final safe = _applyKeywordSafety(dbProduct);
          await _cache.saveProduct(barcode, safe);
          return safe;
        }
        hadStaleUnknown = true;
      }
    }

    // Step 3: Edge Function (fetches OFf + runs AI + saves to shared DB).
    // Force a fresh fetch if we detected a stale "unknown" in Steps 1 or 2
    // so the Edge Function bypasses its own Supabase cache too.
    final backendProduct = await _fetchFromBackend(
      barcode,
      force: forceBackendRefresh || hadStaleUnknown || hadStaleTestFixture,
    );
    if (backendProduct != null) {
      final safe = _applyKeywordSafety(backendProduct);
      // If the backend still returns unknown after a stale-unknown force-refresh,
      // fall through to Step 4 — direct OFf fetch may resolve it via category tags.
      final staleRetry = hadStaleUnknown || hadStaleTestFixture;
      if (!safe.isUnknown || !staleRetry) {
        await _cache.saveProduct(barcode, safe);
        if (kDebugMode && hadStaleTestFixture && !safe.isUnknown) {
          await TestProductRepository.instance.upsert(safe);
        }
        return safe;
      }
    }

    // Step 4: Fallback — try each open food database in order.
    // OBF (beauty) and OPF (general products) are non-food databases.
    const nonFoodUrls = {_obfBaseUrl, _opfBaseUrl};
    for (final baseUrl in [_offBaseUrl, _obfBaseUrl, _opfBaseUrl]) {
      var product = await _fetchFromFoodApi(barcode, baseUrl);
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
        final safe = _applyKeywordSafety(product);
        await _cache.saveProduct(barcode, safe);
        if (kDebugMode && hadStaleTestFixture) {
          await TestProductRepository.instance.upsert(safe);
        }
        return safe;
      }
    }
    return null;
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

      // When no ingredients are available, check the product name itself.
      // Names like "Wieselburger Bier" or "Rosé Wine" contain haram keywords
      // that make the verdict unambiguous without needing ingredient data.
      final nameCheck = ingredients.isEmpty
          ? analyzeWithKeywords([name.toLowerCase()])
          : null;

      final List<String> haramIngredients = fallback.haram.isNotEmpty
          ? fallback.haram
          : (nameCheck?.haram ?? []);
      final List<String> suspiciousIngredients = fallback.suspicious.isNotEmpty
          ? fallback.suspicious
          : (nameCheck?.suspicious ?? []);
      final Map<String, String> ingredientWarnings =
          fallback.warnings.isNotEmpty
          ? fallback.warnings
          : (nameCheck?.warnings ?? {});

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
      final bool isUnknown =
          ingredients.isEmpty &&
          (nameCheck?.isHalal ?? true) &&
          !haramByCategory &&
          !isHalalByCategory;

      final String explanation;
      if (haramByCategory &&
          fallback.haram.isEmpty &&
          (nameCheck?.isHalal ?? true)) {
        explanation =
            'This product belongs to a category that is not permissible: '
            '${rawCategories.firstWhere((c) => FoodCategories.haram.contains(c.toString().toLowerCase()))}.';
      } else if (isHalalByCategory) {
        explanation =
            'This product is in an inherently halal category (e.g. water, salt). No harmful ingredients expected.';
      } else if (isUnknown) {
        explanation =
            'No ingredient data found. Halal status cannot be determined — check the packaging directly.';
      } else if (nameCheck != null && !nameCheck.isHalal) {
        explanation =
            'No ingredient list found, but the product name contains a haram indicator: '
            '${nameCheck.haram.join(', ')}.';
      } else {
        explanation = fallback.explanation;
      }

      return Product(
        barcode: barcode,
        name: name,
        ingredients: ingredients,
        isHalal:
            isHalalByCategory ||
            (!isUnknown && !haramByCategory && haramIngredients.isEmpty),
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
      );
    } catch (_) {
      return null;
    }
  }
}
