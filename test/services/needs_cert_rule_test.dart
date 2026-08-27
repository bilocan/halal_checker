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

  test('unknown product with waived cysteine stays not halal', () {
    final result = NeedsCertRule.applyToProduct(
      Product(
        barcode: '1',
        name: 'Test',
        ingredients: const ['L-cysteine'],
        isHalal: false,
        isUnknown: true,
        haramIngredients: const [],
        suspiciousIngredients: const ['L-cysteine'],
        ingredientWarnings: const {},
        labels: const ['halal'],
        ingredientCanonicals: const {'L-cysteine': 'l-cysteine'},
      ),
    );
    expect(result.requiresHalalCert, isFalse);
    expect(result.isHalal, isFalse);
  });

  test('halal label plus haram additive does not claim a clean list', () {
    final result = NeedsCertRule.applyToProduct(
      Product(
        barcode: '1',
        name: 'Test',
        ingredients: const ['L-cysteine'],
        isHalal: false,
        haramIngredients: const [],
        haramAdditives: const ['e120'],
        suspiciousIngredients: const ['L-cysteine'],
        ingredientWarnings: const {},
        labels: const ['halal'],
        ingredientCanonicals: const {'L-cysteine': 'l-cysteine'},
      ),
    );
    expect(result.requiresHalalCert, isFalse);
    expect(result.isHalal, isFalse);
    expect(result.explanation, isNot(contains('No haram or suspicious')));
  });

  test('non-food plus cysteine does not set needs-cert', () {
    final result = NeedsCertRule.applyToProduct(
      _base(suspicious: const ['L-cysteine'], isNonFood: true),
    );
    expect(result.requiresHalalCert, isFalse);
    expect(result.isHalal, isFalse);
  });

  test('e920 additive without cert sets requiresHalalCert', () {
    final result = NeedsCertRule.applyToProduct(
      _base(
        suspiciousAdditives: const ['e920'],
        canonicals: const {'e920': 'e920'},
      ),
    );
    expect(result.requiresHalalCert, isTrue);
    expect(result.suspiciousAdditives, contains('e920'));
    expect(result.ingredientWarnings['e920'], isNotNull);
  });

  test('unrelated text is not treated as needs-cert', () {
    expect(NeedsCertRule.isNeedsCertText('wheat flour'), isFalse);
    expect(NeedsCertRule.isNeedsCertCanonical(null), isFalse);
    expect(NeedsCertRule.itemIsNeedsCert('salt', const {}), isFalse);
  });

  test('onlyNeedsCertFlags is true when suspicious lists are empty', () {
    expect(NeedsCertRule.onlyNeedsCertFlags(_base()), isTrue);
  });

  test('foundOn is true for cysteine additive only', () {
    expect(
      NeedsCertRule.foundOn(
        _base(
          suspiciousAdditives: const ['E-920'],
          canonicals: const {'E-920': 'e920'},
        ),
      ),
      isTrue,
    );
  });

  test('halal label with leftover e471 does not claim a clean list', () {
    final result = NeedsCertRule.applyToProduct(
      _base(
        suspicious: const ['L-cysteine', 'e471'],
        labels: const ['halal'],
        canonicals: const {'L-cysteine': 'l-cysteine', 'e471': 'e471'},
      ),
    );
    expect(result.requiresHalalCert, isFalse);
    expect(result.suspiciousIngredients, contains('e471'));
    expect(result.suspiciousIngredients, isNot(contains('L-cysteine')));
    expect(result.isHalal, isFalse);
    expect(result.explanation, isNot(contains('No haram or suspicious')));
  });

  test('haram ingredients plus cysteine do not set needs-cert', () {
    final result = NeedsCertRule.applyToProduct(
      Product(
        barcode: '1',
        name: 'Test',
        ingredients: const ['pork', 'L-cysteine'],
        isHalal: false,
        haramIngredients: const ['pork'],
        suspiciousIngredients: const ['L-cysteine'],
        ingredientWarnings: const {},
        labels: const [],
      ),
    );
    expect(result.requiresHalalCert, isFalse);
    expect(result.suspiciousIngredients, contains('L-cysteine'));
  });

  test('existing animal cert without cysteine stays requiresHalalCert', () {
    final result = NeedsCertRule.applyToProduct(
      _base(requiresHalalCert: true, suspicious: const ['e471']),
    );
    expect(result.requiresHalalCert, isTrue);
  });

  test(
    'halal label clears an existing animal cert when cysteine is absent',
    () {
      final result = NeedsCertRule.applyToProduct(
        _base(
          requiresHalalCert: true,
          labels: const ['halal'],
          suspicious: const ['e471'],
          canonicals: const {'e471': 'e471'},
        ),
      );
      expect(result.requiresHalalCert, isFalse);
    },
  );

  group('hasAnimalProductSignal', () {
    test('is false for non-food', () {
      expect(
        NeedsCertRule.hasAnimalProductSignal(_base(isNonFood: true)),
        isFalse,
      );
    });

    test('is false for haram category', () {
      expect(
        NeedsCertRule.hasAnimalProductSignal(
          _base(categoriesTags: const ['en:beers']),
        ),
        isFalse,
      );
    });

    test('is false when vegan label is present', () {
      expect(
        NeedsCertRule.hasAnimalProductSignal(
          _base(
            name: 'Chicken bites',
            labels: const ['en:vegan'],
            categoriesTags: const ['en:chicken'],
          ),
        ),
        isFalse,
      );
    });

    test('is false when the name says vegan', () {
      expect(
        NeedsCertRule.hasAnimalProductSignal(
          _base(name: 'Vegan chicken-style bites'),
        ),
        isFalse,
      );
    });

    test('is true for an animal category tag', () {
      expect(
        NeedsCertRule.hasAnimalProductSignal(
          _base(categoriesTags: const ['en:chicken']),
        ),
        isTrue,
      );
    });

    test('is true from the product name when categories are unknown', () {
      expect(
        NeedsCertRule.hasAnimalProductSignal(
          _base(name: 'Chicken wrap', categoriesTags: const ['en:unknown']),
        ),
        isTrue,
      );
    });

    test('is false for a non-animal named product', () {
      expect(
        NeedsCertRule.hasAnimalProductSignal(_base(name: 'Salt crackers')),
        isFalse,
      );
    });
  });
}
