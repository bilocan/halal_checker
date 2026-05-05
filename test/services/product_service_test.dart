import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:halal_checker/services/product_service.dart';
import 'package:halal_checker/services/test_product_repository.dart';

// Builds a minimal valid OFf API response body.
String _offJson({
  String name = 'Test Product',
  String ingredients = '',
  List<String> categoriesTags = const [],
  String labels = '',
  List<String> labelsTags = const [],
  String? imageUrl,
  String? ingredientsTextDe,
  List<Map<String, dynamic>>? structuredIngredients,
}) {
  final product = <String, dynamic>{
    'product_name': name,
    'ingredients_text': ingredients,
    'categories_tags': categoriesTags,
    'labels': labels,
    'labels_tags': labelsTags,
  };
  if (imageUrl != null) product['image_url'] = imageUrl;
  if (ingredientsTextDe != null)
    product['ingredients_text_de'] = ingredientsTextDe;
  if (structuredIngredients != null)
    product['ingredients'] = structuredIngredients;
  return jsonEncode({'status': 1, 'product': product});
}

final _notFoundJson = jsonEncode({'status': 0});

// Mock that returns the given body for every GET and 500 for every POST
// (so the Supabase backend path is skipped cleanly in tests).
MockClient _mockGet(String body, {int status = 200}) => MockClient(
  (req) async => req.method == 'POST'
      ? http.Response('', 500)
      : http.Response(body, status),
);

