import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:halal_checker/services/auth_service.dart';
import 'package:halal_checker/services/ingredient_report_service.dart';

void main() {
  tearDown(IngredientReportService.resetForTesting);

  group('IngredientReportService — no Supabase config', () {
    test('submitReport returns false', () async {
      expect(
        await IngredientReportService.submitReport(
          barcode: '111222333',
          productName: 'Snack',
          ingredients: ['water', 'salt'],
        ),
        isFalse,
      );
    });

    test('getReports returns empty list', () async {
      expect(await IngredientReportService.getReports(), isEmpty);
    });

    test('updateStatus returns false', () async {
      expect(
        await IngredientReportService.updateStatus(1, 'approved'),
        isFalse,
      );
    });
  });

  group('IngredientReportService — enableForTesting without auth', () {
    setUp(IngredientReportService.enableForTesting);

    test('submitReport returns false when auth is unavailable', () async {
      expect(
        await IngredientReportService.submitReport(
          barcode: '111222333',
          productName: 'Snack',
          ingredients: ['water'],
        ),
        isFalse,
      );
    });

    test('getReports returns empty list when auth is unavailable', () async {
      expect(await IngredientReportService.getReports(), isEmpty);
    });

    test('updateStatus returns false when auth is unavailable', () async {
      expect(
        await IngredientReportService.updateStatus(1, 'approved'),
        isFalse,
      );
    });
  });

  group('IngredientReportService — fakes', () {
    setUp(IngredientReportService.enableForTesting);

    const fakeUser = User(
      id: 'test-uid',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2024-01-01T00:00:00',
      isAnonymous: false,
    );

    tearDown(AuthService.resetForTesting);

    test('submitReport uses fake and passes payload fields', () async {
      AuthService.setCurrentUserForTesting(fakeUser);
      String? capturedBarcode;
      String? capturedName;
      List<String>? capturedIngredients;
      String? capturedExplanation;

      IngredientReportService.fakeSubmitReport =
          ({
            required String barcode,
            required String productName,
            required List<String> ingredients,
            String? explanation,
          }) async {
            capturedBarcode = barcode;
            capturedName = productName;
            capturedIngredients = ingredients;
            capturedExplanation = explanation;
            return true;
          };

      final ok = await IngredientReportService.submitReport(
        barcode: '9876543210',
        productName: 'Cola',
        ingredients: ['water', 'sugar'],
        explanation: 'Missing alcohol',
      );

      expect(ok, isTrue);
      expect(capturedBarcode, '9876543210');
      expect(capturedName, 'Cola');
      expect(capturedIngredients, ['water', 'sugar']);
      expect(capturedExplanation, 'Missing alcohol');
    });

    test('getReports passes status to fake', () async {
      String? capturedStatus;
      IngredientReportService.fakeGetReports = (status) async {
        capturedStatus = status;
        return [
          {'id': 1, 'barcode': '111', 'status': status},
        ];
      };

      final rows = await IngredientReportService.getReports(status: 'approved');

      expect(capturedStatus, 'approved');
      expect(rows, hasLength(1));
      expect(rows.first['barcode'], '111');
    });

    test('getReports default status is pending', () async {
      String? capturedStatus;
      IngredientReportService.fakeGetReports = (status) async {
        capturedStatus = status;
        return [];
      };

      await IngredientReportService.getReports();

      expect(capturedStatus, 'pending');
    });

    test('updateStatus uses fake with id and status', () async {
      int? capturedId;
      String? capturedStatus;
      IngredientReportService.fakeUpdateStatus = (id, status) async {
        capturedId = id;
        capturedStatus = status;
        return true;
      };

      final ok = await IngredientReportService.updateStatus(42, 'rejected');

      expect(ok, isTrue);
      expect(capturedId, 42);
      expect(capturedStatus, 'rejected');
    });

    test('submitReport inserts via fakeInsertReport with user id', () async {
      AuthService.setCurrentUserForTesting(fakeUser);
      IngredientReportService.fakeEnsureReady = () async => true;
      String? capturedUserId;
      IngredientReportService.fakeInsertReport =
          ({
            required String barcode,
            required String productName,
            required List<String> ingredients,
            String? explanation,
            String? userId,
          }) async {
            capturedUserId = userId;
            expect(barcode, '111');
            expect(explanation, isNull);
          };

      final ok = await IngredientReportService.submitReport(
        barcode: '111',
        productName: 'Snack',
        ingredients: ['water'],
      );

      expect(ok, isTrue);
      expect(capturedUserId, 'test-uid');
    });

    test('submitReport omits empty explanation in insert fake', () async {
      IngredientReportService.fakeEnsureReady = () async => true;
      String? capturedExplanation;
      IngredientReportService.fakeInsertReport =
          ({
            required String barcode,
            required String productName,
            required List<String> ingredients,
            String? explanation,
            String? userId,
          }) async {
            capturedExplanation = explanation;
          };

      await IngredientReportService.submitReport(
        barcode: '111',
        productName: 'Snack',
        ingredients: ['water'],
        explanation: '',
      );

      expect(capturedExplanation, '');
    });

    test('submitReport passes explanation to insert fake', () async {
      IngredientReportService.fakeEnsureReady = () async => true;
      String? capturedExplanation;
      IngredientReportService.fakeInsertReport =
          ({
            required String barcode,
            required String productName,
            required List<String> ingredients,
            String? explanation,
            String? userId,
          }) async {
            capturedExplanation = explanation;
          };

      await IngredientReportService.submitReport(
        barcode: '111',
        productName: 'Snack',
        ingredients: ['water'],
        explanation: 'Wrong list on packaging',
      );

      expect(capturedExplanation, 'Wrong list on packaging');
    });

    test('submitReport returns false when insert throws', () async {
      IngredientReportService.fakeEnsureReady = () async => true;
      IngredientReportService.fakeInsertReport =
          ({
            required String barcode,
            required String productName,
            required List<String> ingredients,
            String? explanation,
            String? userId,
          }) async {
            throw Exception('db error');
          };

      expect(
        await IngredientReportService.submitReport(
          barcode: '111',
          productName: 'Snack',
          ingredients: ['water'],
        ),
        isFalse,
      );
    });

    test('getReports returns rows from fetch fake', () async {
      IngredientReportService.fakeEnsureReady = () async => true;
      IngredientReportService.fakeFetchReports = (status) async => [
        {'id': 1, 'barcode': '111', 'status': status},
      ];

      final rows = await IngredientReportService.getReports(status: 'rejected');

      expect(rows, hasLength(1));
      expect(rows.first['status'], 'rejected');
    });

    test('updateStatus returns true via perform fake', () async {
      IngredientReportService.fakeEnsureReady = () async => true;
      IngredientReportService.fakePerformStatusUpdate = (id, status) async {
        expect(id, 9);
        expect(status, 'approved');
      };

      expect(await IngredientReportService.updateStatus(9, 'approved'), isTrue);
    });

    test('getReports returns empty list when query throws', () async {
      IngredientReportService.fakeEnsureReady = () async => true;
      IngredientReportService.fakeFetchReports = (_) async =>
          throw Exception('db error');

      expect(await IngredientReportService.getReports(), isEmpty);
    });

    test('updateStatus returns false when update throws', () async {
      IngredientReportService.fakeEnsureReady = () async => true;
      IngredientReportService.fakePerformStatusUpdate = (_, _) async =>
          throw Exception('db error');

      expect(
        await IngredientReportService.updateStatus(1, 'approved'),
        isFalse,
      );
    });
  });
}
