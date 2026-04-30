import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/product.dart';
import 'cache_service.dart';
import 'keyword_service.dart';
import 'test_product_repository.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  ProductService._internal();
  factory ProductService() => _instance;

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

  // Canonical keyword → reason (used for transparency UI chips)
  static const Map<String, String> haramKeywords = {
    'alcohol': 'Contains alcohol or alcohol-derived ingredient',
    'ethanol': 'Contains alcohol or alcohol-derived ingredient',
    'wine': 'Contains alcohol or alcohol-derived ingredient',
    'beer': 'Contains alcohol or alcohol-derived ingredient',
    'cognac': 'Contains cognac (alcoholic spirit)',
    'brandy': 'Contains brandy (alcoholic spirit)',
    'whisky': 'Contains whisky (alcoholic spirit)',
    'vodka': 'Contains vodka (alcoholic spirit)',
    'rum': 'Contains rum (alcoholic spirit)',
    'gin': 'Contains gin (alcoholic spirit)',
    'liqueur': 'Contains liqueur (alcoholic)',
    'schnapps': 'Contains schnapps (alcoholic spirit)',
    'champagne': 'Contains champagne (alcoholic)',
    'prosecco': 'Contains prosecco (alcoholic)',
    'bourbon': 'Contains bourbon (alcoholic spirit)',
    'sake': 'Contains sake (alcoholic)',
    'pork': 'Contains pork or pork-derived ingredient',
    'lard': 'Contains pork fat',
    'gelatin': 'Gelatin is typically animal-derived',
    'bacon': 'Contains pork product',
    'ham': 'Contains pork product',
    'pepperoni': 'Contains pork product',
    'salami': 'Contains pork product',
    'chorizo': 'Contains pork product',
    'prosciutto': 'Contains pork product',
    'carmine': 'Carmine/cochineal is insect-derived',
    'cochineal': 'Carmine/cochineal is insect-derived',
    'e120': 'Carmine/cochineal color, animal-derived',
    'e441': 'Gelatin, animal-derived',
    'e542': 'Bone phosphate, animal-derived',
    'e904': 'Shellac, animal-derived',
  };

  static const Map<String, String> suspiciousKeywords = {
    'e920': 'L-cysteine may be animal-derived',
    'e322': 'Lecithin may be animal-derived',
    'e471': 'Mono- and diglycerides may be animal-derived',
    'e472': 'Emulsifiers may be animal-derived',
    'e473': 'Sucrose esters may be animal-derived',
    'e927': 'Glycine may be animal-derived',
    'rennet': 'Rennet may be animal-derived',
    'whey': 'Whey is a dairy ingredient',
    'l-cysteine': 'L-cysteine may be animal-derived',
    'natural flavour': 'Natural flavor may include animal-derived extracts',
    'flavouring': 'Flavouring may include animal-derived extracts',
    'enzymes': 'Enzymes may be extracted from animal sources',
    'glycerol': 'Glycerol may be animal-derived',
  };

  // Multilingual variants per canonical keyword (EN / DE / TR / FR / IT / ES / NL)
  static const Map<String, List<String>> _haramVariants = {
    'alcohol': ['alcohol', 'alkohol', 'alcool', 'alcol', 'alkol', 'álcool'],
    'ethanol': ['ethanol', 'äthanol', 'éthanol', 'etanolo', 'etanol'],
    'wine': ['wine', 'wein', 'vin', 'vino', 'şarap', 'wijn', 'vinho'],
    'beer': ['beer', 'bier', 'bière', 'birra', 'cerveza', 'bira', 'cerveja'],
    'cognac': ['cognac', 'kognak'],
    'brandy': ['brandy', 'branntwein', 'brandewijn'],
    'whisky': ['whisky', 'whiskey', 'whiskie', 'viski'],
    'vodka': ['vodka', 'wodka'],
    'rum': ['rum', 'rhum', 'ron'],
    'gin': ['gin'],
    'liqueur': ['liqueur', 'likör', 'licor', 'likeur', 'liquore'],
    'schnapps': ['schnapps', 'schnaps'],
    'champagne': ['champagne', 'sekt', 'cava', 'spumante'],
    'prosecco': ['prosecco'],
    'bourbon': ['bourbon'],
    'sake': ['sake', 'saké'],
    'pork': [
      'pork',
      'schwein',
      'schweinefleisch',
      'porc',
      'maiale',
      'cerdo',
      'domuz',
      'varkens',
      'varkensvlees',
      'porco',
    ],
    'lard': [
      'lard',
      'schmalz',
      'schweineschmalz',
      'saindoux',
      'strutto',
      'manteca',
      'domuz yağı',
      'banha',
    ],
    'gelatin': ['gelatin', 'gelatine', 'gelatina', 'jelatin', 'gélatine'],
    'bacon': ['bacon', 'speck', 'lardons', 'pancetta', 'domuz pastırması'],
    'ham': ['ham', 'schinken', 'jambon', 'prosciutto', 'jamón', 'presunto'],
    'pepperoni': ['pepperoni'],
    'salami': ['salami', 'salame'],
    'chorizo': ['chorizo'],
    'prosciutto': ['prosciutto'],
    'carmine': ['carmine', 'karmin', 'carmín', 'karmín', 'carmin'],
    'cochineal': [
      'cochineal',
      'cochenille',
      'cocciniglia',
      'cochinilla',
      'koşnil',
    ],
    'e120': ['e120', 'e-120'],
    'e441': ['e441', 'e-441'],
    'e542': ['e542', 'e-542'],
    'e904': ['e904', 'e-904'],
  };

  static const Map<String, List<String>> _suspiciousVariants = {
    'e920': ['e920', 'e-920'],
    'e322': ['e322', 'e-322'],
    'e471': ['e471', 'e-471'],
    'e472': ['e472', 'e-472'],
    'e473': ['e473', 'e-473'],
    'e927': ['e927', 'e-927'],
    'rennet': [
      'rennet',
      'lab',
      'labferment',
      'présure',
      'caglio',
      'cuajo',
      'peynir mayası',
      'stremsel',
    ],
    'whey': [
      'whey',
      'molke',
      'lactosérum',
      'siero di latte',
      'suero de leche',
      'peynir suyu',
      'wei',
    ],
    'l-cysteine': [
      'l-cysteine',
      'l-cystein',
      'l-cystéine',
      'l-cisteina',
      'l-sistein',
    ],
    'natural flavour': [
      'natural flavour',
      'natural flavor',
      'natürliches aroma',
      'natürliche aromen',
      'arôme naturel',
      'aroma naturale',
      'aroma natural',
      'doğal aroma',
      'natuurlijk aroma',
    ],
    'flavouring': [
      'flavouring',
      'flavoring',
      'aroma',
      'arôme',
      'aroma naturale',
      'doğal aroma',
      'natürliches aroma',
      'smaakstof',
    ],
    'enzymes': ['enzymes', 'enzyme', 'enzimi', 'enzimas', 'enzim', 'enzymen'],
    'glycerol': [
      'glycerol',
      'glycerin',
      'glycérol',
      'glicerina',
      'gliserin',
      'glycerine',
    ],
  };

  // All alcohol-family terms — these get the "alcohol-free" exclusion applied
  static const _alcoholFamily = {
    'alcohol',
    'alkohol',
    'alcool',
    'alcol',
    'alkol',
    'álcool',
    'ethanol',
    'äthanol',
    'éthanol',
    'etanolo',
    'etanol',
  };

  // Fatty alcohol prefixes — these are NOT haram (cosmetic/food emulsifiers)
  static final _fattyAlcoholPrefix = RegExp(
    r'\b(cetyl|stearyl|behenyl|lauryl|myristyl|arachidyl|oleyl|cetostearyl|'
    r'lanolin|isostearyl|octyldodecyl|decyl)\s+',
    caseSensitive: false,
  );

  static bool isFattyAlcohol(String ingredient) =>
      _fattyAlcoholPrefix.hasMatch(ingredient);

  static bool _matchesVariant(String ingredient, String variant) {
    if (variant.contains(' ')) {
      return ingredient.toLowerCase().contains(variant.toLowerCase());
    }
    final escaped = RegExp.escape(variant);
    if (_alcoholFamily.contains(variant.toLowerCase())) {
      // Skip fatty alcohols — they are halal
      if (_fattyAlcoholPrefix.hasMatch(ingredient)) return false;
      return RegExp(
        '\\b$escaped\\b(?![-\\s]*free)',
        caseSensitive: false,
      ).hasMatch(ingredient);
    }
    return RegExp('\\b$escaped\\b', caseSensitive: false).hasMatch(ingredient);
  }

  static bool matchesKeyword(String ingredient, String keyword) {
    final variants =
        _haramVariants[keyword] ?? _suspiciousVariants[keyword] ?? [keyword];
    return variants.any((v) => _matchesVariant(ingredient, v));
  }

  static ({
    bool isHalal,
    List<String> haram,
    List<String> suspicious,
    Map<String, String> warnings,
    String explanation,
  })
  analyzeWithKeywords(List<String> ingredients) {
    final Map<String, String> warnings = {};
    final List<String> haram = [];
    final List<String> suspicious = [];

    for (final ingredient in ingredients) {
      final lower = ingredient.toLowerCase();

      bool foundHaram = false;
      for (final entry in haramKeywords.entries) {
        if (matchesKeyword(lower, entry.key)) {
          warnings[ingredient] = entry.value;
          haram.add(ingredient);
          foundHaram = true;
          break;
        }
      }
      if (foundHaram) continue;

      for (final entry in suspiciousKeywords.entries) {
        if (matchesKeyword(lower, entry.key)) {
          warnings[ingredient] = entry.value;
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
      explanation: explanation,
    );
  }

  ({
    bool isHalal,
    List<String> haram,
    List<String> suspicious,
    Map<String, String> warnings,
  })
  _customKeywordAnalysis(List<String> ingredients) {
    final Map<String, String> warnings = {};
    final List<String> haram = [];
    final List<String> suspicious = [];

    for (final ingredient in ingredients) {
      bool foundHaram = false;
      for (final entry in _customHaramKeywords.entries) {
        final variants = _customHaramVariants[entry.key] ?? [entry.key];
        if (variants.any((v) => _matchesVariant(ingredient, v))) {
          warnings[ingredient] = entry.value;
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
        explanation: explanation,
      );
    }
    return product;
  }

  Future<Product?> refreshProduct(String barcode) async {
    await _cache.removeProduct(barcode);
    return _getProduct(barcode, forceBackendRefresh: true);
  }

  // Try the Supabase Edge Function. Returns null on any failure so the caller
  // can fall back to direct OpenFoodFacts + keyword analysis.
  Future<Product?> _fetchFromBackend(
    String barcode, {
    bool force = false,
  }) async {
    if (!AppConfig.hasSupabase) return null;
    try {
      final response = await http
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

    // Step 0 (debug only): return fixture from test DB without touching cache/network
    if (kDebugMode) {
      final fixture = await TestProductRepository.instance.getByBarcode(
        barcode,
      );
      if (fixture != null) return fixture;
    }

    // Step 1: Check local cache (fast path — no network)
    if (!forceBackendRefresh) {
      final cached = await _cache.getProduct(barcode);
      if (cached != null) return cached;
    }

    // Step 2: Try backend (handles OFf + Claude + shared DB)
    final backendProduct = await _fetchFromBackend(
      barcode,
      force: forceBackendRefresh,
    );
    if (backendProduct != null) {
      final safe = _applyKeywordSafety(backendProduct);
      await _cache.saveProduct(barcode, safe);
      return safe;
    }

    // Step 3: Fallback — try each open food database in order
    for (final baseUrl in [_offBaseUrl, _obfBaseUrl, _opfBaseUrl]) {
      final product = await _fetchFromFoodApi(barcode, baseUrl);
      if (product != null) {
        final safe = _applyKeywordSafety(product);
        await _cache.saveProduct(barcode, safe);
        return safe;
      }
    }
    return null;
  }

  Future<Product?> _fetchFromFoodApi(String barcode, String baseUrl) async {
    try {
      final response = await http
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
        for (final lang in ['en', 'nl', 'de', 'fr', 'tr', 'es', 'it']) {
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

      // OFf categories that unambiguously indicate an alcoholic product.
      const haramCategories = {
        'en:alcoholic-beverages',
        'en:beers',
        'en:wines',
        'en:spirits',
        'en:champagnes',
        'en:ciders',
        'en:sake',
      };
      final rawCategories = productData['categories_tags'];
      final bool haramByCategory =
          rawCategories is List &&
          rawCategories.any(
            (c) => haramCategories.contains(c.toString().toLowerCase()),
          );

      final fallback = analyzeWithKeywords(ingredients);

      // When no ingredients are available, check the product name itself.
      // Names like "Wieselburger Bier" or "Rosé Wine" contain haram keywords
      // that make the verdict unambiguous without needing ingredient data.
      final nameCheck = ingredients.isEmpty
          ? analyzeWithKeywords([name.toLowerCase()])
          : null;

      final bool isUnknown =
          ingredients.isEmpty &&
          (nameCheck?.isHalal ?? true) &&
          !haramByCategory;
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

      final String explanation;
      if (haramByCategory &&
          fallback.haram.isEmpty &&
          (nameCheck?.isHalal ?? true)) {
        explanation =
            'This product belongs to a category that is not permissible: '
            '${rawCategories.firstWhere((c) => haramCategories.contains(c.toString().toLowerCase()))}.';
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
        isHalal: !isUnknown && !haramByCategory && haramIngredients.isEmpty,
        isUnknown: isUnknown,
        haramIngredients: haramIngredients,
        suspiciousIngredients: suspiciousIngredients,
        ingredientWarnings: ingredientWarnings,
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
