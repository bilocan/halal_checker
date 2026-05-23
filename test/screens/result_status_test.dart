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
}
