import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:halal_checker/services/off_fetcher.dart';

void main() {
  test('exposes OFF/OBF/OPF base URLs in lookup order', () {
    expect(OffFetcher.baseUrls, [
      OffFetcher.offBaseUrl,
      OffFetcher.obfBaseUrl,
      OffFetcher.opfBaseUrl,
    ]);
    expect(OffFetcher.nonFoodBaseUrls, {
      OffFetcher.obfBaseUrl,
      OffFetcher.opfBaseUrl,
    });
  });

  group('OffFetcher.nameIndicatesAnimalProduct', () {
    test('detects meat terms in product name', () {
      expect(
        OffFetcher.nameIndicatesAnimalProduct('Rindfleisch Burger'),
        isTrue,
      );
    });

    test('ignores unrelated names', () {
      expect(
        OffFetcher.nameIndicatesAnimalProduct('organic oat milk'),
        isFalse,
      );
    });
  });

  group('OffFetcher.nameIndicatesVeganOrVegetarian', () {
    test('detects vegan label in name', () {
      expect(OffFetcher.nameIndicatesVeganOrVegetarian('vegan burger'), isTrue);
    });
  });

  group('OffFetcher.fetch', () {
    test('returns null when API status is 0', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'status': 0}), 200),
      );
      final product = await OffFetcher(
        client,
      ).fetch('123', OffFetcher.offBaseUrl);
      expect(product, isNull);
    });

    test('returns null on non-200 response', () async {
      final client = MockClient((_) async => http.Response('', 404));
      expect(
        await OffFetcher(client).fetch('123', OffFetcher.offBaseUrl),
        isNull,
      );
    });

    test('parses product with water ingredients as halal', () async {
      final body = jsonEncode({
        'status': 1,
        'product': {
          'product_name': 'Spring Water',
          'ingredients_text': 'water',
          'categories_tags': ['en:waters'],
        },
      });
      final client = MockClient((_) async => http.Response(body, 200));
      final product = await OffFetcher(
        client,
      ).fetch('1234567890123', OffFetcher.offBaseUrl);

      expect(product, isNotNull);
      expect(product!.name, 'Spring Water');
      expect(product.isHalal, isTrue);
      expect(product.ingredients, contains('water'));
    });
  });
}
