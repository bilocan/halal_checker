import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/product_verdict.dart';

void main() {
  Product base({
    bool isHalal = false,
    List<String> haram = const [],
    List<String> suspicious = const [],
    bool requiresHalalCert = false,
  }) => Product(
    barcode: '1',
    name: 'Test',
    ingredients: const ['a'],
    isHalal: isHalal,
    haramIngredients: haram,
    suspiciousIngredients: suspicious,
    ingredientWarnings: const {},
    labels: const [],
    requiresHalalCert: requiresHalalCert,
  );

  test('isHalalFromFlags is false when suspicious present', () {
    expect(
      ProductVerdict.isHalalFromFlags(
        haramIngredients: const [],
        suspiciousIngredients: const ['e471'],
        requiresHalalCert: false,
      ),
      isFalse,
    );
  });

  test('outcome is suspicious when only doubtful ingredients', () {
    expect(
      ProductVerdict.outcome(base(suspicious: const ['e471'])),
      ProductOutcome.suspicious,
    );
  });

  test('haram beats suspicious in outcome', () {
    expect(
      ProductVerdict.outcome(
        base(haram: const ['pork'], suspicious: const ['e471']),
      ),
      ProductOutcome.haram,
    );
  });
}
