import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/product_image_service.dart';

void main() {
  tearDown(ProductImageService.resetForTesting);

  group('ProductImageService — no Supabase config', () {
    test('uploadImage returns false', () async {
      expect(
        await ProductImageService.uploadImage(
          barcode: '1234567890123',
          imageFile: File.fromUri(Uri.parse('file:///tmp/test.jpg')),
        ),
        isFalse,
      );
    });

    test('getSubmissions returns empty list', () async {
      expect(await ProductImageService.getSubmissions(), isEmpty);
    });

    test('updateSubmissionStatus returns false', () async {
      expect(
        await ProductImageService.updateSubmissionStatus(1, 'approved'),
        isFalse,
      );
    });
  });

  group('ProductImageService — fakes', () {
    test('getSubmissions uses fake when set', () async {
      ProductImageService.fakeGetSubmissions = (status) async => [
        {'id': 1, 'barcode': '123', 'status': status},
      ];

      final rows = await ProductImageService.getSubmissions(status: 'pending');

      expect(rows, hasLength(1));
      expect(rows.first['barcode'], '123');
    });

    test('updateSubmissionStatus uses fake when set', () async {
      ProductImageService.fakeUpdateSubmissionStatus = (id, status) async {
        expect(id, 42);
        expect(status, 'approved');
        return true;
      };

      expect(
        await ProductImageService.updateSubmissionStatus(42, 'approved'),
        isTrue,
      );
    });
  });
}
