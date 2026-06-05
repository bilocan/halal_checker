import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/localization/app_localizations_en.dart';
import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/screens/result/result_status.dart';

void main() {
  test('non-food products use localized explanation', () {
    final loc = AppLocalizationsEn();
    final product = Product(
      barcode: '123',
      name: 'Shampoo',
      ingredients: [],
      isHalal: false,
      isNonFood: true,
      haramIngredients: [],
      suspiciousIngredients: [],
      ingredientWarnings: {},
      labels: const [],
    );

    final status = ResultStatus.from(product, loc);

    expect(status.explanation, loc.explanationNonFood);
    expect(status.resultLabel, loc.nonFood);
  });

  test('suspicious-only product shows verify status', () {
    final loc = AppLocalizationsEn();
    final product = Product(
      barcode: '9100000784175',
      name: 'Test',
      ingredients: const ['e471'],
      isHalal: false,
      haramIngredients: const [],
      suspiciousIngredients: const ['e471'],
      ingredientWarnings: const {},
      labels: const [],
    );

    final status = ResultStatus.from(product, loc);

    expect(status.resultLabel, loc.suspiciousResult);
    expect(status.explanation, loc.explanationSuspiciousOnly('e471'));
  });

  test('suspicious aroma uses flavouring explanation with alcohol wording', () {
    final loc = AppLocalizationsEn();
    final product = Product(
      barcode: '9100000976259',
      name: 'Chocolate Chip Cookies',
      ingredients: const ['Aroma'],
      isHalal: false,
      haramIngredients: const [],
      suspiciousIngredients: const ['Aroma'],
      ingredientWarnings: const {},
      ingredientCanonicals: const {'Aroma': 'flavouring'},
      labels: const [],
    );

    final status = ResultStatus.from(product, loc);

    expect(
      status.explanation,
      loc.explanationSuspiciousFlavouringOnly('Aroma'),
    );
    expect(status.explanation, contains('alcohol'));
  });

  test('stored English explanation is not shown when localized copy exists', () {
    final loc = AppLocalizationsEn();
    final product = Product(
      barcode: '1',
      name: 'Test',
      ingredients: const ['water'],
      isHalal: true,
      haramIngredients: const [],
      suspiciousIngredients: const [],
      ingredientWarnings: const {},
      labels: const [],
      explanation:
          'No haram or suspicious ingredients detected. Assessed by keyword matching.',
      analysisMethod: 'keyword',
    );

    final status = ResultStatus.from(product, loc);

    expect(status.explanation, loc.explanationClean);
    expect(status.explanation, isNot(contains('Assessed by keyword')));
  });

  test('haram product lists flagged ingredients in localized explanation', () {
    final loc = AppLocalizationsEn();
    final product = Product(
      barcode: '2',
      name: 'Spam',
      ingredients: const ['Pork with Ham'],
      isHalal: false,
      haramIngredients: const ['Pork with Ham'],
      suspiciousIngredients: const [],
      ingredientWarnings: const {},
      labels: const [],
      explanation: 'English-only stored explanation',
    );

    final status = ResultStatus.from(product, loc);

    expect(
      status.explanation,
      loc.explanationHaramWithIngredients('Pork with Ham'),
    );
  });

  test('unanalyzable language uses localized unknown explanation', () {
    final loc = AppLocalizationsEn();
    final product = Product(
      barcode: '3',
      name: 'Test',
      ingredients: const ['不明'],
      isHalal: false,
      isUnknown: true,
      haramIngredients: const [],
      suspiciousIngredients: const [],
      ingredientWarnings: const {},
      labels: const [],
      keywordMatchSource: 'unanalyzable',
    );

    final status = ResultStatus.from(product, loc);

    expect(status.explanation, loc.explanationUnanalyzableLanguage);
  });
}
