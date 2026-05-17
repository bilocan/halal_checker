import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/cache_service.dart';
import 'package:halal_checker/services/product_service.dart';
import 'package:halal_checker/services/test_product_repository.dart';

// ── constants ─────────────────────────────────────────────────────────────────

const _kBarcode = '1234567890';
const _kSupabaseUrl = 'https://test.supabase.co';
const _kAnonKey = 'test_anon_key';

// ── fixture builders ──────────────────────────────────────────────────────────

// Supabase REST row (snake_case) returned by _fetchFromSharedDb.
Map<String, dynamic> _dbRow({
  String barcode = _kBarcode,
  String name = 'Test Product',
  List<dynamic> ingredients = const ['water', 'salt'],
  bool isHalal = true,
  bool isUnknown = false,
  bool isNonFood = false,
  List<dynamic> haramIngredients = const [],
  List<dynamic> suspiciousIngredients = const [],
  bool isManaged = false,
  bool needsReanalysis = false,
}) => {
  'barcode': barcode,
  'name': name,
  'ingredients': ingredients,
  'is_halal': isHalal,
  'is_unknown': isUnknown,
  'is_non_food': isNonFood,
  'haram_ingredients': haramIngredients,
  'suspicious_ingredients': suspiciousIngredients,
  'ingredient_warnings': <String, dynamic>{},
  'labels': <dynamic>[],
  'image_url': null,
  'image_front_url': null,
  'image_ingredients_url': null,
  'image_nutrition_url': null,
  'explanation': 'Test explanation.',
  'analyzed_by_ai': false,
  'requires_halal_cert': false,
  'is_managed': isManaged,
  'needs_reanalysis': needsReanalysis,
  'fetched_at': '2026-01-01T00:00:00.000Z',
};

// Edge Function product JSON (camelCase) returned by _fetchFromBackend.
Map<String, dynamic> _efProduct({
  String barcode = _kBarcode,
  String name = 'Fresh EF Product',
  bool isHalal = true,
  bool isUnknown = false,
  List<dynamic> haramIngredients = const [],
  List<dynamic> suspiciousIngredients = const [],
  bool needsReanalysis = false,
}) => {
  'barcode': barcode,
  'name': name,
  'ingredients': ['water', 'salt'],
  'isHalal': isHalal,
  'isUnknown': isUnknown,
  'isNonFood': false,
  'haramIngredients': haramIngredients,
  'suspiciousIngredients': suspiciousIngredients,
  'ingredientWarnings': <String, dynamic>{},
  'labels': <dynamic>[],
  'imageUrl': null,
  'imageFrontUrl': null,
  'imageIngredientsUrl': null,
  'imageNutritionUrl': null,
  'explanation': 'Fresh result from Edge Function.',
  'analyzedByAI': false,
  'analysisMethod': 'keyword',
  'requiresHalalCert': false,
  'isManaged': false,
  'needsReanalysis': needsReanalysis,
};

// Minimal halal OFf response for Step 4 fallback tests.
final _offHalalJson = jsonEncode({
  'status': 1,
  'product': {
    'product_name': 'OFf Fallback Product',
    'ingredients_text': 'water, salt',
    'categories_tags': <dynamic>[],
    'labels': '',
    'labels_tags': <dynamic>[],
  },
});

// ── mock HTTP client builder ──────────────────────────────────────────────────

// Routes requests by host / method.
// - Supabase GET  → Supabase REST (product row or empty list)
// - Supabase POST → Edge Function (product JSON or 500)
// - OFf / OBF / OPF GET → OpenFoodFacts
// Passes each request to [onRequest] before responding (for call tracking).
MockClient _makeClient({
  Map<String, dynamic>? dbRow, // null = product not in DB
  Map<String, dynamic>? efResponse, // null = EF returns 500
  String? offBody, // null = OFf returns not-found
  void Function(http.Request)? onRequest,
}) => MockClient((req) async {
  onRequest?.call(req);

  if (req.url.host.contains('supabase.co')) {
    if (req.method == 'GET') {
      final body = dbRow != null ? jsonEncode([dbRow]) : jsonEncode([]);
      return http.Response(body, 200);
    }
    if (req.method == 'POST' && efResponse != null) {
      return http.Response(jsonEncode({'product': efResponse}), 200);
    }
    return http.Response('', 500);
  }

  if (req.url.host.contains('openfoodfacts.org') ||
      req.url.host.contains('openbeautyfacts.org') ||
      req.url.host.contains('openproductsfacts.org')) {
    return http.Response(offBody ?? jsonEncode({'status': 0}), 200);
  }

  return http.Response('', 500);
});

// ── test setup helpers ────────────────────────────────────────────────────────

void _setUp() {
  SharedPreferences.setMockInitialValues({});
  ProductService().enableSupabaseForTesting(url: _kSupabaseUrl, key: _kAnonKey);
}

