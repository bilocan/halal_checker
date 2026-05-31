import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/food_categories.dart';
import '../models/product.dart';
import 'halal_rules_engine.dart';
import 'ingredient_resolution.dart';
import 'keyword_multi_source.dart';
import 'product_verdict.dart';

/// Fetches and parses products from OpenFoodFacts, OpenBeautyFacts, and
/// OpenProductsFacts. Extracted from ProductService to isolate the OFF-specific
/// HTTP + parsing logic.
class OffFetcher {
  static const _engine = HalalRulesEngine();

  static const String offBaseUrl =
      'https://world.openfoodfacts.org/api/v0/product';
  static const String obfBaseUrl =
      'https://world.openbeautyfacts.org/api/v0/product';
  static const String opfBaseUrl =
      'https://world.openproductsfacts.org/api/v0/product';

  static const List<String> baseUrls = [offBaseUrl, obfBaseUrl, opfBaseUrl];
  static const Set<String> nonFoodBaseUrls = {obfBaseUrl, opfBaseUrl};

  final http.Client _client;
  OffFetcher(this._client);

  static bool nameIndicatesAnimalProduct(String nameLower) {
    return FoodCategories.animalProductNameTerms.any(
      (term) => RegExp(
        '(?<![a-zA-ZÀ-ɏ])${RegExp.escape(term)}(?![a-zA-ZÀ-ɏ])',
        caseSensitive: false,
      ).hasMatch(nameLower),
    );
  }

  static bool nameIndicatesVeganOrVegetarian(String nameLower) {
    return FoodCategories.veganOrVegetarianNameTerms.any(
      (term) => RegExp(
        '(?<![a-zA-ZÀ-ɏ])${RegExp.escape(term)}(?![a-zA-ZÀ-ɏ])',
        caseSensitive: false,
      ).hasMatch(nameLower),
    );
  }

  static ({
    bool isHalal,
    List<String> haram,
    List<String> suspicious,
    Map<String, String> warnings,
    Map<String, String> translations,
    Map<String, String> canonicals,
    String explanation,
  })
  _analyze(List<String> ingredients) {
    final result = _engine.analyzeIngredients(ingredients);
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

  Future<Product?> fetch(String barcode, String baseUrl) async {
    try {
      final response = await _client
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

      // Ingredient text — display list + multi-source analysis (language fallback).
      final resolved = resolveOffIngredientAnalysis(productData);
      final ingredients = resolved.display;

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

      final kwResult = analyzeIngredientsFromSources(
        engine: _engine,
        sources: resolved.sources,
        displayIngredients: ingredients,
        analyzeLang: resolved.analyzeLang,
      );

      // When no ingredient data at all, check the product name itself.
      final nameCheck = ingredients.isEmpty && resolved.sources.isEmpty
          ? _analyze([name.toLowerCase()])
          : null;

      final List<String> haramIngredients = [
        ...(kwResult.haram.isNotEmpty
            ? kwResult.haram
            : (nameCheck?.haram ?? [])),
      ];
      final List<String> suspiciousIngredients = [
        ...(kwResult.suspicious.isNotEmpty
            ? kwResult.suspicious
            : (nameCheck?.suspicious ?? [])),
      ];
      final Map<String, String> ingredientWarnings = {
        ...(kwResult.warnings.isNotEmpty
            ? kwResult.warnings
            : (nameCheck?.warnings ?? {})),
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
          explanation: '',
          analyzedByAI: false,
          ingredientSource: 'off',
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
          nameIndicatesAnimalProduct(name.toLowerCase());
      final bool hasVeganOrVegetarianEvidence =
          labels.any(
            (l) => FoodCategories.veganOrVegetarianLabels.contains(
              l.toLowerCase(),
            ),
          ) ||
          nameIndicatesVeganOrVegetarian(name.toLowerCase());
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
          !haramByCategory &&
          !halalByCategory &&
          (kwResult.isUnknown ||
              (ingredients.isEmpty &&
                  resolved.sources.isEmpty &&
                  (nameCheck?.isHalal ?? true) &&
                  !requiresHalalCert));

      final String explanation;
      if (haramByCategory &&
          kwResult.haram.isEmpty &&
          (nameCheck?.isHalal ?? true)) {
        explanation =
            'This product belongs to a category that is not permissible: '
            '${rawCategories.firstWhere((c) => FoodCategories.haram.contains(c.toString().toLowerCase()))}.';
      } else if (isHalalByCategory) {
        explanation =
            'This product is in an inherently halal category (e.g. water, salt). No harmful ingredients expected.';
      } else if (requiresHalalCert) {
        explanation = '';
      } else if (nameCheck != null && !nameCheck.isHalal) {
        explanation =
            'No ingredient list found, but the product name contains a haram indicator: '
            '${nameCheck.haram.join(', ')}.';
      } else {
        explanation = kwResult.explanation;
      }

      return Product(
        barcode: barcode,
        name: name,
        ingredients: ingredients,
        isHalal:
            isHalalByCategory ||
            (!haramByCategory &&
                ProductVerdict.isHalalFromFlags(
                  haramIngredients: haramIngredients,
                  suspiciousIngredients: suspiciousIngredients,
                  requiresHalalCert: requiresHalalCert,
                  isUnknown: isUnknown,
                )),
        isUnknown: isUnknown,
        haramIngredients: haramIngredients,
        suspiciousIngredients: suspiciousIngredients,
        ingredientWarnings: ingredientWarnings,
        ingredientTranslations: {
          ...kwResult.translations,
          ...(nameCheck?.translations ?? {}),
        },
        ingredientCanonicals: {
          ...kwResult.canonicals,
          ...(nameCheck?.canonicals ?? {}),
        },
        labels: labels,
        imageUrl: imageUrl,
        imageFrontUrl: imageFrontUrl,
        imageIngredientsUrl: imageIngredientsUrl,
        imageNutritionUrl: imageNutritionUrl,
        explanation: explanation,
        analyzedByAI: false,
        ingredientSource: 'off',
        requiresHalalCert: requiresHalalCert,
        keywordMatchSource: kwResult.keywordMatchSource,
        keywordMatchOrigins: kwResult.keywordMatchOrigins,
        analyzeLang: kwResult.analyzeLang,
        displayLang: resolved.displayLang.isEmpty ? null : resolved.displayLang,
      );
    } catch (_) {
      return null;
    }
  }
}
