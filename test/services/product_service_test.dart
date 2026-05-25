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
  if (imageUrl != null) {
    product['image_url'] = imageUrl;
  }
  if (ingredientsTextDe != null) {
    product['ingredients_text_de'] = ingredientsTextDe;
  }
  if (structuredIngredients != null) {
    product['ingredients'] = structuredIngredients;
  }
  return jsonEncode({'status': 1, 'product': product});
}

final _notFoundJson = jsonEncode({'status': 0});

// Mock that returns the given body for every GET and 500 for every POST
// (so the Supabase backend path is skipped cleanly in tests).
MockClient _mockGet(String body, {int status = 200}) => MockClient((req) async {
  if (req.method == 'POST') {
    return http.Response('', 500);
  }
  return http.Response(body, status);
});

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

    test('whey → suspicious, not halal', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(name: 'Yogurt', ingredients: 'milk, whey powder, cultures'),
        ),
      );

      final p = await ProductService().getProduct('1000000002');
      expect(p!.isHalal, isFalse);
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

    test(
      'vegan product does not require halal certification when category tags imply meat',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(
            _offJson(
              name: 'Vegan Burger',
              ingredients: '',
              categoriesTags: ['en:meats'],
              labelsTags: ['en:vegan'],
            ),
          ),
        );

        ProductService().setHttpClientForTesting(
          _mockGetWithCallback((req) async {
            if (req.url.host == 'world.openfoodfacts.org') {
              return http.Response(
                _offJson(
                  name: 'Vegan Burger',
                  ingredients: '',
                  categoriesTags: ['en:meats'],
                  labelsTags: ['en:vegan'],
                ),
                200,
              );
            }
            return http.Response(_notFoundJson, 200);
          }),
        );

        final p = await ProductService().getProduct('1000000050');
        expect(p!.requiresHalalCert, isFalse);
        expect(p.isUnknown, isTrue);
      },
    );
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
      final body = _offJson(name: 'Mystery Product', ingredients: '');
      ProductService().setHttpClientForTesting(
        _mockGetWithCallback((req) async {
          // Only OFf has this product — OBF/OPF must return not-found so the
          // cross-listing check doesn't accidentally mark it as non-food.
          if (req.url.host == 'world.openfoodfacts.org') {
            return http.Response(body, 200);
          }
          return http.Response(_notFoundJson, 200);
        }),
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

  // ── isFattyAlcohol ────────────────────────────────────────────────────────

  group('isFattyAlcohol', () {
    test('cetyl alcohol → true', () {
      expect(ProductService.isFattyAlcohol('cetyl alcohol'), isTrue);
    });

    test('stearyl alcohol → true', () {
      expect(ProductService.isFattyAlcohol('stearyl alcohol'), isTrue);
    });

    test('behenyl alcohol → true', () {
      expect(ProductService.isFattyAlcohol('behenyl alcohol'), isTrue);
    });

    test('cetostearyl alcohol → true', () {
      expect(ProductService.isFattyAlcohol('cetostearyl alcohol'), isTrue);
    });

    test('plain alcohol → false', () {
      expect(ProductService.isFattyAlcohol('alcohol'), isFalse);
    });

    test('ethanol → false', () {
      expect(ProductService.isFattyAlcohol('ethanol'), isFalse);
    });

    test('case-insensitive: CETYL ALCOHOL → true', () {
      expect(ProductService.isFattyAlcohol('CETYL ALCOHOL'), isTrue);
    });
  });

  // ── matchesKeyword ────────────────────────────────────────────────────────

  group('matchesKeyword', () {
    test('exact match → true', () {
      expect(ProductService.matchesKeyword('pork', 'pork'), isTrue);
    });

    test('no match → false', () {
      expect(ProductService.matchesKeyword('water', 'pork'), isFalse);
    });

    test('multilingual variant: schweinefleisch matches pork keyword', () {
      expect(ProductService.matchesKeyword('schweinefleisch', 'pork'), isTrue);
    });

    test('multilingual variant: gelatine matches gelatin keyword', () {
      expect(ProductService.matchesKeyword('gelatine', 'gelatin'), isTrue);
    });

    test('hyphenated e-number variant: e-120 matches e120 keyword', () {
      expect(ProductService.matchesKeyword('e-120', 'e120'), isTrue);
    });

    test('alcohol-free is not matched by alcohol keyword', () {
      expect(
        ProductService.matchesKeyword('malt (alcohol-free)', 'alcohol'),
        isFalse,
      );
    });

    test('cetyl alcohol is not matched by alcohol keyword', () {
      expect(
        ProductService.matchesKeyword('cetyl alcohol', 'alcohol'),
        isFalse,
      );
    });

    test('word boundary: alcoholic is not matched by alcohol keyword', () {
      expect(
        ProductService.matchesKeyword('alcoholic extract', 'alcohol'),
        isFalse,
      );
    });

    test(
      'multi-word variant: natural flavor matches natural flavour keyword',
      () {
        expect(
          ProductService.matchesKeyword('natural flavor', 'natural flavour'),
          isTrue,
        );
      },
    );
  });

  // ── analyzeWithKeywords ───────────────────────────────────────────────────

  group('analyzeWithKeywords', () {
    test('empty list → isHalal true, explanation says no data', () {
      final result = ProductService.analyzeWithKeywords([]);
      expect(result.isHalal, isTrue);
      expect(result.haram, isEmpty);
      expect(result.suspicious, isEmpty);
      expect(result.explanation, contains('No ingredient data'));
    });

    test('clean ingredients → isHalal true, no flags', () {
      final result = ProductService.analyzeWithKeywords([
        'water',
        'salt',
        'sugar',
      ]);
      expect(result.isHalal, isTrue);
      expect(result.haram, isEmpty);
      expect(result.suspicious, isEmpty);
    });

    test('haram ingredient → isHalal false, haram list populated', () {
      final result = ProductService.analyzeWithKeywords(['pork', 'salt']);
      expect(result.isHalal, isFalse);
      expect(result.haram, contains('pork'));
      expect(result.warnings['pork'], isNotNull);
    });

    test(
      'suspicious ingredient → isHalal false, suspicious list populated',
      () {
        final result = ProductService.analyzeWithKeywords([
          'flour',
          'enzymes',
          'water',
        ]);
        expect(result.isHalal, isFalse);
        expect(result.suspicious, contains('enzymes'));
        expect(result.warnings['enzymes'], isNotNull);
      },
    );

    test('haram takes priority over suspicious for same ingredient', () {
      // gelatin is haram; it should not also appear in suspicious
      final result = ProductService.analyzeWithKeywords(['gelatin']);
      expect(result.haram, contains('gelatin'));
      expect(result.suspicious, isEmpty);
    });

    test('haram explanation mentions the ingredient', () {
      final result = ProductService.analyzeWithKeywords(['wine', 'water']);
      expect(result.explanation, contains('wine'));
      expect(result.explanation, contains('not permissible'));
    });

    test('suspicious-only explanation mentions verification', () {
      final result = ProductService.analyzeWithKeywords(['whey', 'water']);
      expect(result.explanation, contains('verification'));
    });

    test('clean ingredients explanation confirms no haram detected', () {
      final result = ProductService.analyzeWithKeywords(['water', 'salt']);
      expect(result.explanation, contains('No haram'));
    });

    test('warnings map has correct reason for carmine (e120)', () {
      final result = ProductService.analyzeWithKeywords(['e120']);
      expect(result.warnings['e120'], contains('animal-derived'));
    });
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
        final body = _offJson(name: 'Mystery Box', ingredients: '');
        ProductService().setHttpClientForTesting(
          _mockGetWithCallback((req) async {
            // Only OFf has this product — OBF/OPF must return not-found so the
            // cross-listing check doesn't accidentally mark it as non-food.
            if (req.url.host == 'world.openfoodfacts.org') {
              return http.Response(body, 200);
            }
            return http.Response(_notFoundJson, 200);
          }),
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

  // ── non-food category detection ───────────────────────────────────────────

  group('getProduct — non-food by OFf category tag', () {
    test('en:non-food-products → isNonFood true, isUnknown false', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Cleaning Spray',
            ingredients: '',
            categoriesTags: ['en:non-food-products', 'en:cleaning-products'],
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000030');
      expect(p, isNotNull);
      expect(p!.isNonFood, isTrue);
      expect(p.isUnknown, isFalse);
      expect(p.explanation, isEmpty);
    });

    test('en:cosmetics → isNonFood true', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Face Cream',
            ingredients: '',
            categoriesTags: ['en:cosmetics', 'en:beauty-products'],
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000031');
      expect(p!.isNonFood, isTrue);
      expect(p.isUnknown, isFalse);
    });

    test('en:diapers → isNonFood true', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Baby Diapers',
            ingredients: '',
            categoriesTags: ['en:baby-products', 'en:diapers'],
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000032');
      expect(p!.isNonFood, isTrue);
      expect(p.isUnknown, isFalse);
    });

    test('en:baby-care → isNonFood true', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Baby Lotion',
            ingredients: '',
            categoriesTags: ['en:baby-care', 'en:baby-lotions'],
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000033');
      expect(p!.isNonFood, isTrue);
    });

    test(
      'en:baby-products alone (no non-food sub-tag) → normal analysis, not non-food',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(
            _offJson(
              name: 'Baby Formula',
              ingredients: 'skimmed milk, lactose, vegetable oils',
              categoriesTags: ['en:baby-products', 'en:baby-milks'],
            ),
          ),
        );

        final p = await ProductService().getProduct('1000000034');
        expect(p!.isNonFood, isFalse);
        expect(p.isUnknown, isFalse);
        expect(p.isHalal, isTrue);
      },
    );

    test(
      'en:medicines → analyzed normally, gelatin detected as haram',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(
            _offJson(
              name: 'Ibuprofen Capsules',
              ingredients: 'ibuprofen, gelatin, magnesium stearate',
              categoriesTags: ['en:medicines'],
            ),
          ),
        );

        final p = await ProductService().getProduct('1000000035');
        expect(p!.isNonFood, isFalse);
        expect(p.isHalal, isFalse);
        expect(p.haramIngredients, contains('gelatin'));
      },
    );

    test(
      'en:dietary-supplements → analyzed normally, gelatin detected as haram',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(
            _offJson(
              name: 'Fish Oil Capsules',
              ingredients: 'fish oil, gelatin, glycerin',
              categoriesTags: ['en:dietary-supplements'],
            ),
          ),
        );

        final p = await ProductService().getProduct('1000000036');
        expect(p!.isNonFood, isFalse);
        expect(p.isHalal, isFalse);
        expect(p.haramIngredients, contains('gelatin'));
      },
    );
  });

  group('getProduct — non-food category edge cases', () {
    test('en:pet-food → isNonFood true', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Dog Kibble',
            ingredients: '',
            categoriesTags: ['en:pet-food', 'en:dog-food'],
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000042');
      expect(p!.isNonFood, isTrue);
      expect(p.isUnknown, isFalse);
    });

    test(
      'non-food category + OFf has ingredient data → ingredients discarded, isNonFood true',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGet(
            _offJson(
              name: 'Moisturiser',
              ingredients: 'water, glycerin, alcohol, parfum',
              categoriesTags: ['en:cosmetics'],
            ),
          ),
        );

        final p = await ProductService().getProduct('1000000043');
        expect(p!.isNonFood, isTrue);
        expect(p.isUnknown, isFalse);
        expect(p.ingredients, isEmpty);
      },
    );

    test('non-food category takes priority over haram category', () async {
      ProductService().setHttpClientForTesting(
        _mockGet(
          _offJson(
            name: 'Alcohol Hand Gel',
            ingredients: '',
            categoriesTags: ['en:cosmetics', 'en:alcoholic-beverages'],
          ),
        ),
      );

      final p = await ProductService().getProduct('1000000044');
      expect(p!.isNonFood, isTrue);
      expect(p.isUnknown, isFalse);
    });
  });

  group('getProduct — non-food via OBF/OPF database', () {
    test('product found in OBF (not OFf) → isNonFood true', () async {
      ProductService().setHttpClientForTesting(
        _mockGetWithCallback((req) async {
          if (req.url.host == 'world.openfoodfacts.org') {
            return http.Response(_notFoundJson, 200);
          }
          if (req.url.host == 'world.openbeautyfacts.org') {
            return http.Response(
              _offJson(name: 'Shampoo', ingredients: ''),
              200,
            );
          }
          return http.Response(_notFoundJson, 200);
        }),
      );

      final p = await ProductService().getProduct('1000000037');
      expect(p!.isNonFood, isTrue);
      expect(p.isUnknown, isFalse);
      expect(p.explanation, isEmpty);
    });

    test('product found in OPF (not OFf/OBF) → isNonFood true', () async {
      ProductService().setHttpClientForTesting(
        _mockGetWithCallback((req) async {
          if (req.url.host == 'world.openproductsfacts.org') {
            return http.Response(
              _offJson(name: 'Tape Roll', ingredients: ''),
              200,
            );
          }
          return http.Response(_notFoundJson, 200);
        }),
      );

      final p = await ProductService().getProduct('1000000038');
      expect(p!.isNonFood, isTrue);
      expect(p.isUnknown, isFalse);
    });

    test(
      'OFf unknown + found in OBF → isNonFood true (cross-listing detection)',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGetWithCallback((req) async {
            if (req.url.host == 'world.openfoodfacts.org') {
              // Found in OFf but no ingredients — would be unknown on its own.
              return http.Response(
                _offJson(name: 'Cleaning Spray', ingredients: ''),
                200,
              );
            }
            if (req.url.host == 'world.openbeautyfacts.org') {
              return http.Response(
                _offJson(name: 'Cleaning Spray', ingredients: ''),
                200,
              );
            }
            return http.Response(_notFoundJson, 200);
          }),
        );

        final p = await ProductService().getProduct('1000000039');
        expect(p!.isNonFood, isTrue);
        expect(p.isUnknown, isFalse);
        expect(p.explanation, isEmpty);
      },
    );

    test(
      'OFf unknown + found in OPF → isNonFood true (cross-listing detection)',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGetWithCallback((req) async {
            if (req.url.host == 'world.openfoodfacts.org') {
              return http.Response(
                _offJson(name: 'Stationery Kit', ingredients: ''),
                200,
              );
            }
            if (req.url.host == 'world.openproductsfacts.org') {
              return http.Response(
                _offJson(name: 'Stationery Kit', ingredients: ''),
                200,
              );
            }
            return http.Response(_notFoundJson, 200);
          }),
        );

        final p = await ProductService().getProduct('1000000040');
        expect(p!.isNonFood, isTrue);
        expect(p.isUnknown, isFalse);
      },
    );

    test(
      'OFf unknown + not in OBF/OPF → still returns unknown (not null)',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGetWithCallback((req) async {
            if (req.url.host == 'world.openfoodfacts.org') {
              return http.Response(
                _offJson(name: 'Mystery Item', ingredients: ''),
                200,
              );
            }
            return http.Response(_notFoundJson, 200);
          }),
        );

        final p = await ProductService().getProduct('1000000041');
        expect(p, isNotNull);
        expect(p!.isUnknown, isTrue);
        expect(p.isNonFood, isFalse);
      },
    );

    test(
      'OFf unknown + OBF HTTP error → falls through to OPF, returns non-food',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGetWithCallback((req) async {
            if (req.url.host == 'world.openfoodfacts.org') {
              return http.Response(
                _offJson(name: 'Mystery Spray', ingredients: ''),
                200,
              );
            }
            if (req.url.host == 'world.openbeautyfacts.org') {
              return http.Response('server error', 500);
            }
            if (req.url.host == 'world.openproductsfacts.org') {
              return http.Response(
                _offJson(name: 'Mystery Spray', ingredients: ''),
                200,
              );
            }
            return http.Response(_notFoundJson, 200);
          }),
        );

        final p = await ProductService().getProduct('1000000045');
        expect(p!.isNonFood, isTrue);
        expect(p.isUnknown, isFalse);
      },
    );

    test(
      'OFf unknown + both OBF and OPF HTTP errors → falls back to OFf unknown',
      () async {
        ProductService().setHttpClientForTesting(
          _mockGetWithCallback((req) async {
            if (req.url.host == 'world.openfoodfacts.org') {
              return http.Response(
                _offJson(name: 'Mystery Item', ingredients: ''),
                200,
              );
            }
            return http.Response('server error', 500);
          }),
        );

        final p = await ProductService().getProduct('1000000046');
        expect(p, isNotNull);
        expect(p!.isUnknown, isTrue);
        expect(p.isNonFood, isFalse);
      },
    );
  });
}
