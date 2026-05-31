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

  group('OffFetcher.nameIndicatesHalalCategory', () {
    test('detects German water term "mineralwasser"', () {
      expect(
        OffFetcher.nameIndicatesHalalCategory('mineralwasser prickelnd'),
        isTrue,
      );
    });

    test('detects English water term "mineral water"', () {
      expect(
        OffFetcher.nameIndicatesHalalCategory('mineral water sparkling'),
        isTrue,
      );
    });

    test('does not match unrelated names', () {
      expect(OffFetcher.nameIndicatesHalalCategory('orange juice'), isFalse);
    });

    test('does not match compound word "mineralwasserbasis"', () {
      expect(
        OffFetcher.nameIndicatesHalalCategory('mineralwasserbasis'),
        isFalse,
      );
    });
  });

  group('OffFetcher.fetch', () {
    test(
      'water product with only non-English categories returns halal by name',
      () async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Mineralwasser prickelnd',
            'categories_tags': ['de:mineralwässer', 'de:wasser'],
          },
        });
        final client = MockClient((_) async => http.Response(body, 200));
        final product = await OffFetcher(
          client,
        ).fetch('90098369', OffFetcher.offBaseUrl);

        expect(product, isNotNull);
        expect(product!.isHalal, isTrue);
        expect(product.isUnknown, isFalse);
      },
    );

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

    test('falls back to product_name_en when product_name is blank', () async {
      final body = jsonEncode({
        'status': 1,
        'product': {
          'product_name': '',
          'product_name_en': 'Fallback Name',
          'ingredients_text': 'water',
          'categories_tags': [],
        },
      });
      final client = MockClient((_) async => http.Response(body, 200));
      final product = await OffFetcher(
        client,
      ).fetch('123', OffFetcher.offBaseUrl);

      expect(product?.name, 'Fallback Name');
    });

    test(
      'resolves image from selected_images when direct field is absent',
      () async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Branded Product',
            'ingredients_text': 'water',
            'selected_images': {
              'front': {
                'display': {
                  'en': 'https://images.openfoodfacts.org/img/product.100.jpg',
                },
              },
            },
          },
        });
        final client = MockClient((_) async => http.Response(body, 200));
        final product = await OffFetcher(
          client,
        ).fetch('123', OffFetcher.offBaseUrl);

        expect(
          product?.imageUrl,
          'https://images.openfoodfacts.org/img/product.400.jpg',
        );
      },
    );

    test(
      'Cyrillic label matches Bulgarian pork keywords, keeps BG display ingredients',
      () async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Свински кюфтета',
            'ingredients_lc': 'bg',
            'ingredients_text':
                '80% частично финомляно свинско месо, вода, сол',
          },
        });
        final client = MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(body),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );
        final product = await OffFetcher(
          client,
        ).fetch('20013066', OffFetcher.offBaseUrl);

        expect(product, isNotNull);
        expect(product!.ingredients, isNotEmpty);
        expect(
          product.ingredients.any((i) => i.contains('свинско')),
          isTrue,
          reason: 'display list must stay in original label language',
        );
        expect(product.isUnknown, isFalse);
        expect(product.isHalal, isFalse);
        expect(product.keywordMatchSource, 'primary');
        expect(product.displayLang, 'bg');
        expect(product.analyzeLang, isNull);
        expect(product.haramIngredients, isNotEmpty);
        expect(product.explanation.toLowerCase(), contains('keyword matching'));
        expect(
          product.haramIngredients.any((h) => h.contains('свинско')),
          isTrue,
        );
      },
    );

    test(
      'Cyrillic without EN but only non-pork taxonomy → unanalyzable',
      () async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Вода',
            'ingredients_lc': 'bg',
            'ingredients_text': 'вода, сол',
            'ingredients': [
              {'id': 'en:water', 'text': 'вода'},
              {'id': 'en:salt', 'text': 'сол'},
            ],
          },
        });
        final client = MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(body),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );
        final product = await OffFetcher(
          client,
        ).fetch('20013066', OffFetcher.offBaseUrl);

        expect(product?.isUnknown, isTrue);
        expect(product?.keywordMatchSource, 'unanalyzable');
        expect(product?.haramIngredients, isEmpty);
      },
    );

    test(
      'Cyrillic label with English OFF fallback flags pork and records match source',
      () async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Свински кюфтета',
            'ingredients_lc': 'bg',
            'ingredients_text':
                '80% частично финомляно свинско месо, вода, сол',
            'ingredients_text_en':
                '80% pork meat is partially minced, water, salt',
            'categories_tags': ['en:prepared-meats'],
          },
        });
        final client = MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(body),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );
        final product = await OffFetcher(
          client,
        ).fetch('20013066', OffFetcher.offBaseUrl);

        expect(product?.isHalal, isFalse);
        expect(product?.haramIngredients, isNotEmpty);
        expect(product?.keywordMatchSource, contains('off_en'));
        expect(product?.displayLang, 'bg');
        expect(product?.analyzeLang, 'en');
      },
    );

    test(
      'extracts nested structured ingredient ids for keyword analysis',
      () async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'Structured Product',
            'ingredients_text': 'water, salt',
            'ingredients': [
              {
                'id': 'en:pork',
                'text': 'water',
                'ingredients': [
                  {'id': 'en:gelatin', 'text': 'gelatin'},
                ],
              },
            ],
          },
        });
        final client = MockClient((_) async => http.Response(body, 200));
        final product = await OffFetcher(
          client,
        ).fetch('123', OffFetcher.offBaseUrl);

        expect(product?.isHalal, isFalse);
        expect(product?.haramIngredients, contains('pork'));
        expect(product?.suspiciousIngredients, contains('gelatin'));
      },
    );

    test('animal product without halal cert requires certification', () async {
      final body = jsonEncode({
        'status': 1,
        'product': {
          'product_name': 'Ground Beef',
          'ingredients_text': 'beef, salt',
          'categories_tags': ['en:meats', 'en:beef'],
          'labels_tags': [],
        },
      });
      final client = MockClient((_) async => http.Response(body, 200));
      final product = await OffFetcher(
        client,
      ).fetch('123', OffFetcher.offBaseUrl);

      expect(product?.requiresHalalCert, isTrue);
      expect(product?.isHalal, isFalse);
    });

    test(
      'haram category without ingredient hits uses category explanation',
      () async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'House Blend',
            'ingredients_text': '',
            'categories_tags': ['en:alcoholic-beverages'],
          },
        });
        final client = MockClient((_) async => http.Response(body, 200));
        final product = await OffFetcher(
          client,
        ).fetch('123', OffFetcher.offBaseUrl);

        expect(product?.isHalal, isFalse);
        expect(product?.explanation, contains('not permissible'));
      },
    );

    test('uses abbreviated_product_name when other names are blank', () async {
      final body = jsonEncode({
        'status': 1,
        'product': {
          'product_name': '   ',
          'abbreviated_product_name': 'Short Name',
          'ingredients_text': 'water',
        },
      });
      final client = MockClient((_) async => http.Response(body, 200));
      final product = await OffFetcher(
        client,
      ).fetch('123', OffFetcher.offBaseUrl);

      expect(product?.name, 'Short Name');
    });

    test(
      'falls back to ingredients_text_de when ingredients_text is empty',
      () async {
        final body = jsonEncode({
          'status': 1,
          'product': {
            'product_name': 'German Product',
            'ingredients_text': '',
            'ingredients_text_de': 'schweinefleisch, salz',
          },
        });
        final client = MockClient((_) async => http.Response(body, 200));
        final product = await OffFetcher(
          client,
        ).fetch('123', OffFetcher.offBaseUrl);

        expect(product?.isHalal, isFalse);
      },
    );

    test('parses comma-separated labels string', () async {
      final body = jsonEncode({
        'status': 1,
        'product': {
          'product_name': 'Certified Product',
          'ingredients_text': 'water',
          'labels': 'Halal, Organic',
        },
      });
      final client = MockClient((_) async => http.Response(body, 200));
      final product = await OffFetcher(
        client,
      ).fetch('123', OffFetcher.offBaseUrl);

      expect(product?.labels, containsAll(['halal', 'organic']));
    });
  });
}
