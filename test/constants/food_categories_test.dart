import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/constants/food_categories.dart';

void main() {
  // ── Set integrity ────────────────────────────────────────────────────────────

  group('FoodCategories — no overlap between haram and halal', () {
    test('haram and halal sets are disjoint', () {
      final shared = FoodCategories.haram.intersection(FoodCategories.halal);
      expect(shared, isEmpty, reason: 'shared categories: $shared');
    });
  });

  group('FoodCategories — haram set', () {
    test('is non-empty', () {
      expect(FoodCategories.haram, isNotEmpty);
    });
    test('contains en:alcoholic-beverages', () {
      expect(FoodCategories.haram.contains('en:alcoholic-beverages'), isTrue);
    });
    test('contains en:beers', () {
      expect(FoodCategories.haram.contains('en:beers'), isTrue);
    });
    test('contains en:wines', () {
      expect(FoodCategories.haram.contains('en:wines'), isTrue);
    });
    test('contains en:spirits', () {
      expect(FoodCategories.haram.contains('en:spirits'), isTrue);
    });
    test('does not contain en:waters', () {
      expect(FoodCategories.haram.contains('en:waters'), isFalse);
    });
  });

  group('FoodCategories — halal set', () {
    test('is non-empty', () {
      expect(FoodCategories.halal, isNotEmpty);
    });
    test('contains en:waters', () {
      expect(FoodCategories.halal.contains('en:waters'), isTrue);
    });
    test('contains en:mineral-waters', () {
      expect(FoodCategories.halal.contains('en:mineral-waters'), isTrue);
    });
    test('contains en:salts', () {
      expect(FoodCategories.halal.contains('en:salts'), isTrue);
    });
    test('contains en:sugars', () {
      expect(FoodCategories.halal.contains('en:sugars'), isTrue);
    });
    test('contains en:vinegars', () {
      expect(FoodCategories.halal.contains('en:vinegars'), isTrue);
    });
    test('does not contain en:beers', () {
      expect(FoodCategories.halal.contains('en:beers'), isFalse);
    });
  });

  // ── Category format ──────────────────────────────────────────────────────────

  group('FoodCategories — all entries use en: prefix', () {
    test('all haram entries start with "en:"', () {
      for (final cat in FoodCategories.haram) {
        expect(
          cat.startsWith('en:'),
          isTrue,
          reason: '"$cat" does not start with "en:"',
        );
      }
    });
    test('all halal entries start with "en:"', () {
      for (final cat in FoodCategories.halal) {
        expect(
          cat.startsWith('en:'),
          isTrue,
          reason: '"$cat" does not start with "en:"',
        );
      }
    });
  });
}
