import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:halal_checker/services/ocr_service.dart';

void main() {
  // ML Kit (TextRecognizer) requires native platform support absent in the
  // desktop test environment. extractIngredientsFromFile is not directly
  // testable: TextRecognizer.close() throws MissingPluginException which
  // escapes the catch block and propagates to the caller.
  //
  // For URL-based methods, the HTTP download step can be mocked. A non-200
  // response returns null from _downloadToTemp before ML Kit is ever called.
  // A 200 response downloads the file but then ML Kit fails with
  // MissingPluginException, so the result is still null on desktop — but the
  // download path is exercised.

  group('OcrService.extractIngredientsFromImage — no mock (real network)', () {
    test('returns null for a malformed URL', () async {
      expect(
        await OcrService.extractIngredientsFromImage('not-a-valid-url'),
        isNull,
      );
    });
  });

  group('OcrService.extractIngredientsFromImage — HTTP mock', () {
    tearDown(OcrService.resetForTesting);

    test('HTTP 404 → null (download fails, ML Kit never called)', () async {
      OcrService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 404)),
      );
      expect(
        await OcrService.extractIngredientsFromImage(
          'https://example.com/image.jpg',
        ),
        isNull,
      );
    });

    test('HTTP 500 → null', () async {
      OcrService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 500)),
      );
      expect(
        await OcrService.extractIngredientsFromImage(
          'https://example.com/image.jpg',
        ),
        isNull,
      );
    });

    test('network exception → null', () async {
      OcrService.setHttpClientForTesting(
        MockClient((_) async => throw Exception('network error')),
      );
      expect(
        await OcrService.extractIngredientsFromImage(
          'https://example.com/image.jpg',
        ),
        isNull,
      );
    });

    test('HTTP 200 → downloads file but ML Kit unavailable → null', () async {
      OcrService.setHttpClientForTesting(
        MockClient(
          (_) async => http.Response(
            'fake image bytes',
            200,
            headers: {'content-type': 'image/jpeg'},
          ),
        ),
      );
      // MissingPluginException from ML Kit is caught and returns null.
      expect(
        await OcrService.extractIngredientsFromImage(
          'https://example.com/image.jpg',
        ),
        isNull,
      );
    });
  });

  group('OcrService.extractIngredientsFromImages — HTTP mock', () {
    tearDown(OcrService.resetForTesting);

    test('empty list → null (no requests made)', () async {
      expect(await OcrService.extractIngredientsFromImages([]), isNull);
    });

    test('all URLs return 404 → null', () async {
      OcrService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 404)),
      );
      expect(
        await OcrService.extractIngredientsFromImages([
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ]),
        isNull,
      );
    });

    test('all URLs throw → null', () async {
      OcrService.setHttpClientForTesting(
        MockClient((_) async => throw Exception('offline')),
      );
      expect(
        await OcrService.extractIngredientsFromImages([
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ]),
        isNull,
      );
    });
  });
}
