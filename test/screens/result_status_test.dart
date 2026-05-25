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
}