MockClient _mockGetWithCallback(
  Future<http.Response> Function(http.Request) handler,
) => MockClient(
  (req) async => req.method == 'POST' ? http.Response('', 500) : handler(req),
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestProductRepository.dbPathOverride = inMemoryDatabasePath;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Re-open a fresh in-memory DB so debug fixture lookup always returns null.
    await TestProductRepository.instance.closeForTesting();
  });

  tearDown(() {
    ProductService().setHttpClientForTesting(http.Client());
  });

  // ── halal products ────────────────────────────────────────────────────────

  group('getProduct — halal', () {
    test('clean ingredients → isHalal true, no flags', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(name: 'Mineral Water', ingredients: 'water, minerals'),
        ),
      );

      final p = await ProductService().getProduct('1000000001');
      expect(p, isNotNull);
      expect(p!.isHalal, isTrue);
      expect(p.isUnknown, isFalse);
      expect(p.haramIngredients, isEmpty);
      expect(p.suspiciousIngredients, isEmpty);
    });

    test('whey → suspicious but still halal', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(name: 'Yogurt', ingredients: 'milk, whey powder, cultures'),
        ),
      );

      final p = await ProductService().getProduct('1000000002');
      expect(p!.isHalal, isTrue);
      expect(p.suspiciousIngredients.any((i) => i.contains('whey')), isTrue);
    });

    test('cetyl alcohol is not flagged as haram', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Lotion',
            ingredients: 'water, cetyl alcohol, glycerin',
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000003');
      expect(p!.haramIngredients, isEmpty);
    });

    test('alcohol-free label is not flagged as haram', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Malt Drink',
            ingredients: 'water, malt (alcohol-free), barley',
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000004');
      expect(p!.haramIngredients, isEmpty);
    });
  });

  // ── haram products ────────────────────────────────────────────────────────

  group('getProduct — haram', () {
    test('pork ingredient → isHalal false', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(name: 'Pork Sausage', ingredients: 'pork, salt, spices'),
        ),
      );

      final p = await ProductService().getProduct('1000000005');
      expect(p!.isHalal, isFalse);
      expect(p.haramIngredients, contains('pork'));
    });

    test('gelatin ingredient → isHalal false', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Gummy Bears',
            ingredients: 'glucose syrup, sugar, gelatin, citric acid',
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000006');
      expect(p!.isHalal, isFalse);
      expect(p.haramIngredients, contains('gelatin'));
    });

    test('wine ingredient → isHalal false', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(name: 'Wine Sauce', ingredients: 'tomato, wine, herbs'),
        ),
      );

      final p = await ProductService().getProduct('1000000007');
      expect(p!.isHalal, isFalse);
      expect(p.haramIngredients, contains('wine'));
    });

    test(
      'haram categories_tags (en:beers) → isHalal false even without ingredient match',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(
            _offJson(
              name: 'Craft Beer',
              ingredients: 'water, barley malt, hops, yeast',
              categoriesTags: [
                'en:beverages',
                'en:alcoholic-beverages',
                'en:beers',
              ],
            ),
          ),
        );

        final p = await ProductService().getProduct('1000000008');
        expect(p!.isHalal, isFalse);
        expect(p.isUnknown, isFalse);
      },
    );

    test('German pork (schweinefleisch) → isHalal false', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Wurst',
            ingredients: 'schweinefleisch, salz, gewürze',
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000009');
      expect(p!.isHalal, isFalse);
      expect(
        p.haramIngredients.any((i) => i.contains('schweinefleisch')),
        isTrue,
      );
    });

    test('e120 (carmine) → isHalal false', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Red Candy',
            ingredients: 'sugar, water, e120, citric acid',
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000010');
      expect(p!.isHalal, isFalse);
      expect(p.haramIngredients, contains('e120'));
    });
  });

  // ── unknown products ──────────────────────────────────────────────────────

  group('getProduct — unknown', () {
    test('no ingredients and no haram signals → isUnknown true', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(_offJson(name: 'Mystery Product', ingredients: '')),
      );

      final p = await ProductService().getProduct('1000000011');
      expect(p!.isUnknown, isTrue);
      expect(p.isHalal, isFalse);
    });

    test(
      'no ingredients but haram name → isHalal false, isUnknown false',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(_offJson(name: 'Wieselburger Bier', ingredients: '')),
        );

        final p = await ProductService().getProduct('1000000012');
        expect(p!.isHalal, isFalse);
        expect(p.isUnknown, isFalse);
      },
    );
  });

  // ── not found / HTTP errors ───────────────────────────────────────────────

  group('getProduct — not found / errors', () {
    test('all APIs return status 0 → null', () async {
      ProductService().setHttpClientForTesting(_mockGet(_notFoundJson));

      expect(await ProductService().getProduct('9999999991'), isNull);
    });

    test('all APIs return HTTP 500 → null', () async {
      ProductService().setHttpClientForTesting(
        MockClient((_) async => http.Response('', 500)),
      );

      expect(await ProductService().getProduct('9999999992'), isNull);
    });
  });

  // ── ingredient parsing ────────────────────────────────────────────────────

  group('getProduct — ingredient parsing', () {
    test(
      'falls back to ingredients_text_de when ingredients_text is empty',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(
            _offJson(
              name: 'Deutsches Produkt',
              ingredients: '',
              ingredientsTextDe: 'schweinefleisch, salz',
            ),
          ),
        );

        final p = await ProductService().getProduct('1000000013');
        expect(p!.isHalal, isFalse);
      },
    );

    test('falls back to structured ingredients array', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Structured Product',
            ingredients: '',
            structuredIngredients: [
              {'text': 'pork'},
              {'text': 'salt'},
            ],
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000014');
      expect(p!.isHalal, isFalse);
      expect(p.haramIngredients, contains('pork'));
    });

    test('image URL .100. is optimized to .400.', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Branded Product',
            ingredients: 'water',
            imageUrl: 'https://images.openfoodfacts.org/img/product.100.jpg',
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000015');
      expect(p!.imageUrl, contains('.400.'));
      expect(p.imageUrl, isNot(contains('.100.')));
    });

    test('labels parsed from labels_tags array', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Certified Product',
            ingredients: 'water, salt',
            labelsTags: ['en:halal', 'en:organic'],
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000016');
      expect(p!.labels, containsAll(['en:halal', 'en:organic']));
    });

    test('product name used as fallback when product_name is blank', () async {
      ProductService().setHttpClientForTesting(
        MockClient((req) async {
          if (req.method == 'POST') return http.Response('', 500);
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': '',
                'product_name_en': 'Fallback Name',
                'ingredients_text': 'water',
                'categories_tags': [],
              },
            }),
            200,
          );
        }),
      );

      final p = await ProductService().getProduct('1000000017');
      expect(p!.name, equals('Fallback Name'));
    });
  });

  // ── cache behaviour ───────────────────────────────────────────────────────

  group('getProduct — caching', () {
    test(
      'second call with same barcode is served from cache (no extra HTTP)',
      () async {
        var calls = 0;
        ProductService().setHttpClientForTesting(
          _mockGetWithCallback((_) async {
            calls++;
            return http.Response(
              _offJson(name: 'Cached Product', ingredients: 'water'),
              200,
            );
          }),
        );

        await ProductService().getProduct('1000000018');
        await ProductService().getProduct('1000000018');
        expect(calls, equals(1));
      },
    );
  });

  // ── refreshProduct ────────────────────────────────────────────────────────

  group('refreshProduct', () {
    test('bypasses cache and issues a new HTTP request', () async {
      var calls = 0;
      ProductService().setHttpClientForTesting(
        _mockGetWithCallback((_) async {
          calls++;
          return http.Response(
            _offJson(name: 'Refreshed Product', ingredients: 'water'),
            200,
          );
        }),
      );

      await ProductService().getProduct('1000000019');
      await ProductService().refreshProduct('1000000019');
      expect(calls, equals(2));
    });
  });

  // ── _applyKeywordSafety (via OFf fallback path) ───────────────────────────

  group('_applyKeywordSafety', () {
    test('ingredientWarnings are populated for haram ingredients', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(_offJson(name: 'Pork Pie', ingredients: 'pork, pastry, salt')),
      );

      final p = await ProductService().getProduct('1000000020');
      expect(p!.ingredientWarnings, isNotEmpty);
      expect(p.ingredientWarnings.keys.any((k) => k.contains('pork')), isTrue);
    });

    test(
      'ingredientWarnings are populated for suspicious ingredients',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(
            _offJson(
              name: 'Bread',
              ingredients: 'flour, water, yeast, enzymes',
            ),
          ),
        );

        final p = await ProductService().getProduct('1000000021');
        expect(p!.ingredientWarnings, isNotEmpty);
        expect(
          p.ingredientWarnings.keys.any((k) => k.contains('enzymes')),
          isTrue,
        );
      },
    );
  });

  // ── explanation text ──────────────────────────────────────────────────────

  group('explanation text', () {
    test('haram product explanation mentions the ingredient', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(_offJson(name: 'Spam', ingredients: 'pork, salt, water')),
      );

      final p = await ProductService().getProduct('1000000022');
      expect(p!.explanation, contains('pork'));
    });

    test(
      'unknown product explanation says status cannot be determined',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(_offJson(name: 'Mystery Box', ingredients: '')),
        );

        final p = await ProductService().getProduct('1000000023');
        expect(p!.explanation, contains('cannot be determined'));
      },
    );

    test('haram category explanation references the category', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Premium Sparkling',
            ingredients: '',
            categoriesTags: ['en:wines'],
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000024');
      expect(p!.explanation, contains('en:wines'));
    });
  });
}
