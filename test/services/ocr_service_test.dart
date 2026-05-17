import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/ocr_service.dart';

void main() {
  // ML Kit (TextRecognizer) requires native platform support that is absent in
  // the desktop test environment. extractIngredientsFromFile is therefore not
  // directly testable here: TextRecognizer.close() in its finally block throws
  // MissingPluginException which escapes the catch and propagates to the caller.
  //
  // The URL-based methods are safe to test because the HTTP download step fails
  // first (network unavailable / platform exception), so extractIngredientsFromFile
  // is never reached and the null is returned from _downloadToTemp.

  group('OcrService.extractIngredientsFromImage', () {
    test('returns null when image URL is unreachable', () async {
      final result = await OcrService.extractIngredientsFromImage(
        'https://images.openfoodfacts.org/images/products/123/ingredients.jpg',
      );
      expect(result, isNull);
    });

    test('returns null for a malformed URL', () async {
      final result = await OcrService.extractIngredientsFromImage(
        'not-a-valid-url',
      );
      expect(result, isNull);
    });
  });

  group('OcrService.extractIngredientsFromImages', () {
    test('returns null for an empty URL list', () async {
      final result = await OcrService.extractIngredientsFromImages([]);
      expect(result, isNull);
    });

    test('returns null when no URL in the list yields text', () async {
      final result = await OcrService.extractIngredientsFromImages([
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
      ]);
      expect(result, isNull);
    });

    test('returns null for a single unreachable URL', () async {
      final result = await OcrService.extractIngredientsFromImages([
        'https://example.com/image.jpg',
      ]);
      expect(result, isNull);
    });
  });
}
