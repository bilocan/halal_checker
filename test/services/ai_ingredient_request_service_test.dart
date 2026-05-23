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
}
