import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/needs_cert_rule.dart';

Product _base({
  List<String> suspicious = const [],
  List<String> suspiciousAdditives = const [],
  List<String> labels = const [],
  Map<String, String> canonicals = const {},
  bool requiresHalalCert = false,
}) {
  return Product(
    barcode: '1',
    name: 'Test',
    ingredients: const ['a'],
    isHalal: false,
    haramIngredients: const [],
    suspiciousIngredients: suspicious,
    suspiciousAdditives: suspiciousAdditives,
    ingredientWarnings: const {},
    ingredientCanonicals: canonicals,
    labels: labels,
    requiresHalalCert: requiresHalalCert,
  );
}

void main() {
  test('L-cysteine without cert sets requiresHalalCert', () {
    final result = NeedsCertRule.applyToProduct(
      _base(suspicious: const ['Mehlbehandlungsmittel: L-Cystein']),
    );
    expect(result.requiresHalalCert, isTrue);
    expect(result.isHalal, isFalse);
    expect(result.suspiciousIngredients, isNotEmpty);
    expect(result.explanation, contains('L-cysteine (E920)'));
  });

  test('halal label waives L-cysteine', () {
    final result = NeedsCertRule.applyToProduct(
      _base(
        suspicious: const ['L-cysteine'],
        labels: const ['halal'],
        canonicals: const {'L-cysteine': 'l-cysteine'},
      ),
    );
    expect(result.requiresHalalCert, isFalse);
    expect(result.suspiciousIngredients, isEmpty);
    expect(result.isHalal, isTrue);
  });

  test('e471 is not treated as needs-cert', () {
    final result = NeedsCertRule.applyToProduct(
      _base(suspicious: const ['e471'], canonicals: const {'e471': 'e471'}),
    );
    expect(result.requiresHalalCert, isFalse);
    expect(result.suspiciousIngredients, contains('e471'));
  });

  test('onlyNeedsCertFlags is true for cysteine blob', () {
    expect(
      NeedsCertRule.onlyNeedsCertFlags(
        _base(suspicious: const ['Weizentortilla (L-Cystein, Glycerin)']),
      ),
      isTrue,
    );
  });

  test('onlyNeedsCertFlags is false for e471', () {
    expect(
      NeedsCertRule.onlyNeedsCertFlags(_base(suspicious: const ['e471'])),
      isFalse,
    );
  });
}
