import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/product_verdict.dart';

void main() {
  Product base({
    bool isHalal = false,
    bool isUnknown = false,
    bool isNonFood = false,
    List<String> haram = const [],
    List<String> suspicious = const [],
    bool requiresHalalCert = false,
  }) => Product(
    barcode: '1',
    name: 'Test',
    ingredients: const ['a'],
    isHalal: isHalal,
    isUnknown: isUnknown,
    isNonFood: isNonFood,
    haramIngredients: haram,
    suspiciousIngredients: suspicious,
    ingredientWarnings: const {},
    labels: const [],
    requiresHalalCert: requiresHalalCert,
  );

  group('ProductVerdict.isHalalFromFlags', () {
    test('returns true for halal-by-category override', () {
      expect(
        ProductVerdict.isHalalFromFlags(
          haramIngredients: const ['pork'],
          suspiciousIngredients: const ['e471'],
          requiresHalalCert: true,
          isUnknown: true,
          isHalalByCategory: true,
        ),
        isTrue,
      );
    });

    test('returns false when unknown', () {
      expect(
        ProductVerdict.isHalalFromFlags(
          haramIngredients: const [],
          suspiciousIngredients: const [],
          requiresHalalCert: false,
          isUnknown: true,
        ),
        isFalse,
      );
    });

    test('returns false when haram present', () {
      expect(
        ProductVerdict.isHalalFromFlags(
          haramIngredients: const ['pork'],
          suspiciousIngredients: const [],
          requiresHalalCert: false,
        ),
        isFalse,
      );
    });

    test('returns false when suspicious present', () {
      expect(
        ProductVerdict.isHalalFromFlags(
          haramIngredients: const [],
          suspiciousIngredients: const ['e471'],
          requiresHalalCert: false,
        ),
        isFalse,
      );
    });

    test('returns false when halal cert required', () {
      expect(
        ProductVerdict.isHalalFromFlags(
          haramIngredients: const [],
          suspiciousIngredients: const [],
          requiresHalalCert: true,
        ),
        isFalse,
      );
    });

    test('returns true when no blockers', () {
      expect(
        ProductVerdict.isHalalFromFlags(
          haramIngredients: const [],
          suspiciousIngredients: const [],
          requiresHalalCert: false,
        ),
        isTrue,
      );
    });
  });

  group('ProductVerdict.outcome', () {
    test('nonFood beats other flags', () {
      expect(
        ProductVerdict.outcome(
          base(isNonFood: true, haram: const ['pork'], isHalal: true),
        ),
        ProductOutcome.nonFood,
      );
    });

    test('unknown when product is unknown', () {
      expect(
        ProductVerdict.outcome(base(isUnknown: true)),
        ProductOutcome.unknown,
      );
    });

    test('haram when haram ingredients present', () {
      expect(
        ProductVerdict.outcome(base(haram: const ['pork'])),
        ProductOutcome.haram,
      );
    });

    test('suspicious when only doubtful ingredients', () {
      expect(
        ProductVerdict.outcome(base(suspicious: const ['e471'])),
        ProductOutcome.suspicious,
      );
    });

    test('haram beats suspicious', () {
      expect(
        ProductVerdict.outcome(
          base(haram: const ['pork'], suspicious: const ['e471']),
        ),
        ProductOutcome.haram,
      );
    });

    test('noCert when cert required and no blockers', () {
      expect(
        ProductVerdict.outcome(base(requiresHalalCert: true)),
        ProductOutcome.noCert,
      );
    });

    test('halal when isHalal and no blockers', () {
      expect(ProductVerdict.outcome(base(isHalal: true)), ProductOutcome.halal);
    });

    test('falls back to haram when not halal and no other signals', () {
      expect(ProductVerdict.outcome(base()), ProductOutcome.haram);
    });
  });

  group('ProductVerdict keys', () {
    test('e2eOutcomeKey and storageKey match every outcome', () {
      final cases = <Product, String>{
        base(isNonFood: true): 'nonfood',
        base(isUnknown: true): 'unknown',
        base(haram: const ['pork']): 'haram',
        base(suspicious: const ['e471']): 'suspicious',
        base(requiresHalalCert: true): 'nocert',
        base(isHalal: true): 'halal',
        base(): 'haram',
      };

      for (final entry in cases.entries) {
        expect(ProductVerdict.e2eOutcomeKey(entry.key), entry.value);
        expect(ProductVerdict.storageKey(entry.key), entry.value);
      }
    });
  });
}
