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

// Timestamps used to express staleness:
//   _kUpdated > _kAnalysed  → stale  (source data changed after last analysis)
//   _kUpdated <= _kAnalysed → fresh
const _kAnalysed = '2026-01-01T01:00:00.000Z'; // last_analysed_at
const _kUpdated = '2026-01-01T02:00:00.000Z'; // updated_at — newer → stale
const _kFresh = '2026-01-01T00:00:00.000Z'; // updated_at — older → fresh
const _kOlderAnalysed = '2025-12-01T01:00:00.000Z'; // cache behind shared DB

// ── fixture builders ──────────────────────────────────────────────────────────

// Supabase REST row (snake_case) from products_full, returned by _fetchFromSharedDb.
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
  bool isStale = false, // true = updated_at > last_analysed_at
  String? lastAnalysedAt,
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
  'fetched_at': _kFresh,
  'last_analysed_at': lastAnalysedAt ?? _kAnalysed,
  'updated_at': isStale ? _kUpdated : _kFresh, // _kUpdated > _kAnalysed → stale
  'tags_version': 1,
};

// Edge Function product JSON (camelCase) returned by _fetchFromBackend.
Map<String, dynamic> _efProduct({
  String barcode = _kBarcode,
  String name = 'Fresh EF Product',
  bool isHalal = true,
  bool isUnknown = false,
  List<dynamic> haramIngredients = const [],
  List<dynamic> suspiciousIngredients = const [],
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
  'lastAnalysedAt': _kAnalysed,
  'updatedAt': _kFresh,
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

  group('Product.updatedAt / lastAnalysedAt — model', () {
    test('updatedAt defaults to null', () {
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
      expect(p.updatedAt, isNull);
      expect(p.lastAnalysedAt, isNull);
    });

    test('fromJson deserializes both timestamps', () {
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
        'updatedAt': _kUpdated,
        'lastAnalysedAt': _kAnalysed,
      });
      expect(p.updatedAt, isNotNull);
      expect(p.lastAnalysedAt, isNotNull);
      expect(p.updatedAt!.isAfter(p.lastAnalysedAt!), isTrue);
    });

    test('fromJson defaults timestamps to null when absent', () {
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
      expect(p.updatedAt, isNull);
      expect(p.lastAnalysedAt, isNull);
    });

    test('toJson includes timestamps when set', () {
      final p = Product(
        barcode: '123',
        name: 'X',
        ingredients: [],
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        labels: [],
        updatedAt: DateTime.parse(_kUpdated),
        lastAnalysedAt: DateTime.parse(_kAnalysed),
      );
      final j = p.toJson();
      expect(j.containsKey('updatedAt'), isTrue);
      expect(j.containsKey('lastAnalysedAt'), isTrue);
    });

    test('toJson omits timestamps when null', () {
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
      expect(p.toJson().containsKey('updatedAt'), isFalse);
      expect(p.toJson().containsKey('lastAnalysedAt'), isFalse);
    });

    test('copyWith can update timestamps', () {
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
      final ts = DateTime.parse(_kUpdated);
      final copy = original.copyWith(updatedAt: ts);
      expect(original.updatedAt, isNull);
      expect(copy.updatedAt, equals(ts));
    });

    test('copyWith preserves timestamps when not overridden', () {
      final ts = DateTime.parse(_kUpdated);
      final original = Product(
        barcode: '123',
        name: 'X',
        ingredients: [],
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        labels: [],
        updatedAt: ts,
      );
      final copy = original.copyWith(name: 'Y');
      expect(copy.updatedAt, equals(ts));
    });
  });

  // ── pipeline behaviour ────────────────────────────────────────────────────

  group('stale re-analysis — pipeline', () {
    setUp(() async {
      await TestProductRepository.instance.closeForTesting();
      _setUp();
    });

    tearDown(_tearDown);

    // Step 2 short-circuits when fresh (updated_at <= last_analysed_at).
    test('DB hit fresh → returned directly, no EF call', () async {
      var efCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isHalal: true, isStale: false),
          onRequest: (req) {
            if (req.method == 'POST') efCalled = true;
          },
        ),
      );

      final p = await ProductService().getProduct(_kBarcode);

      expect(p, isNotNull);
      expect(p!.isHalal, isTrue);
      expect(efCalled, isFalse);
    });

    // Step 2 must NOT short-circuit when stale (updated_at > last_analysed_at).
    test('DB hit stale → EF is called for fresh analysis', () async {
      var efCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isHalal: false, isStale: true),
          efResponse: _efProduct(isHalal: true),
          onRequest: (req) {
            if (req.method == 'POST') efCalled = true;
          },
        ),
      );

      final p = await ProductService().getProduct(_kBarcode);

      // EF was called; verdict from EF (halal) overrides DB row (not halal).
      expect(efCalled, isTrue);
      expect(p, isNotNull);
      expect(p!.isHalal, isTrue);
    });

    // EF returns a halal verdict after re-analysis.
    test('stale + EF returns halal → product is halal', () async {
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isHalal: false, isStale: true),
          efResponse: _efProduct(isHalal: true),
        ),
      );

      final p = await ProductService().getProduct(_kBarcode);

      expect(p!.isHalal, isTrue);
      expect(p.haramIngredients, isEmpty);
    });

    // EF returns a not-halal verdict after re-analysis.
    test('stale + EF returns haram → product is not halal', () async {
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isStale: true),
          efResponse: _efProduct(isHalal: false, haramIngredients: ['pork']),
        ),
      );

      final p = await ProductService().getProduct(_kBarcode);

      expect(p!.isHalal, isFalse);
      expect(p.haramIngredients, contains('pork'));
    });

    // When the EF fails the client falls through to OFf direct fetch (Step 4).
    test('stale + EF fails → falls through to OFf', () async {
      var offCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isStale: true),
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

    // Managed product: isManaged=true takes priority in Step 1; staleness ignored.
    test('managed product stale → managed DB row returned directly', () async {
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
        updatedAt: DateTime.parse(_kUpdated),
        lastAnalysedAt: DateTime.parse(_kAnalysed),
      );
      await CacheService().saveProduct(_kBarcode, dbProduct);

      var efCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isManaged: true, isStale: true),
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
    });

    // Shared DB re-analysis newer than local cache → DB served (Step 2).
    test('cached product + DB newer analysis → DB returned, no EF', () async {
      final cachedProduct = Product(
        barcode: _kBarcode,
        name: 'Cached Product',
        ingredients: const ['Aroma'],
        isHalal: false,
        haramIngredients: const [],
        suspiciousIngredients: const ['Aroma'],
        ingredientWarnings: const {},
        labels: const [],
        lastAnalysedAt: DateTime.parse(_kOlderAnalysed),
        updatedAt: DateTime.parse(_kFresh),
        tagsPopulated: true,
      );
      await CacheService().saveProduct(_kBarcode, cachedProduct);

      var efCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(
            isHalal: false,
            isStale: false,
            suspiciousIngredients: const ['alcohol extract'],
            lastAnalysedAt: _kAnalysed,
          ),
          onRequest: (req) {
            if (req.method == 'POST') efCalled = true;
          },
        ),
      );

      final p = await ProductService().getProduct(_kBarcode);

      expect(p, isNotNull);
      expect(efCalled, isFalse);
      expect(p!.suspiciousIngredients, contains('alcohol extract'));
      expect(p.suspiciousIngredients, isNot(contains('Aroma')));
    });

    // Local cache with fresh DB row → cache served (Step 1).
    test('cached product + DB fresh → cache returned, no EF', () async {
      // Warm the local cache via a first lookup.
      ProductService().setHttpClientForTesting(
        _makeClient(dbRow: _dbRow(isHalal: true, isStale: false)),
      );
      await ProductService().getProduct(_kBarcode);

      // Second lookup: same DB row (still fresh), expect cache hit.
      var efCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isHalal: true, isStale: false),
          onRequest: (req) {
            if (req.method == 'POST') efCalled = true;
          },
        ),
      );

      final p = await ProductService().getProduct(_kBarcode);

      expect(p, isNotNull);
      expect(efCalled, isFalse);
    });

    // Local cache present but DB is now stale → cache bypassed.
    test('cached product + DB stale → cache bypassed, EF called', () async {
      // Warm the local cache.
      ProductService().setHttpClientForTesting(
        _makeClient(dbRow: _dbRow(isHalal: true, isStale: false)),
      );
      await ProductService().getProduct(_kBarcode);

      // DB row is now stale (e.g. admin edited the product after the cache was written).
      // EF verdict: not halal (lard found).
      var efCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isHalal: true, isStale: true),
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
    });

    // Haram keyword in ingredients: keyword safety override still applies after EF.
    test(
      'stale + EF says halal but has pork → keyword override wins',
      () async {
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(isStale: true),
            // EF mistakenly says halal despite pork in ingredients list.
            efResponse: _efProduct(isHalal: true)
              ..['ingredients'] = ['pork', 'salt'],
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        // Client-side keyword safety override must flag pork as haram.
        expect(p!.isHalal, isFalse);
        expect(p.haramIngredients, isNotEmpty);
      },
    );

    test(
      'DB unknown + approved pack photos + fresh → returned without EF',
      () async {
        var efCalled = false;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _dbRow(
              isHalal: false,
              isUnknown: true,
              isStale: false,
              ingredients: const [],
            )..['image_ingredients_url'] = 'https://example.com/ing.jpg',
            efResponse: _efProduct(isHalal: true),
            onRequest: (req) {
              if (req.method == 'POST') efCalled = true;
            },
          ),
        );

        final p = await ProductService().getProduct(_kBarcode);

        expect(p, isNotNull);
        expect(p!.imageIngredientsUrl, 'https://example.com/ing.jpg');
        expect(efCalled, isFalse);
      },
    );

    // isUnknown=true without pack photos still re-tries via the Edge Function.
    test('DB has isUnknown=true + fresh → falls through (unchanged)', () async {
      var efCalled = false;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isHalal: false, isUnknown: true, isStale: false),
          efResponse: _efProduct(isHalal: true),
          onRequest: (req) {
            if (req.method == 'POST') efCalled = true;
          },
        ),
      );

      await ProductService().getProduct(_kBarcode);

      // isUnknown=true alone causes fall-through; EF must be called.
      expect(efCalled, isTrue);
    });

    // Both isUnknown=true and stale → still falls through to EF exactly once.
    test('DB has isUnknown=true + stale → EF called once', () async {
      var efCallCount = 0;
      ProductService().setHttpClientForTesting(
        _makeClient(
          dbRow: _dbRow(isHalal: false, isUnknown: true, isStale: true),
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
    });
  });
}