void _tearDown() {
  ProductService()
    ..setHttpClientForTesting(http.Client())
    ..resetForTesting();
}

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestProductRepository.dbPathOverride = inMemoryDatabasePath;
  });

  // ── Product model ─────────────────────────────────────────────────────────

  group('Product.needsReanalysis — model', () {
    test('defaults to false', () {
      final p = Product(
        barcode: '123',
        name: 'X',
        ingredients: [],
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        labels: [],
      );
      expect(p.needsReanalysis, isFalse);
    });

    test('fromJson deserializes true', () {
      final p = Product.fromJson({
        'barcode': '123',
        'name': 'X',
        'ingredients': <dynamic>[],
        'isHalal': true,
        'isUnknown': false,
        'isNonFood': false,
        'haramIngredients': <dynamic>[],
        'suspiciousIngredients': <dynamic>[],
        'ingredientWarnings': <String, dynamic>{},
        'labels': <dynamic>[],
        'explanation': '',
        'analyzedByAI': false,
        'needsReanalysis': true,
      });
      expect(p.needsReanalysis, isTrue);
    });

    test('fromJson defaults to false when key absent', () {
      final p = Product.fromJson({
        'barcode': '123',
        'name': 'X',
        'ingredients': <dynamic>[],
        'isHalal': true,
        'isUnknown': false,
        'isNonFood': false,
        'haramIngredients': <dynamic>[],
        'suspiciousIngredients': <dynamic>[],
        'ingredientWarnings': <String, dynamic>{},
        'labels': <dynamic>[],
        'explanation': '',
        'analyzedByAI': false,
      });
      expect(p.needsReanalysis, isFalse);
    });

    test('toJson includes key when true', () {
      final p = Product(
        barcode: '123',
        name: 'X',
        ingredients: [],
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        labels: [],
        needsReanalysis: true,
      );
      expect(p.toJson(), containsPair('needsReanalysis', true));
    });

    test('toJson omits key when false', () {
      final p = Product(
        barcode: '123',
        name: 'X',
        ingredients: [],
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        labels: [],
      );
      expect(p.toJson().containsKey('needsReanalysis'), isFalse);
    });

    test('copyWith can set needsReanalysis', () {
      final original = Product(
        barcode: '123',
        name: 'X',
        ingredients: [],
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        labels: [],
      );
      final copy = original.copyWith(needsReanalysis: true);
      expect(original.needsReanalysis, isFalse);
      expect(copy.needsReanalysis, isTrue);
    });

    test('copyWith preserves needsReanalysis when not overridden', () {
      final original = Product(
        barcode: '123',
        name: 'X',
        ingredients: [],
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        labels: [],
        needsReanalysis: true,
      );
      final copy = original.copyWith(name: 'Y');
      expect(copy.needsReanalysis, isTrue);
    });
  });

  // ── pipeline behavior ─────────────────────────────────────────────────────

  group('needsReanalysis — pipeline', () {
    setUp(() async {
      await TestProductRepository.instance.closeForTesting();
      _setUp();
    });

    tearDown(_tearDown);

    // Step 2 short-circuits when needsReanalysis=false.
    test(
      'DB hit needsReanalysis=false → returned directly, no EF call',
      () async {
        var efCalled = false;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(isHalal: true, needsReanalysis: false),
            onRequest: (req) {
              if (req.method == 'POST') efCalled = true;
            },
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        expect(p, isNotNull);
        expect(p!.isHalal, isTrue);
        expect(efCalled, isFalse);
      },
    );

    // Step 2 must NOT short-circuit when needsReanalysis=true.
    test(
      'DB hit needsReanalysis=true → EF is called for fresh analysis',
      () async {
        var efCalled = false;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(isHalal: false, needsReanalysis: true),
            efResponse: _efProduct(isHalal: true, name: 'Fresh EF Product'),
            onRequest: (req) {
              if (req.method == 'POST') efCalled = true;
            },
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        // EF was called; verdict from EF (halal) overrides DB row (not halal).
        // Note: name comes from _mergeApprovedImages which always uses the DB name.
        expect(efCalled, isTrue);
        expect(p, isNotNull);
        expect(p!.isHalal, isTrue);
      },
    );

    // EF returns a halal verdict after re-analysis.
    test(
      'needsReanalysis=true + EF returns halal → product is halal',
      () async {
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(isHalal: false, needsReanalysis: true),
            efResponse: _efProduct(isHalal: true),
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        expect(p!.isHalal, isTrue);
        expect(p.haramIngredients, isEmpty);
      },
    );

    // EF returns a not-halal verdict after re-analysis.
    test(
      'needsReanalysis=true + EF returns haram → product is not halal',
      () async {
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(needsReanalysis: true),
            efResponse: _efProduct(isHalal: false, haramIngredients: ['pork']),
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        expect(p!.isHalal, isFalse);
        expect(p.haramIngredients, contains('pork'));
      },
    );

    // When the EF fails the client falls through to OFf direct fetch (Step 4).
    test('needsReanalysis=true + EF fails → falls through to OFf', () async {
      var offCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(needsReanalysis: true),
          efResponse: null, // 500
          offBody: _offHalalJson,
          onRequest: (req) {
            if (req.url.host.contains('openfoodfacts.org')) offCalled = true;
          },
        ),
      );

      final p = await ProductService().getProduct(_kBarcode);

      expect(offCalled, isTrue);
      expect(p, isNotNull);
      expect(p!.isHalal, isTrue);
    });

    // Product not in DB at all → normal OFf path is unaffected.
    test('product not in DB → OFf path works normally (regression)', () async {
      var offCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: null,
          efResponse: null,
          offBody: _offHalalJson,
          onRequest: (req) {
            if (req.url.host.contains('openfoodfacts.org')) offCalled = true;
          },
        ),
      );

      final p = await ProductService().getProduct(_kBarcode);

      expect(offCalled, isTrue);
      expect(p, isNotNull);
    });

    // Managed product: isManaged=true takes priority in Step 1; needsReanalysis ignored.
    test(
      'managed product needsReanalysis=true → managed DB row returned',
      () async {
        // Pre-populate local cache so Step 1 runs.
        final dbProduct = Product(
          barcode: _kBarcode,
          name: 'Managed Product',
          ingredients: const ['chicken'],
          isHalal: true,
          haramIngredients: const [],
          suspiciousIngredients: const [],
          ingredientWarnings: const {},
          labels: const [],
          isManaged: true,
          needsReanalysis: true,
        );
        await CacheService().saveProduct(_kBarcode, dbProduct);

        var efCalled = false;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(isManaged: true, needsReanalysis: true),
            onRequest: (req) {
              if (req.method == 'POST') efCalled = true;
            },
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        // Managed product takes priority; no EF call.
        expect(p, isNotNull);
        expect(p!.isManaged, isTrue);
        expect(efCalled, isFalse);
      },
    );

    // Local cache with needsReanalysis=false in DB → cache served (Step 1).
    test(
      'cached product + DB needsReanalysis=false → cache returned, no EF',
      () async {
        // Warm the local cache via a first lookup.
        ProductService().setHttpClientForTesting(
          _makeClient(dbRow: _dbRow(isHalal: true, needsReanalysis: false)),
        );
        await ProductService().getProduct(_kBarcode);

        // Second lookup: same DB row (still false), expect cache hit.
        var efCalled = false;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(isHalal: true, needsReanalysis: false),
            onRequest: (req) {
              if (req.method == 'POST') efCalled = true;
            },
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        expect(p, isNotNull);
        expect(efCalled, isFalse);
      },
    );

    // Local cache present but DB now has needsReanalysis=true → cache bypassed.
    test(
      'cached product + DB needsReanalysis=true → cache bypassed, EF called',
      () async {
        // Warm the local cache.
        ProductService().setHttpClientForTesting(
          _makeClient(dbRow: _dbRow(isHalal: true, needsReanalysis: false)),
        );
        await ProductService().getProduct(_kBarcode);

        // Now DB row has needsReanalysis=true (e.g. admin edited the product).
        // EF verdict: not halal (pork found).
        var efCalled = false;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(isHalal: true, needsReanalysis: true),
            efResponse: _efProduct(isHalal: false, haramIngredients: ['lard']),
            onRequest: (req) {
              if (req.method == 'POST') efCalled = true;
            },
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        // EF was called; fresh verdict (not halal) overrides stale cache (halal).
        expect(efCalled, isTrue);
        expect(p!.isHalal, isFalse);
        expect(p.haramIngredients, contains('lard'));
      },
    );

    // Haram keyword in ingredients: keyword safety override still applies after EF.
    test(
      'needsReanalysis=true + EF says halal but has pork → keyword override wins',
      () async {
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(needsReanalysis: true),
            // EF mistakenly says halal despite pork in ingredients.
            efResponse: _efProduct(
              isHalal: true,
              haramIngredients: [],
              // Return pork in the ingredients list so the client-side keyword
              // safety override can catch it.
            )..['ingredients'] = ['pork', 'salt'],
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        // Client-side keyword safety override must flag pork as haram.
        expect(p!.isHalal, isFalse);
        expect(p.haramIngredients, isNotEmpty);
      },
    );

    // isUnknown=true in DB has same fall-through behaviour regardless of flag.
    test(
      'DB has isUnknown=true + needsReanalysis=false → falls through (unchanged)',
      () async {
        var efCalled = false;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(
              isHalal: false,
              isUnknown: true,
              needsReanalysis: false,
            ),
            efResponse: _efProduct(isHalal: true),
            onRequest: (req) {
              if (req.method == 'POST') efCalled = true;
            },
          ),
        );

        await ProductService().getProduct(_kBarcode);

        // isUnknown=true alone already causes fall-through; EF must be called.
        expect(efCalled, isTrue);
      },
    );

    // Both isUnknown=true and needsReanalysis=true → still falls through once.
    test(
      'DB has isUnknown=true + needsReanalysis=true → EF called once',
      () async {
        var efCallCount = 0;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(
              isHalal: false,
              isUnknown: true,
              needsReanalysis: true,
            ),
            efResponse: _efProduct(isHalal: true),
            onRequest: (req) {
              if (req.method == 'POST') efCallCount++;
            },
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        // Only one EF call despite two fall-through reasons.
        expect(efCallCount, 1);
        expect(p!.isHalal, isTrue);
      },
    );
  });
}
