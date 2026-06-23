import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/constants/food_categories.dart';

void main() {
  // ── animalProduct set ────────────────────────────────────────────────────

  group('FoodCategories — animalProduct set', () {
    test('is non-empty', () {
      expect(FoodCategories.animalProduct, isNotEmpty);
    });

    test('contains en:meats', () {
      expect(FoodCategories.animalProduct.contains('en:meats'), isTrue);
    });

    test('contains en:poultry', () {
      expect(FoodCategories.animalProduct.contains('en:poultry'), isTrue);
    });

    test('contains en:sausages', () {
      expect(FoodCategories.animalProduct.contains('en:sausages'), isTrue);
    });

    test('contains German category de:fleisch', () {
      expect(FoodCategories.animalProduct.contains('de:fleisch'), isTrue);
    });

    test('contains Turkish category tr:tavuk', () {
      expect(FoodCategories.animalProduct.contains('tr:tavuk'), isTrue);
    });

    test('does not contain en:waters', () {
      expect(FoodCategories.animalProduct.contains('en:waters'), isFalse);
    });

    test('does not contain en:cosmetics', () {
      expect(FoodCategories.animalProduct.contains('en:cosmetics'), isFalse);
    });
  });

  // ── halalCertificationLabels set ─────────────────────────────────────────

  group('FoodCategories — halalCertificationLabels set', () {
    test('is non-empty', () {
      expect(FoodCategories.halalCertificationLabels, isNotEmpty);
    });

    test('contains "halal"', () {
      expect(FoodCategories.halalCertificationLabels.contains('halal'), isTrue);
    });

    test('contains "certified halal"', () {
      expect(
        FoodCategories.halalCertificationLabels.contains('certified halal'),
        isTrue,
      );
    });

    test('contains "ifanca"', () {
      expect(
        FoodCategories.halalCertificationLabels.contains('ifanca'),
        isTrue,
      );
    });

    test('does not contain arbitrary string', () {
      expect(
        FoodCategories.halalCertificationLabels.contains('organic'),
        isFalse,
      );
    });
  });

  // ── veganOrVegetarianLabels set ──────────────────────────────────────────

  group('FoodCategories — veganOrVegetarianLabels set', () {
    test('is non-empty', () {
      expect(FoodCategories.veganOrVegetarianLabels, isNotEmpty);
    });

    test('contains "vegan"', () {
      expect(FoodCategories.veganOrVegetarianLabels.contains('vegan'), isTrue);
    });

    test('contains "vegetarian"', () {
      expect(
        FoodCategories.veganOrVegetarianLabels.contains('vegetarian'),
        isTrue,
      );
    });

    test('contains "en:vegan"', () {
      expect(
        FoodCategories.veganOrVegetarianLabels.contains('en:vegan'),
        isTrue,
      );
    });
  });

  // ── veganOrVegetarianNameTerms set ──────────────────────────────────────

  group('FoodCategories — veganOrVegetarianNameTerms set', () {
    test('is non-empty', () {
      expect(FoodCategories.veganOrVegetarianNameTerms, isNotEmpty);
    });

    test('contains "vegan"', () {
      expect(
        FoodCategories.veganOrVegetarianNameTerms.contains('vegan'),
        isTrue,
      );
    });

    test('contains "vegetarian"', () {
      expect(
        FoodCategories.veganOrVegetarianNameTerms.contains('vegetarian'),
        isTrue,
      );
    });
  });

  // ── animalProductNameTerms set ──────────────────────────────────────────

  group('FoodCategories — animalProductNameTerms set', () {
    test('is non-empty', () {
      expect(FoodCategories.animalProductNameTerms, isNotEmpty);
    });

    test('contains German term "fleisch"', () {
      expect(FoodCategories.animalProductNameTerms.contains('fleisch'), isTrue);
    });

    test('contains English term "ground beef"', () {
      expect(
        FoodCategories.animalProductNameTerms.contains('ground beef'),
        isTrue,
      );
    });

    test('contains Turkish term "sucuk"', () {
      expect(FoodCategories.animalProductNameTerms.contains('sucuk'), isTrue);
    });

    test('does not contain single-word generic terms like "meat"', () {
      expect(FoodCategories.animalProductNameTerms.contains('meat'), isFalse);
    });
  });

  // ── cross-set integrity ────────────────────────────────────────────────

  group('FoodCategories — animalProduct vs other sets', () {
    test('animalProduct and haram are disjoint', () {
      final shared = FoodCategories.animalProduct.intersection(
        FoodCategories.haram,
      );
      expect(shared, isEmpty, reason: 'shared categories: $shared');
    });

    test('animalProduct and halal are disjoint', () {
      final shared = FoodCategories.animalProduct.intersection(
        FoodCategories.halal,
      );
      expect(shared, isEmpty, reason: 'shared categories: $shared');
    });

    test('animalProduct and nonFood are disjoint', () {
      final shared = FoodCategories.animalProduct.intersection(
        FoodCategories.nonFood,
      );
      expect(shared, isEmpty, reason: 'shared categories: $shared');
    });
  });

  // ── animalProduct language-prefix format ──────────────────────────────────

  group('FoodCategories — animalProduct uses valid language prefixes', () {
    const validPrefixes = {'en:', 'de:', 'tr:'};

    test('every animalProduct entry starts with a valid language prefix', () {
      for (final cat in FoodCategories.animalProduct) {
        final hasValidPrefix = validPrefixes.any((p) => cat.startsWith(p));
        expect(
          hasValidPrefix,
          isTrue,
          reason: '"$cat" does not start with a known language prefix',
        );
      }
    });
  });

  // ── label casing ──────────────────────────────────────────────────────────

  group('FoodCategories — halalCertificationLabels are lowercase', () {
    test('all certification labels are lowercase', () {
      for (final label in FoodCategories.halalCertificationLabels) {
        expect(
          label,
          equals(label.toLowerCase()),
          reason: '"$label" is not lowercase',
        );
      }
    });
  });

  group('FoodCategories — veganOrVegetarianLabels are lowercase', () {
    test('all vegan/vegetarian labels are lowercase', () {
      for (final label in FoodCategories.veganOrVegetarianLabels) {
        expect(
          label,
          equals(label.toLowerCase()),
          reason: '"$label" is not lowercase',
        );
      }
    });
  });

  // ── animalProductNameTerms minimum length ─────────────────────────────────

  group(
    'FoodCategories — animalProductNameTerms are distinctive (≥4 chars)',
    () {
      test('no term is shorter than 4 characters', () {
        for (final term in FoodCategories.animalProductNameTerms) {
          expect(
            term.length,
            greaterThanOrEqualTo(4),
            reason: '"$term" is too short to be a distinctive meat term',
          );
        }
      });
    },
  );

  // ── haram completeness ────────────────────────────────────────────────────

  group('FoodCategories — haram contains all alcohol categories', () {
    const expected = {
      'en:alcoholic-beverages',
      'en:beers',
      'en:wines',
      'en:spirits',
      'en:champagnes',
      'en:ciders',
      'en:sake',
    };
    test('all 7 alcohol category tags are present', () {
      expect(FoodCategories.haram, containsAll(expected));
    });
    test('haram size matches expected (no silent additions)', () {
      expect(FoodCategories.haram.length, expected.length);
    });
  });

  // ── halalCertificationLabels completeness ─────────────────────────────────

  group('FoodCategories — halalCertificationLabels completeness', () {
    const expected = {
      'halal',
      'halal certified',
      'halal certificate',
      'certified halal',
      'hfa halal',
      'halal hfa',
      'ifanca',
      'isna halal',
      'muis halal',
      'muslim consumer group',
    };
    test('all 10 certification labels are present', () {
      expect(FoodCategories.halalCertificationLabels, containsAll(expected));
    });
    test('size matches expected (no silent additions)', () {
      expect(FoodCategories.halalCertificationLabels.length, expected.length);
    });
  });

  // ── veganOrVegetarianLabels completeness ─────────────────────────────────

  group('FoodCategories — veganOrVegetarianLabels completeness', () {
    const expected = {
      'vegan',
      'vegetarian',
      'vegan certified',
      'vegetarian friendly',
      'en:vegan',
      'en:vegetarian',
    };
    test('all 6 vegan/vegetarian labels are present', () {
      expect(FoodCategories.veganOrVegetarianLabels, containsAll(expected));
    });
    test('size matches expected (no silent additions)', () {
      expect(FoodCategories.veganOrVegetarianLabels.length, expected.length);
    });
  });

  // ── animalProductNameTerms casing and language coverage ───────────────────

  group('FoodCategories — animalProductNameTerms casing', () {
    test('all terms are lowercase (for case-insensitive name matching)', () {
      for (final term in FoodCategories.animalProductNameTerms) {
        expect(
          term,
          equals(term.toLowerCase()),
          reason: '"$term" is not lowercase',
        );
      }
    });
  });

  group('FoodCategories — animalProductNameTerms language coverage', () {
    test('contains French term "viande"', () {
      expect(FoodCategories.animalProductNameTerms.contains('viande'), isTrue);
    });
    test('contains Turkish term "kıyma"', () {
      expect(FoodCategories.animalProductNameTerms.contains('kıyma'), isTrue);
    });
    test('contains Turkish term "köfte"', () {
      expect(FoodCategories.animalProductNameTerms.contains('köfte'), isTrue);
    });
    test('contains English multi-word term "chicken breast"', () {
      expect(
        FoodCategories.animalProductNameTerms.contains('chicken breast'),
        isTrue,
      );
    });
    test('contains standalone English term "chicken"', () {
      expect(FoodCategories.animalProductNameTerms.contains('chicken'), isTrue);
    });
    test('contains standalone English term "beef"', () {
      expect(FoodCategories.animalProductNameTerms.contains('beef'), isTrue);
    });
    test('contains standalone German term "hähnchen"', () {
      expect(
        FoodCategories.animalProductNameTerms.contains('hähnchen'),
        isTrue,
      );
    });
    test('contains standalone Turkish term "tavuk"', () {
      expect(FoodCategories.animalProductNameTerms.contains('tavuk'), isTrue);
    });
  });

  // ── cross-set integrity: label sets ──────────────────────────────────────

  group('FoodCategories — cross-set integrity: label sets', () {
    test(
      'halalCertificationLabels and veganOrVegetarianLabels are disjoint',
      () {
        final shared = FoodCategories.halalCertificationLabels.intersection(
          FoodCategories.veganOrVegetarianLabels,
        );
        expect(shared, isEmpty, reason: 'shared labels: $shared');
      },
    );

    test(
      'veganOrVegetarianNameTerms is a subset of veganOrVegetarianLabels',
      () {
        for (final term in FoodCategories.veganOrVegetarianNameTerms) {
          expect(
            FoodCategories.veganOrVegetarianLabels.contains(term),
            isTrue,
            reason: '"$term" in nameTerms but missing from labels',
          );
        }
      },
    );
  });

  // ── halalCategoryNameTerms set ───────────────────────────────────────────

  group('FoodCategories — halalCategoryNameTerms set', () {
    test('is non-empty', () {
      expect(FoodCategories.halalCategoryNameTerms, isNotEmpty);
    });

    test('contains German water term "mineralwasser"', () {
      expect(
        FoodCategories.halalCategoryNameTerms.contains('mineralwasser'),
        isTrue,
      );
    });

    test('contains English water term "mineral water"', () {
      expect(
        FoodCategories.halalCategoryNameTerms.contains('mineral water'),
        isTrue,
      );
    });

    test('all terms are lowercase', () {
      for (final term in FoodCategories.halalCategoryNameTerms) {
        expect(
          term,
          equals(term.toLowerCase()),
          reason: '"$term" is not lowercase',
        );
      }
    });

    test('no term is shorter than 4 characters', () {
      for (final term in FoodCategories.halalCategoryNameTerms) {
        expect(
          term.length,
          greaterThanOrEqualTo(4),
          reason: '"$term" is too short',
        );
      }
    });
  });

  // ── nonFood pet-food entries ──────────────────────────────────────────────

  group('FoodCategories — nonFood pet-food subcategories', () {
    test('contains en:pet-food', () {
      expect(FoodCategories.nonFood.contains('en:pet-food'), isTrue);
    });
    test('contains en:cat-food', () {
      expect(FoodCategories.nonFood.contains('en:cat-food'), isTrue);
    });
    test('contains en:dog-food', () {
      expect(FoodCategories.nonFood.contains('en:dog-food'), isTrue);
    });
    test('contains en:pet-care', () {
      expect(FoodCategories.nonFood.contains('en:pet-care'), isTrue);
    });
  });

  // ── halal water-variant coverage ─────────────────────────────────────────

  group('FoodCategories — halal water variants', () {
    const waterVariants = {
      'en:waters',
      'en:bottled-waters',
      'en:mineral-waters',
      'en:spring-waters',
      'en:carbonated-waters',
      'en:sparkling-waters',
      'en:still-waters',
      'en:flavoured-waters',
      'en:drinking-water',
    };
    test('all major water variants are present', () {
      expect(FoodCategories.halal, containsAll(waterVariants));
    });
  });
}
