import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/food_categories.dart';
import '../models/product.dart';
import 'halal_rules_engine.dart';

/// Fetches and parses products from OpenFoodFacts, OpenBeautyFacts, and
/// OpenProductsFacts. Extracted from ProductService to isolate the OFF-specific
/// HTTP + parsing logic.
class OffFetcher {
  static const _engine = HalalRulesEngine();

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

      final fallback = _analyze(ingredients);

      // Also analyse canonical IDs; merge extra matches the text analysis missed.
      final idAnalysis = _analyze(ingredientIds);
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
          ? _analyze([name.toLowerCase()])
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
        ingredientCanonicals: {
          ...fallback.canonicals,
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
      );
    } catch (_) {
      return null;
    }
  }
}
