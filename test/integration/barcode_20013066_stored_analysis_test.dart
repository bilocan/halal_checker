// Integration test: barcode 20013066 — stale shared-DB row with Cyrillic label
// ingredients, then fresh analysis (mock Edge Function) must keyword-match via OFF
// English fallback, not the bogus "product name contains a haram indicator" path.
//
// Run (mocked HTTP — no live Supabase required):
//   flutter test test/integration/barcode_20013066_stored_analysis_test.dart
//
// Included in run_all_integration_tests when defines file exists.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:halal_checker/services/product_service.dart';
import 'package:halal_checker/services/test_product_repository.dart';

const _kBarcode = '20013066';
const _kSupabaseUrl = 'https://test.supabase.co';
const _kAnonKey = 'test_anon_key';
const _kAnalysed = '2026-01-01T01:00:00.000Z';
const _kUpdated = '2026-01-01T02:00:00.000Z';

/// Bulgarian label lines as stored in products.ingredients (display language).
const _kLabelIngredients = [
  '80% частично финомляно свинско месо',
  'вода',
  'сол',
];

const _kProductName = 'Свински кюфтета';

Map<String, dynamic> _staleDbRow20013066() => {
  'barcode': _kBarcode,
  'name': _kProductName,
  'ingredients': _kLabelIngredients,
  'is_halal': false,
  'is_unknown': true,
  'is_non_food': false,
  'haram_ingredients': <dynamic>[],
  'suspicious_ingredients': <dynamic>[],
  'ingredient_warnings': <String, dynamic>{},
  'labels': <dynamic>[],
  'image_url': null,
  'image_front_url': null,
  'image_ingredients_url': null,
  'image_nutrition_url': null,
  'explanation':
      'No ingredient list found, but the product name contains a haram indicator: .',
  'analyzed_by_ai': false,
  'requires_halal_cert': false,
  'is_managed': false,
  'fetched_at': _kAnalysed,
  'last_analysed_at': _kAnalysed,
  'updated_at': _kUpdated,
  'keyword_match_source': 'unanalyzable',
  'display_lang': 'bg',
};

/// Edge Function body after rules engine + OFF en fallback on stored label data.
Map<String, dynamic> _efResolved20013066() => {
  'barcode': _kBarcode,
  'name': _kProductName,
  'ingredients': _kLabelIngredients,
  'isHalal': false,
  'isUnknown': false,
  'isNonFood': false,
  'haramIngredients': ['80% pork meat is partially minced'],
  'suspiciousIngredients': <dynamic>[],
  'ingredientWarnings': {
    '80% pork meat is partially minced':
        'Contains pork or pork-derived ingredient',
  },
  'labels': <dynamic>[],
  'imageUrl': null,
  'imageFrontUrl': null,
  'imageIngredientsUrl': null,
  'imageNutritionUrl': null,
  'explanation':
      'This product contains ingredient(s) that are not permissible: '
      '80% pork meat is partially minced. Assessed by keyword matching.',
  'analyzedByAI': false,
  'analysisMethod': 'keyword',
  'requiresHalalCert': false,
  'isManaged': false,
  'keywordMatchSource': 'off_en',
  'keywordMatchOrigins': {'80% pork meat is partially minced': 'off_en'},
  'analyzeLang': 'en',
  'displayLang': 'bg',
  'lastAnalysedAt': _kAnalysed,
  'updatedAt': _kUpdated,
};

MockClient _makeClient({
  required Map<String, dynamic> dbRow,
  required Map<String, dynamic> efResponse,
  void Function(http.Request)? onRequest,
}) => MockClient((req) async {
  onRequest?.call(req);
  if (req.url.host.contains('supabase.co')) {
    if (req.method == 'GET') {
      return http.Response.bytes(
        utf8.encode(jsonEncode([dbRow])),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (req.method == 'POST') {
      return http.Response.bytes(
        utf8.encode(jsonEncode({'product': efResponse})),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    return http.Response('', 500);
  }
  return http.Response(jsonEncode({'status': 0}), 200);
});

void main() {
  group('Barcode 20013066 — stored label ingredients', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      TestProductRepository.dbPathOverride = inMemoryDatabasePath;
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      ProductService().enableSupabaseForTesting(
        url: _kSupabaseUrl,
        key: _kAnonKey,
      );
    });

    tearDown(() {
      ProductService()
        ..setHttpClientForTesting(http.Client())
        ..resetForTesting();
    });

    test(
      'stale DB Cyrillic label → re-analysis explains label keyword match',
      () async {
        var efCalled = false;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: _staleDbRow20013066(),
            efResponse: _efResolved20013066(),
            onRequest: (req) {
              if (req.method == 'POST' &&
                  req.url.host.contains('supabase.co')) {
                efCalled = true;
              }
            },
          ),
        );

        final product = await ProductService().getProduct(_kBarcode);

        expect(efCalled, isTrue);
        expect(product, isNotNull);
        expect(product!.ingredients, _kLabelIngredients);
        expect(product.isHalal, isFalse);
        expect(product.isUnknown, isFalse);
        expect(product.haramIngredients, isNotEmpty);
        expect(product.keywordMatchSource, 'off_en');
        expect(
          product.explanation.toLowerCase(),
          contains('keyword matching'),
          reason: 'label keyword match explanation',
        );
        expect(product.explanation.toLowerCase(), contains('pork'));
        expect(
          product.explanation,
          isNot(contains('product name contains a haram indicator')),
        );
        expect(
          product.explanation,
          isNot(contains('language we cannot analyze')),
        );
      },
    );

    test(
      'managed DB Cyrillic label → refresh reanalyzes with primary keyword match',
      () async {
        var efCalled = false;
        ProductService().setHttpClientForTesting(
          _makeClient(
            dbRow: {
              ..._staleDbRow20013066(),
              'is_managed': true,
              'is_unknown': true,
              'explanation':
                  'Ingredients are in a language we cannot analyze. Halal status cannot be determined — check the packaging directly.',
            },
            efResponse: _efResolved20013066(),
            onRequest: (req) {
              if (req.method == 'POST' &&
                  req.url.host.contains('supabase.co')) {
                efCalled = true;
              }
            },
          ),
        );

        final product = await ProductService().refreshProduct(_kBarcode);

        expect(efCalled, isFalse);
        expect(product, isNotNull);
        expect(product!.ingredients, _kLabelIngredients);
        expect(product.isHalal, isFalse);
        expect(product.isUnknown, isFalse);
        expect(product.keywordMatchSource, 'primary');
        expect(product.explanation.toLowerCase(), contains('keyword matching'));
        expect(
          product.haramIngredients.any((h) => h.contains('свинско')),
          isTrue,
        );
        expect(
          product.explanation,
          isNot(contains('language we cannot analyze')),
        );
      },
    );
  });
}
