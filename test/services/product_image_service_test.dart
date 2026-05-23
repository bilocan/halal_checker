import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/product_image_service.dart';

void main() {
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
}
