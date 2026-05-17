import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:halal_checker/services/ingredient_contribution_service.dart';

void main() {
  tearDown(IngredientContributionService.resetForTesting);

  // ── no Supabase config (guard-path) ───────────────────────────────────────

  group('IngredientContributionService — no Supabase config', () {
    test('submitIngredients returns false', () async {
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water, sugar, salt',
        ),
        isFalse,
      );
    });

    test('getContributions returns empty list', () async {
      expect(await IngredientContributionService.getContributions(), isEmpty);
    });

    test('getContributions with explicit status returns empty list', () async {
      expect(
        await IngredientContributionService.getContributions(
          status: 'approved',
        ),
        isEmpty,
      );
    });

    test('updateStatus returns false', () async {
      expect(
        await IngredientContributionService.updateStatus(1, 'approved'),
        isFalse,
      );
    });
  });

  // ── submitIngredients ─────────────────────────────────────────────────────

  group('IngredientContributionService.submitIngredients — HTTP responses', () {
    test('HTTP 201 → true', () async {
      IngredientContributionService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 201)),
      );
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water, sugar, salt',
        ),
        isTrue,
      );
    });

    test('HTTP 200 (not 201) → false', () async {
      IngredientContributionService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 200)),
      );
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water, sugar',
        ),
        isFalse,
      );
    });

    test('HTTP 400 → false', () async {
      IngredientContributionService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 400)),
      );
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water',
        ),
        isFalse,
      );
    });

    test('network exception → false', () async {
      IngredientContributionService.setHttpClientForTesting(
        MockClient((_) async => throw Exception('network error')),
      );
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water',
        ),
        isFalse,
      );
    });

    test('request body contains barcode and ingredient_text', () async {
      late http.Request captured;
      IngredientContributionService.setHttpClientForTesting(
        MockClient((req) async {
          captured = req;
          return http.Response('', 201);
        }),
      );
      await IngredientContributionService.submitIngredients(
        barcode: '9876543210',
        ingredientText: 'sugar, water, salt',
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['barcode'], '9876543210');
      expect(body['ingredient_text'], 'sugar, water, salt');
    });

    test('request headers include apikey and content-type', () async {
      late http.Request captured;
      IngredientContributionService.setHttpClientForTesting(
        MockClient((req) async {
          captured = req;
          return http.Response('', 201);
        }),
      );
      await IngredientContributionService.submitIngredients(
        barcode: '111222333',
        ingredientText: 'water',
      );
      expect(captured.headers['Content-Type'], contains('application/json'));
      expect(captured.headers.containsKey('apikey'), isTrue);
      expect(captured.headers.containsKey('Authorization'), isTrue);
      expect(captured.headers['Prefer'], 'return=minimal');
    });

    test('request body omits submitted_by when no user logged in', () async {
      late http.Request captured;
      IngredientContributionService.setHttpClientForTesting(
        MockClient((req) async {
          captured = req;
          return http.Response('', 201);
        }),
      );
      await IngredientContributionService.submitIngredients(
        barcode: '111222333',
        ingredientText: 'water',
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body.containsKey('submitted_by'), isFalse);
    });
  });

  // ── getContributions ──────────────────────────────────────────────────────

  group('IngredientContributionService.getContributions', () {
    setUp(IngredientContributionService.enableForTesting);

    test('returns rows as list of maps', () async {
      IngredientContributionService.fakeFetchContributions = (_) async => [
        {
          'id': 1,
          'barcode': '111',
          'ingredient_text': 'water',
          'status': 'pending',
        },
        {
          'id': 2,
          'barcode': '222',
          'ingredient_text': 'salt',
          'status': 'pending',
        },
      ];
      final result = await IngredientContributionService.getContributions();
      expect(result, hasLength(2));
      expect(result[0]['id'], 1);
      expect(result[1]['barcode'], '222');
    });

    test('passes status to query', () async {
      String? capturedStatus;
      IngredientContributionService.fakeFetchContributions = (s) async {
        capturedStatus = s;
        return [];
      };
      await IngredientContributionService.getContributions(status: 'approved');
      expect(capturedStatus, 'approved');
    });

    test('default status is pending', () async {
      String? capturedStatus;
      IngredientContributionService.fakeFetchContributions = (s) async {
        capturedStatus = s;
        return [];
      };
      await IngredientContributionService.getContributions();
      expect(capturedStatus, 'pending');
    });

    test('returns empty list when no rows', () async {
      IngredientContributionService.fakeFetchContributions = (_) async => [];
      expect(await IngredientContributionService.getContributions(), isEmpty);
    });

    test('returns empty list on exception', () async {
      IngredientContributionService.fakeFetchContributions = (_) async =>
          throw Exception('DB error');
      expect(await IngredientContributionService.getContributions(), isEmpty);
    });
  });

  // ── updateStatus ──────────────────────────────────────────────────────────

  group('IngredientContributionService.updateStatus', () {
    setUp(IngredientContributionService.enableForTesting);

    test(
      'rejected path: returns true and updates contribution status',
      () async {
        int? updatedId;
        String? updatedStatus;
        IngredientContributionService.fakeGetContribution = (_) async => {
          'barcode': '111222333',
          'ingredient_text': 'water, salt',
        };
        IngredientContributionService.fakeUpdateContributionStatus =
            (id, s) async {
              updatedId = id;
              updatedStatus = s;
            };
        final result = await IngredientContributionService.updateStatus(
          42,
          'rejected',
        );
        expect(result, isTrue);
        expect(updatedId, 42);
        expect(updatedStatus, 'rejected');
      },
    );

    test('rejected path: does not update product', () async {
      var productUpdateCalled = false;
      IngredientContributionService.fakeGetContribution = (_) async => {
        'barcode': '111',
        'ingredient_text': 'water',
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async {};
      IngredientContributionService.fakeUpdateProduct = (_, _) async =>
          productUpdateCalled = true;
      await IngredientContributionService.updateStatus(1, 'rejected');
      expect(productUpdateCalled, isFalse);
    });

    test(
      'approved path: updates contribution status with correct args',
      () async {
        int? updatedId;
        String? updatedStatus;
        IngredientContributionService.fakeGetContribution = (_) async => {
          'barcode': '111',
          'ingredient_text': 'water, salt',
        };
        IngredientContributionService.fakeUpdateContributionStatus =
            (id, s) async {
              updatedId = id;
              updatedStatus = s;
            };
        IngredientContributionService.fakeUpdateProduct = (_, _) async {};
        await IngredientContributionService.updateStatus(7, 'approved');
        expect(updatedId, 7);
        expect(updatedStatus, 'approved');
      },
    );

    test('approved path: updates product with correct barcode', () async {
      String? capturedBarcode;
      IngredientContributionService.fakeGetContribution = (_) async => {
        'barcode': '9876543210',
        'ingredient_text': 'water, salt',
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async {};
      IngredientContributionService.fakeUpdateProduct = (b, _) async =>
          capturedBarcode = b;
      await IngredientContributionService.updateStatus(1, 'approved');
      expect(capturedBarcode, '9876543210');
    });

    test('approved path: product data contains required keys', () async {
      Map<String, dynamic>? capturedData;
      IngredientContributionService.fakeGetContribution = (_) async => {
        'barcode': '111',
        'ingredient_text': 'water, salt',
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async {};
      IngredientContributionService.fakeUpdateProduct = (_, d) async =>
          capturedData = d;
      await IngredientContributionService.updateStatus(1, 'approved');
      expect(capturedData, isNotNull);
      expect(capturedData!.containsKey('is_halal'), isTrue);
      expect(capturedData!.containsKey('ingredients'), isTrue);
      expect(capturedData!.containsKey('is_managed'), isTrue);
      expect(capturedData!.containsKey('is_unknown'), isTrue);
      expect(capturedData!.containsKey('analyzed_by_ai'), isTrue);
      expect(capturedData!['is_managed'], isTrue);
      expect(capturedData!['analyzed_by_ai'], isFalse);
      expect(capturedData!['is_unknown'], isFalse);
    });

    test('approved path: halal ingredients → is_halal true', () async {
      Map<String, dynamic>? capturedData;
      IngredientContributionService.fakeGetContribution = (_) async => {
        'barcode': '111',
        'ingredient_text': 'water, salt, sugar',
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async {};
      IngredientContributionService.fakeUpdateProduct = (_, d) async =>
          capturedData = d;
      await IngredientContributionService.updateStatus(1, 'approved');
      expect(capturedData!['is_halal'], isTrue);
    });

    test('approved path: haram ingredient → is_halal false', () async {
      Map<String, dynamic>? capturedData;
      IngredientContributionService.fakeGetContribution = (_) async => {
        'barcode': '111',
        'ingredient_text': 'pork, water',
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async {};
      IngredientContributionService.fakeUpdateProduct = (_, d) async =>
          capturedData = d;
      await IngredientContributionService.updateStatus(1, 'approved');
      expect(capturedData!['is_halal'], isFalse);
    });

    test('approved path: null barcode → no product update', () async {
      var productUpdateCalled = false;
      IngredientContributionService.fakeGetContribution = (_) async => {
        'barcode': null,
        'ingredient_text': 'water',
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async {};
      IngredientContributionService.fakeUpdateProduct = (_, _) async =>
          productUpdateCalled = true;
      final result = await IngredientContributionService.updateStatus(
        1,
        'approved',
      );
      expect(result, isTrue);
      expect(productUpdateCalled, isFalse);
    });

    test('approved path: null ingredient_text → no product update', () async {
      var productUpdateCalled = false;
      IngredientContributionService.fakeGetContribution = (_) async => {
        'barcode': '111',
        'ingredient_text': null,
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async {};
      IngredientContributionService.fakeUpdateProduct = (_, _) async =>
          productUpdateCalled = true;
      final result = await IngredientContributionService.updateStatus(
        1,
        'approved',
      );
      expect(result, isTrue);
      expect(productUpdateCalled, isFalse);
    });

    test('approved path: empty ingredient text → no product update', () async {
      var productUpdateCalled = false;
      IngredientContributionService.fakeGetContribution = (_) async => {
        'barcode': '111',
        'ingredient_text': '',
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async {};
      IngredientContributionService.fakeUpdateProduct = (_, _) async =>
          productUpdateCalled = true;
      final result = await IngredientContributionService.updateStatus(
        1,
        'approved',
      );
      expect(result, isTrue);
      expect(productUpdateCalled, isFalse);
    });

    test('passes id to fakeGetContribution', () async {
      int? capturedId;
      IngredientContributionService.fakeGetContribution = (id) async {
        capturedId = id;
        return {'barcode': '111', 'ingredient_text': 'water'};
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async {};
      await IngredientContributionService.updateStatus(99, 'rejected');
      expect(capturedId, 99);
    });

    test('returns false on exception', () async {
      IngredientContributionService.fakeGetContribution = (_) async =>
          throw Exception('DB error');
      expect(
        await IngredientContributionService.updateStatus(1, 'approved'),
        isFalse,
      );
    });

    test('returns false when status update throws', () async {
      IngredientContributionService.fakeGetContribution = (_) async => {
        'barcode': '111',
        'ingredient_text': 'water',
      };
      IngredientContributionService.fakeUpdateContributionStatus =
          (_, _) async => throw Exception('write error');
      expect(
        await IngredientContributionService.updateStatus(1, 'rejected'),
        isFalse,
      );
    });
  });
}
