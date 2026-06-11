import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/photo_submission.dart';
import 'package:halal_checker/models/review_status.dart';

void main() {
  group('PhotoSubmission', () {
    test('fromJson parses status', () {
      final item = PhotoSubmission.fromJson({
        'id': 1,
        'barcode': '1234567890123',
        'product_name': 'Snack',
        'image_type': 'front',
        'public_url': 'https://example.com/a.jpg',
        'status': 'approved',
        'created_at': '2026-06-11T10:00:00Z',
      });

      expect(item.status, ReviewStatus.approved);
      expect(item.productName, 'Snack');
    });

    test('fromJson defaults missing status to pending', () {
      final item = PhotoSubmission.fromJson({
        'id': 2,
        'barcode': '1234567890123',
        'image_type': 'ingredients',
        'public_url': 'https://example.com/b.jpg',
      });

      expect(item.status, ReviewStatus.pending);
    });
  });
}
