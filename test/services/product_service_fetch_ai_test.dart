import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:halal_checker/services/cache_service.dart';
import 'package:halal_checker/services/product_service.dart';
import '../helpers/test_product_fixture.dart';

void main() {
  const barcode = '4001234567890';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProductService().resetForTesting();
  });

  tearDown(ProductService().resetForTesting);

  test('fetchIngredientsByAI uses test hook and writes to cache', () async {
    final product = testProduct(
      barcode,
      ingredients: ['sugar', 'cocoa'],
      isUnknown: false,
      ingredientSource: 'ai',
    );
    ProductService().testFetchIngredientsByAI = (_) async => product;

    final fetched = await ProductService().fetchIngredientsByAI(barcode);

    expect(fetched, product);
    final cached = await CacheService().getProduct(barcode);
    expect(cached?.ingredients, ['sugar', 'cocoa']);
    expect(cached?.ingredientSource, 'ai');
  });

  test(
    'fetchIngredientsByAI returns null when test hook returns null',
    () async {
      ProductService().testFetchIngredientsByAI = (_) async => null;

      expect(await ProductService().fetchIngredientsByAI(barcode), isNull);
      expect(await CacheService().getProduct(barcode), isNull);
    },
  );
}
