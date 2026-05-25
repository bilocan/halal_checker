import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:halal_checker/models/ai_ingredient_request.dart';
import 'package:halal_checker/services/ai_ingredient_request_service.dart';
import 'package:halal_checker/services/auth_service.dart';

void main() {
  tearDown(AiIngredientRequestService.resetForTesting);

  group('AiIngredientRequestService — no Supabase config', () {
    test('getRequestForBarcode returns null', () async {
      expect(
        await AiIngredientRequestService.getRequestForBarcode('123'),
        isNull,
      );
    });

    test('submitRequest returns failed', () async {
      expect(
        await AiIngredientRequestService.submitRequest(
          '123',
          productName: 'Snack',
        ),
        AiIngredientSubmitResult.failed,
      );
    });

    test('getPendingRequests returns empty list', () async {
      expect(await AiIngredientRequestService.getPendingRequests(), isEmpty);
    });

    test('getApprovedRequests returns empty list', () async {
      expect(await AiIngredientRequestService.getApprovedRequests(), isEmpty);
    });

    test('updateStatus returns false', () async {
      expect(
        await AiIngredientRequestService.updateStatus(1, 'approved'),
        isFalse,
      );
    });
  });

  group('AiIngredientRequestService — fakes', () {
    test(
      'getRequestForBarcode returns null when auth is unavailable',
      () async {
        AiIngredientRequestService.enableForTesting();

        expect(
          await AiIngredientRequestService.getRequestForBarcode('123'),
          isNull,
        );
      },
    );

    test('getPendingRequests uses fake when set', () async {
      AiIngredientRequestService.fakeGetPendingRequests = () async => [
        {'id': 1, 'barcode': '123', 'status': 'pending'},
      ];

      final rows = await AiIngredientRequestService.getPendingRequests();

      expect(rows, hasLength(1));
      expect(rows.first['barcode'], '123');
    });

    test('getApprovedRequests uses fake when set', () async {
      AiIngredientRequestService.fakeGetApprovedRequests = () async => [
        {'id': 2, 'barcode': '456', 'status': 'approved'},
      ];

      final rows = await AiIngredientRequestService.getApprovedRequests();

      expect(rows, hasLength(1));
      expect(rows.first['status'], 'approved');
    });

    test('getRequestForBarcode uses fake when set', () async {
      AiIngredientRequestService.fakeGetRequestForBarcode = (barcode) async => {
        'id': 2,
        'barcode': barcode,
        'status': 'approved',
      };

      final row = await AiIngredientRequestService.getRequestForBarcode('456');

      expect(row?['barcode'], '456');
      expect(row?['status'], 'approved');
    });

    test('submitRequest uses fake when set', () async {
      String? capturedBarcode;
      String? capturedName;
      AiIngredientRequestService.fakeSubmitRequest =
          (barcode, {productName}) async {
            capturedBarcode = barcode;
            capturedName = productName;
            return AiIngredientSubmitResult.pending;
          };

      final result = await AiIngredientRequestService.submitRequest(
        '789',
        productName: 'Chips',
      );

      expect(result, AiIngredientSubmitResult.pending);
      expect(capturedBarcode, '789');
      expect(capturedName, 'Chips');
    });

    test('updateStatus uses fake when set', () async {
      int? capturedId;
      String? capturedStatus;
      AiIngredientRequestService.fakeUpdateStatus = (id, status) async {
        capturedId = id;
        capturedStatus = status;
        return true;
      };

      final ok = await AiIngredientRequestService.updateStatus(9, 'approved');

      expect(ok, isTrue);
      expect(capturedId, 9);
      expect(capturedStatus, 'approved');
    });
  });

  group('AiIngredientRequestService — submit and update logic', () {
    const fakeUser = User(
      id: 'test-uid',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2024-01-01T00:00:00',
      isAnonymous: false,
    );

    setUp(() {
      AiIngredientRequestService.enableForTesting();
      AiIngredientRequestService.fakeEnsureReady = () async => true;
      AiIngredientRequestService.fakeIsAdmin = () async => false;
      AuthService.setCurrentUserForTesting(fakeUser);
    });

    tearDown(AuthService.resetForTesting);

    test(
      'submitRequest returns alreadyPending when pending request exists',
      () async {
        AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => {
          'id': 1,
        };
        AiIngredientRequestService.fakeIsAdmin = () async => false;

        expect(
          await AiIngredientRequestService.submitRequest('123'),
          AiIngredientSubmitResult.alreadyPending,
        );
      },
    );

    test('admin submitRequest approves existing pending request', () async {
      AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => {
        'id': 7,
      };
      AiIngredientRequestService.fakeIsAdmin = () async => true;
      AiIngredientRequestService.fakePerformStatusUpdate =
          (id, status, userId) async {
            expect(id, 7);
            expect(status, 'approved');
            expect(userId, 'test-uid');
            return [
              {'id': 7},
            ];
          };

      expect(
        await AiIngredientRequestService.submitRequest('123'),
        AiIngredientSubmitResult.approved,
      );
    });

    test(
      'submitRequest inserts pending when no pending request exists',
      () async {
        String? capturedBarcode;
        String? capturedUserId;
        AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => null;
        AiIngredientRequestService.fakeIsAdmin = () async => false;
        AiIngredientRequestService.fakeInsertRequest =
            ({
              required String barcode,
              productName,
              required String userId,
            }) async {
              capturedBarcode = barcode;
              capturedUserId = userId;
            };

        expect(
          await AiIngredientRequestService.submitRequest(
            '456',
            productName: 'Chips',
          ),
          AiIngredientSubmitResult.pending,
        );
        expect(capturedBarcode, '456');
        expect(capturedUserId, 'test-uid');
      },
    );

    test(
      'admin submitRequest inserts as approved when no pending exists',
      () async {
        AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => null;
        AiIngredientRequestService.fakeIsAdmin = () async => true;
        AiIngredientRequestService.fakeInsertRequest =
            ({
              required String barcode,
              productName,
              required String userId,
            }) async {};

        expect(
          await AiIngredientRequestService.submitRequest('456'),
          AiIngredientSubmitResult.approved,
        );
      },
    );

    test(
      'admin submitRequest returns failed when approve update affects no rows',
      () async {
        AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => {
          'id': 8,
        };
        AiIngredientRequestService.fakeIsAdmin = () async => true;
        AiIngredientRequestService.fakePerformStatusUpdate =
            (_, _, _) async => [];

        expect(
          await AiIngredientRequestService.submitRequest('123'),
          AiIngredientSubmitResult.failed,
        );
      },
    );

    test('submitRequest returns failed when user is not signed in', () async {
      AuthService.resetForTesting();
      AiIngredientRequestService.enableForTesting();
      AiIngredientRequestService.fakeEnsureReady = () async => true;

      expect(
        await AiIngredientRequestService.submitRequest('123'),
        AiIngredientSubmitResult.failed,
      );
    });

    test('submitRequest returns failed on insert exception', () async {
      AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => null;
      AiIngredientRequestService.fakeIsAdmin = () async => false;
      AiIngredientRequestService.fakeInsertRequest =
          ({
            required String barcode,
            productName,
            required String userId,
          }) async {
            throw Exception('insert failed');
          };

      expect(
        await AiIngredientRequestService.submitRequest('123'),
        AiIngredientSubmitResult.failed,
      );
    });

    test('updateStatus returns true when rows are updated', () async {
      AiIngredientRequestService.fakePerformStatusUpdate =
          (id, status, userId) async {
            expect(id, 3);
            expect(status, 'approved');
            expect(userId, 'test-uid');
            return [
              {'id': 3},
            ];
          };

      expect(
        await AiIngredientRequestService.updateStatus(3, 'approved'),
        isTrue,
      );
    });

    test('updateStatus returns false when no rows are updated', () async {
      AiIngredientRequestService.fakePerformStatusUpdate = (_, _, _) async =>
          [];

      expect(
        await AiIngredientRequestService.updateStatus(3, 'approved'),
        isFalse,
      );
    });

    test('updateStatus returns false on exception', () async {
      AiIngredientRequestService.fakePerformStatusUpdate = (_, _, _) async =>
          throw Exception('update failed');

      expect(
        await AiIngredientRequestService.updateStatus(3, 'approved'),
        isFalse,
      );
    });

    test('getRequestForBarcode returns row from fetch fake', () async {
      AiIngredientRequestService.fakeFetchRequestForBarcode = (barcode) async =>
          {'id': 5, 'barcode': barcode, 'status': 'pending'};

      final row = await AiIngredientRequestService.getRequestForBarcode('777');

      expect(row?['id'], 5);
    });

    test('getRequestForBarcode returns null on fetch exception', () async {
      AiIngredientRequestService.fakeFetchRequestForBarcode = (_) async =>
          throw Exception('query failed');

      expect(
        await AiIngredientRequestService.getRequestForBarcode('777'),
        isNull,
      );
    });

    test('getPendingRequests returns rows from fetch fake', () async {
      AiIngredientRequestService.fakeFetchPendingRequests = () async => [
        {'id': 1, 'barcode': '111', 'status': 'pending'},
      ];

      final rows = await AiIngredientRequestService.getPendingRequests();

      expect(rows, hasLength(1));
    });

    test('getPendingRequests returns empty list on fetch exception', () async {
      AiIngredientRequestService.fakeFetchPendingRequests = () async =>
          throw Exception('query failed');

      expect(await AiIngredientRequestService.getPendingRequests(), isEmpty);
    });

    test('getApprovedRequests returns rows from fetch fake', () async {
      AiIngredientRequestService.fakeFetchApprovedRequests = () async => [
        {'id': 2, 'barcode': '222', 'status': 'approved'},
      ];

      final rows = await AiIngredientRequestService.getApprovedRequests();

      expect(rows, hasLength(1));
    });

    test('getApprovedRequests returns empty list on fetch exception', () async {
      AiIngredientRequestService.fakeFetchApprovedRequests = () async =>
          throw Exception('query failed');

      expect(await AiIngredientRequestService.getApprovedRequests(), isEmpty);
    });

    test(
      'submitRequest returns false when duplicate check hits missing table',
      () async {
        AiIngredientRequestService.fakeFindPendingByBarcode = (_) async {
          throw PostgrestException(message: 'missing', code: 'PGRST205');
        };

        expect(
          await AiIngredientRequestService.submitRequest('123'),
          AiIngredientSubmitResult.failed,
        );
      },
    );

    test(
      'logs migration hint for missing ai_ingredient_requests table',
      () async {
        AiIngredientRequestService.fakeFetchRequestForBarcode = (_) async {
          throw PostgrestException(message: 'missing', code: 'PGRST205');
        };

        expect(
          await AiIngredientRequestService.getRequestForBarcode('777'),
          isNull,
        );
      },
    );
  });
}
