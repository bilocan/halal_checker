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

  // ── nonFood set ──────────────────────────────────────────────────────────────

  group('FoodCategories — nonFood set', () {
    test('is non-empty', () {
      expect(FoodCategories.nonFood, isNotEmpty);
    });
    test('contains en:non-food-products', () {
      expect(FoodCategories.nonFood.contains('en:non-food-products'), isTrue);
    });
    test('contains en:cosmetics', () {
      expect(FoodCategories.nonFood.contains('en:cosmetics'), isTrue);
    });
    test('contains en:cleaning-products', () {
      expect(FoodCategories.nonFood.contains('en:cleaning-products'), isTrue);
    });
    test('contains en:diapers', () {
      expect(FoodCategories.nonFood.contains('en:diapers'), isTrue);
    });
    test('contains en:baby-care', () {
      expect(FoodCategories.nonFood.contains('en:baby-care'), isTrue);
    });
    test('contains en:baby-wipes', () {
      expect(FoodCategories.nonFood.contains('en:baby-wipes'), isTrue);
    });
    test(
      'does NOT contain en:medicines — medicines need ingredient analysis',
      () {
        expect(FoodCategories.nonFood.contains('en:medicines'), isFalse);
      },
    );
    test(
      'does NOT contain en:dietary-supplements — need ingredient analysis',
      () {
        expect(
          FoodCategories.nonFood.contains('en:dietary-supplements'),
          isFalse,
        );
      },
    );
    test('does NOT contain en:baby-products — generic tag includes food', () {
      expect(FoodCategories.nonFood.contains('en:baby-products'), isFalse);
    });
  });

  // ── Set integrity ─────────────────────────────────────────────────────────────

  group('FoodCategories — no overlap between sets', () {
    test('nonFood and haram are disjoint', () {
      final shared = FoodCategories.nonFood.intersection(FoodCategories.haram);
      expect(shared, isEmpty, reason: 'shared categories: $shared');
    });
    test('nonFood and halal are disjoint', () {
      final shared = FoodCategories.nonFood.intersection(FoodCategories.halal);
      expect(shared, isEmpty, reason: 'shared categories: $shared');
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
    test('all nonFood entries start with "en:"', () {
      for (final cat in FoodCategories.nonFood) {
        expect(
          cat.startsWith('en:'),
          isTrue,
          reason: '"$cat" does not start with "en:"',
        );
      }
    });
  });
}
