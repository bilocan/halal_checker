import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/product.dart';
import 'cache_service.dart';
import 'claude_service.dart';

class ProductService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  final CacheService _cache = CacheService();
  final ClaudeService _claude = ClaudeService();

  // Canonical keyword → reason (used for transparency UI chips)
  static const Map<String, String> haramKeywords = {
    'alcohol':    'Contains alcohol or alcohol-derived ingredient',
    'ethanol':    'Contains alcohol or alcohol-derived ingredient',
    'wine':       'Contains alcohol or alcohol-derived ingredient',
    'beer':       'Contains alcohol or alcohol-derived ingredient',
    'pork':       'Contains pork or pork-derived ingredient',
    'lard':       'Contains pork fat',
    'gelatin':    'Gelatin is typically animal-derived',
    'bacon':      'Contains pork product',
    'ham':        'Contains pork product',
    'pepperoni':  'Contains pork product',
    'salami':     'Contains pork product',
    'chorizo':    'Contains pork product',
    'prosciutto': 'Contains pork product',
    'carmine':    'Carmine/cochineal is insect-derived',
    'cochineal':  'Carmine/cochineal is insect-derived',
    'e120': 'Carmine/cochineal color, animal-derived',
    'e441': 'Gelatin, animal-derived',
    'e542': 'Bone phosphate, animal-derived',
    'e904': 'Shellac, animal-derived',
  };

  static const Map<String, String> suspiciousKeywords = {
    'e920':           'L-cysteine may be animal-derived',
    'e322':           'Lecithin may be animal-derived',
    'e471':           'Mono- and diglycerides may be animal-derived',
    'e472':           'Emulsifiers may be animal-derived',
    'e473':           'Sucrose esters may be animal-derived',
    'e927':           'Glycine may be animal-derived',
    'rennet':         'Rennet may be animal-derived',
    'whey':           'Whey is a dairy ingredient',
    'l-cysteine':     'L-cysteine may be animal-derived',
    'natural flavour':'Natural flavor may include animal-derived extracts',
    'flavouring':     'Flavouring may include animal-derived extracts',
    'enzymes':        'Enzymes may be extracted from animal sources',
    'glycerol':       'Glycerol may be animal-derived',
  };

  // Multilingual variants per canonical keyword (EN / DE / TR / FR / IT / ES / NL)
  static const Map<String, List<String>> _haramVariants = {
    'alcohol':    ['alcohol', 'alkohol', 'alcool', 'alcol', 'alkol', 'álcool'],
    'ethanol':    ['ethanol', 'äthanol', 'éthanol', 'etanolo', 'etanol'],
    'wine':       ['wine', 'wein', 'vin', 'vino', 'şarap', 'wijn', 'vinho'],
    'beer':       ['beer', 'bier', 'bière', 'birra', 'cerveza', 'bira', 'cerveja'],
    'pork':       ['pork', 'schwein', 'schweinefleisch', 'porc', 'maiale', 'cerdo',
                   'domuz', 'varkens', 'varkensvlees', 'porco'],
    'lard':       ['lard', 'schmalz', 'schweineschmalz', 'saindoux', 'strutto',
                   'manteca', 'domuz yağı', 'banha'],
    'gelatin':    ['gelatin', 'gelatine', 'gelatina', 'jelatin', 'gélatine'],
    'bacon':      ['bacon', 'speck', 'lardons', 'pancetta', 'domuz pastırması'],
    'ham':        ['ham', 'schinken', 'jambon', 'prosciutto', 'jamón', 'presunto'],
    'pepperoni':  ['pepperoni'],
    'salami':     ['salami', 'salame'],
    'chorizo':    ['chorizo'],
    'prosciutto': ['prosciutto'],
    'carmine':    ['carmine', 'karmin', 'carmín', 'karmín', 'carmin'],
    'cochineal':  ['cochineal', 'cochenille', 'cocciniglia', 'cochinilla', 'koşnil'],
    'e120':       ['e120', 'e-120'],
    'e441':       ['e441', 'e-441'],
    'e542':       ['e542', 'e-542'],
    'e904':       ['e904', 'e-904'],
  };

  static const Map<String, List<String>> _suspiciousVariants = {
    'e920':           ['e920', 'e-920'],
    'e322':           ['e322', 'e-322'],
    'e471':           ['e471', 'e-471'],
    'e472':           ['e472', 'e-472'],
    'e473':           ['e473', 'e-473'],
    'e927':           ['e927', 'e-927'],
    'rennet':         ['rennet', 'lab', 'labferment', 'présure', 'caglio', 'cuajo',
                       'peynir mayası', 'stremsel'],
    'whey':           ['whey', 'molke', 'lactosérum', 'siero di latte',
                       'suero de leche', 'peynir suyu', 'wei'],
    'l-cysteine':     ['l-cysteine', 'l-cystein', 'l-cystéine', 'l-cisteina',
                       'l-sistein'],
    'natural flavour':['natural flavour', 'natural flavor', 'natürliches aroma',
                       'natürliche aromen', 'arôme naturel', 'aroma naturale',
                       'aroma natural', 'doğal aroma', 'natuurlijk aroma'],
    'flavouring':     ['flavouring', 'flavoring', 'aroma', 'arôme', 'aroma naturale',
                       'doğal aroma', 'natürliches aroma', 'smaakstof'],
    'enzymes':        ['enzymes', 'enzyme', 'enzimi', 'enzimas', 'enzim', 'enzymen'],
    'glycerol':       ['glycerol', 'glycerin', 'glycérol', 'glicerina', 'gliserin',
                       'glycerine'],
  };

  // All alcohol-family terms — these get the "alcohol-free" exclusion applied
  static const _alcoholFamily = {
    'alcohol', 'alkohol', 'alcool', 'alcol', 'alkol', 'álcool',
    'ethanol', 'äthanol', 'éthanol', 'etanolo', 'etanol',
  };

  static bool _matchesVariant(String ingredient, String variant) {
    if (variant.contains(' ')) {
      return ingredient.toLowerCase().contains(variant.toLowerCase());
    }
    final escaped = RegExp.escape(variant);
    if (_alcoholFamily.contains(variant.toLowerCase())) {
      return RegExp('\\b$escaped\\b(?![-\\s]*free)', caseSensitive: false)
          .hasMatch(ingredient);
    }
    return RegExp('\\b$escaped\\b', caseSensitive: false).hasMatch(ingredient);
  }

  static bool matchesKeyword(String ingredient, String keyword) {
    final variants = _haramVariants[keyword] ?? _suspiciousVariants[keyword] ?? [keyword];
    return variants.any((v) => _matchesVariant(ingredient, v));
  }

  // Keyword-based fallback analysis
  static ({
    bool isHalal,
    List<String> haram,
    List<String> suspicious,
    Map<String, String> warnings,
    String explanation,
  }) _keywordAnalysis(List<String> ingredients) {
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

  // Try the Supabase Edge Function. Returns null on any failure so the caller
  // can fall back to direct OpenFoodFacts + Claude.
  Future<Product?> _fetchFromBackend(String barcode) async {
    if (!AppConfig.hasSupabase) return null;
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.supabaseUrl}/functions/v1/lookup-product'),
            headers: {
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'barcode': barcode}),
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

  Future<Product?> getProduct(String barcode) async {
    // Step 1: Check local cache (fast path — no network)
    final cached = await _cache.getProduct(barcode);
    if (cached != null) return cached;

    // Step 2: Try backend (handles OFf + Claude + shared DB)
    final backendProduct = await _fetchFromBackend(barcode);
    if (backendProduct != null) {
      await _cache.saveProduct(barcode, backendProduct);
      return backendProduct;
    }

    // Step 3: Fallback — fetch directly from OpenFoodFacts
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$barcode.json'),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] == 0) return null;

      final productData = data['product'];
      final name = productData['product_name'] ?? 'Unknown Product';
      final ingredientsText =
          (productData['ingredients_text'] ?? '').toString().toLowerCase();

      String? optimizeImageUrl(String? url) {
        if (url == null || url.isEmpty) return null;
        return url
            .replaceAll('.100.', '.400.')
            .replaceAll('.200.', '.400.')
            .replaceAll('.300.', '.400.');
      }

      final imageUrl =
          optimizeImageUrl(productData['image_url']?.toString());
      final imageFrontUrl =
          optimizeImageUrl(productData['image_front_url']?.toString());
      final imageIngredientsUrl =
          optimizeImageUrl(productData['image_ingredients_url']?.toString());
      final imageNutritionUrl =
          optimizeImageUrl(productData['image_nutrition_url']?.toString());

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

      // Step 3: Extract ingredients
      final ingredients = ingredientsText
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Step 4: Analyze with Claude (Step 5), fall back to keywords
      bool isHalal;
      List<String> haramIngredients;
      List<String> suspiciousIngredients;
      Map<String, String> ingredientWarnings;
      String explanation;
      bool analyzedByAI;

      final claudeResult = await _claude.analyzeIngredients(ingredients);
      if (claudeResult != null) {
        isHalal = claudeResult.isHalal;
        haramIngredients = claudeResult.haramIngredients;
        suspiciousIngredients = claudeResult.suspiciousIngredients;
        ingredientWarnings = claudeResult.ingredientWarnings;
        explanation = claudeResult.explanation;
        analyzedByAI = true;
      } else {
        final fallback = _keywordAnalysis(ingredients);
        isHalal = fallback.isHalal;
        haramIngredients = fallback.haram;
        suspiciousIngredients = fallback.suspicious;
        ingredientWarnings = fallback.warnings;
        explanation = fallback.explanation;
        analyzedByAI = false;
      }

      final product = Product(
        barcode: barcode,
        name: name,
        ingredients: ingredients,
        isHalal: isHalal,
        haramIngredients: haramIngredients,
        suspiciousIngredients: suspiciousIngredients,
        ingredientWarnings: ingredientWarnings,
        labels: labels,
        imageUrl: imageUrl,
        imageFrontUrl: imageFrontUrl,
        imageIngredientsUrl: imageIngredientsUrl,
        imageNutritionUrl: imageNutritionUrl,
        explanation: explanation,
        analyzedByAI: analyzedByAI,
      );

      // Step 6: Write to cache
      await _cache.saveProduct(barcode, product);

      return product;
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }
}
