import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/needs_cert_rule.dart';

Product _base({
  String name = 'Test',
  List<String> suspicious = const [],
  List<String> suspiciousAdditives = const [],
  List<String> suspiciousLabels = const [],
  List<String> labels = const [],
  List<String> categoriesTags = const [],
  Map<String, String> canonicals = const {},
  bool requiresHalalCert = false,
  bool isNonFood = false,
  String explanation = '',
}) {
  return Product(
    barcode: '1',
    name: name,
    ingredients: const ['a'],
    isHalal: false,
    isNonFood: isNonFood,
    haramIngredients: const [],
    suspiciousIngredients: suspicious,
    suspiciousAdditives: suspiciousAdditives,
    suspiciousLabels: suspiciousLabels,
    ingredientWarnings: const {},
    ingredientCanonicals: canonicals,
    labels: labels,
    categoriesTags: categoriesTags,
    requiresHalalCert: requiresHalalCert,
    explanation: explanation,
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

  test('onlyNeedsCertFlags is false when a suspicious label remains', () {
    expect(
      NeedsCertRule.onlyNeedsCertFlags(
        _base(
          suspicious: const ['L-cysteine'],
          suspiciousLabels: const ['en:may-contain-pork'],
        ),
      ),
      isFalse,
    );
  });

  test('haram category plus cysteine does not set needs-cert', () {
    final result = NeedsCertRule.applyToProduct(
      _base(
        suspicious: const ['L-cysteine'],
        categoriesTags: const ['en:beers'],
        canonicals: const {'L-cysteine': 'l-cysteine'},
      ),
    );
    expect(result.requiresHalalCert, isFalse);
    expect(result.isHalal, isFalse);
    expect(result.suspiciousIngredients, contains('L-cysteine'));
  });

  test('halal label does not upgrade a haram-category product', () {
    final result = NeedsCertRule.applyToProduct(
      _base(labels: const ['halal'], categoriesTags: const ['en:beers']),
    );
    expect(result.isHalal, isFalse);
    expect(result.requiresHalalCert, isFalse);
  });

  test('animal cert plus cysteine keeps animal explanation', () {
    final result = NeedsCertRule.applyToProduct(
      _base(
        name: 'Chicken wrap',
        suspicious: const ['L-Cystein'],
        categoriesTags: const ['en:chicken'],
        requiresHalalCert: true,
        explanation: 'animal cert already set',
      ),
    );
    expect(result.requiresHalalCert, isTrue);
    expect(result.isHalal, isFalse);
    expect(result.explanation, isNot(contains('L-cysteine (E920)')));
  });

  test('non-food plus cysteine does not set needs-cert', () {
    final result = NeedsCertRule.applyToProduct(
      _base(suspicious: const ['L-cysteine'], isNonFood: true),
    );
    expect(result.requiresHalalCert, isFalse);
    expect(result.isHalal, isFalse);
  });
}
