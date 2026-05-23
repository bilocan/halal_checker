import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/ai_ingredient_request_service.dart';

void main() {
  tearDown(AiIngredientRequestService.resetForTesting);

  group('AiIngredientRequestService — no Supabase config', () {
    test('getRequestForBarcode returns null', () async {
      expect(
        await AiIngredientRequestService.getRequestForBarcode('123'),
        isNull,
      );
    });

    test('submitRequest returns false', () async {
      expect(
        await AiIngredientRequestService.submitRequest(
          '123',
          productName: 'Snack',
        ),
        isFalse,
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
    test('getPendingRequests uses fake when set', () async {
      AiIngredientRequestService.fakeGetPendingRequests = () async => [
        {'id': 1, 'barcode': '123', 'status': 'pending'},
      ];

      final rows = await AiIngredientRequestService.getPendingRequests();

      expect(rows, hasLength(1));
      expect(rows.first['barcode'], '123');
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
  });
}
