import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/ocr_service.dart';

void main() {
  // AppConfig.hasSupabase is false in tests (no --dart-define flags), so
  // all methods return null immediately without network calls.

  group('OcrService — no Supabase config', () {
    test('extractIngredientsFromImage returns null', () async {
      final result = await OcrService.extractIngredientsFromImage(
        'https://images.openfoodfacts.org/images/products/123/ingredients.jpg',
      );
      expect(result, isNull);
    });

    test('extractIngredientsFromImages with empty list returns null', () async {
      final result = await OcrService.extractIngredientsFromImages([]);
      expect(result, isNull);
    });

    test('extractIngredientsFromImages with single URL returns null', () async {
      final result = await OcrService.extractIngredientsFromImages([
        'https://example.com/image.jpg',
      ]);
      expect(result, isNull);
    });

    test(
      'extractIngredientsFromImages with multiple URLs returns null',
      () async {
        final result = await OcrService.extractIngredientsFromImages([
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ]);
        expect(result, isNull);
      },
    );
  });
}
