import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/ai_ingredient_request.dart';

void main() {
  group('AiIngredientRequest.fromJson', () {
    test('parses int id and ISO created_at string', () {
      final item = AiIngredientRequest.fromJson({
        'id': 42,
        'barcode': '123',
        'product_name': 'Snack',
        'created_at': '2026-05-20T12:00:00.000Z',
      });
      expect(item.id, 42);
      expect(item.barcode, '123');
      expect(item.productName, 'Snack');
      expect(item.createdAt, isNotNull);
    });

    test('parses string id from PostgREST bigint', () {
      final item = AiIngredientRequest.fromJson({
        'id': '99',
        'barcode': '456',
        'created_at': '2026-05-20T12:00:00.000Z',
      });
      expect(item.id, 99);
      expect(item.productName, '456');
    });

    test('parses DateTime created_at', () {
      final when = DateTime.utc(2026, 5, 20, 12);
      final item = AiIngredientRequest.fromJson({
        'id': 1,
        'barcode': '789',
        'created_at': when,
      });
      expect(item.createdAt, when.toLocal());
    });
  });
}
