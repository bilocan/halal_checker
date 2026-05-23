import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:halal_checker/services/auth_service.dart';
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

    test('uploadImage uses fake when set', () async {
      ProductImageService.fakeUploadImage =
          ({
            required String barcode,
            required File imageFile,
            ProductImageType type = ProductImageType.front,
            String? productName,
          }) async {
            expect(barcode, '1234567890123');
            expect(type, ProductImageType.ingredients);
            expect(productName, 'Snack');
            return true;
          };

      expect(
        await ProductImageService.uploadImage(
          barcode: '1234567890123',
          imageFile: File.fromUri(Uri.parse('file:///tmp/test.jpg')),
          type: ProductImageType.ingredients,
          productName: 'Snack',
        ),
        isTrue,
      );
    });
  });

  group('ProductImageService — submission enrichment', () {
    setUp(ProductImageService.enableForTesting);

    test('maps current_image_url from product rows by image type', () async {
      ProductImageService.fakeFetchSubmissionsForStatus = (_) async => [
        {'id': 1, 'barcode': '111', 'image_type': 'front'},
        {'id': 2, 'barcode': '222', 'image_type': 'ingredients'},
        {'id': 3, 'barcode': '333', 'image_type': 'nutrition'},
        {'id': 4, 'barcode': '444', 'image_type': 'unknown'},
      ];
      ProductImageService.fakeFetchProductsForBarcodes = (_) async => [
        {
          'barcode': '111',
          'image_front_url': 'https://example.com/front.jpg',
          'image_ingredients_url': 'https://example.com/ing.jpg',
          'image_nutrition_url': 'https://example.com/nut.jpg',
        },
        {
          'barcode': '222',
          'image_front_url': 'https://example.com/front2.jpg',
          'image_ingredients_url': 'https://example.com/ing2.jpg',
          'image_nutrition_url': 'https://example.com/nut2.jpg',
        },
        {
          'barcode': '333',
          'image_front_url': 'https://example.com/front3.jpg',
          'image_ingredients_url': 'https://example.com/ing3.jpg',
          'image_nutrition_url': 'https://example.com/nut3.jpg',
        },
      ];

      final rows = await ProductImageService.getSubmissions();

      expect(rows[0]['current_image_url'], 'https://example.com/front.jpg');
      expect(rows[1]['current_image_url'], 'https://example.com/ing2.jpg');
      expect(rows[2]['current_image_url'], 'https://example.com/nut3.jpg');
      expect(rows[3]['current_image_url'], isNull);
    });

    test('returns empty list when fake submissions are empty', () async {
      ProductImageService.fakeFetchSubmissionsForStatus = (_) async => [];

      expect(await ProductImageService.getSubmissions(), isEmpty);
    });

    test('returns empty list when enrichment query throws', () async {
      ProductImageService.fakeFetchSubmissionsForStatus = (_) async => [
        {'id': 1, 'barcode': '111', 'image_type': 'front'},
      ];
      ProductImageService.fakeFetchProductsForBarcodes = (_) async =>
          throw Exception('db error');

      expect(await ProductImageService.getSubmissions(), isEmpty);
    });
  });

  group('ProductImageService — upload guards', () {
    const fakeUser = User(
      id: 'test-uid',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2024-01-01T00:00:00',
      isAnonymous: false,
    );

    setUp(ProductImageService.enableForTesting);

    tearDown(AuthService.resetForTesting);

    test('uploadImage returns false when user is not signed in', () async {
      expect(
        await ProductImageService.uploadImage(
          barcode: '1234567890123',
          imageFile: File.fromUri(Uri.parse('file:///tmp/test.jpg')),
        ),
        isFalse,
      );
    });

    test('uploadImage stores jpeg submission with product name', () async {
      AuthService.setCurrentUserForTesting(fakeUser);
      String? capturedMime;
      Map<String, dynamic>? capturedPayload;
      ProductImageService.fakeReadImageBytes = (_) async =>
          Uint8List.fromList([1, 2, 3]);
      ProductImageService.fakeUploadBinary = (_, __, mimeType) async {
        capturedMime = mimeType;
      };
      ProductImageService.fakeGetPublicUrl = (path) =>
          'https://example.com/$path';
      ProductImageService.fakeInsertSubmission = (payload) async {
        capturedPayload = payload;
      };

      final ok = await ProductImageService.uploadImage(
        barcode: '1234567890123',
        imageFile: File.fromUri(Uri.parse('file:///tmp/front.jpg')),
        type: ProductImageType.front,
        productName: 'Snack',
      );

      expect(ok, isTrue);
      expect(capturedMime, 'image/jpeg');
      expect(capturedPayload?['barcode'], '1234567890123');
      expect(capturedPayload?['image_type'], 'front');
      expect(capturedPayload?['product_name'], 'Snack');
      expect(capturedPayload?['submitted_by'], 'test-uid');
    });

    test('uploadImage omits blank product name from payload', () async {
      AuthService.setCurrentUserForTesting(fakeUser);
      Map<String, dynamic>? capturedPayload;
      ProductImageService.fakeReadImageBytes = (_) async =>
          Uint8List.fromList([1]);
      ProductImageService.fakeUploadBinary = (_, __, ___) async {};
      ProductImageService.fakeGetPublicUrl = (path) => 'https://example.com/$path';
      ProductImageService.fakeInsertSubmission = (payload) async {
        capturedPayload = payload;
      };

      await ProductImageService.uploadImage(
        barcode: '1234567890123',
        imageFile: File.fromUri(Uri.parse('file:///tmp/front.jpg')),
        productName: '',
      );

      expect(capturedPayload?.containsKey('product_name'), isFalse);
    });

    test('uploadImage uses png mime type for png files', () async {
      AuthService.setCurrentUserForTesting(fakeUser);
      String? capturedMime;
      ProductImageService.fakeReadImageBytes = (_) async =>
          Uint8List.fromList([1]);
      ProductImageService.fakeUploadBinary = (_, __, mimeType) async {
        capturedMime = mimeType;
      };
      ProductImageService.fakeGetPublicUrl = (path) =>
          'https://example.com/$path';
      ProductImageService.fakeInsertSubmission = (_) async {};

      await ProductImageService.uploadImage(
        barcode: '1234567890123',
        imageFile: File.fromUri(Uri.parse('file:///tmp/label.png')),
        type: ProductImageType.nutrition,
      );

      expect(capturedMime, 'image/png');
    });

    test('uploadImage returns false when upload throws', () async {
      AuthService.setCurrentUserForTesting(fakeUser);
      ProductImageService.fakeReadImageBytes = (_) async =>
          Uint8List.fromList([1]);
      ProductImageService.fakeUploadBinary = (_, __, ___) async =>
          throw Exception('upload failed');

      expect(
        await ProductImageService.uploadImage(
          barcode: '1234567890123',
          imageFile: File.fromUri(Uri.parse('file:///tmp/front.jpg')),
        ),
        isFalse,
      );
    });

    test('updateSubmissionStatus returns false when update throws', () async {
      ProductImageService.fakePerformSubmissionStatusUpdate = (_, _) async =>
          throw Exception('update failed');

      expect(
        await ProductImageService.updateSubmissionStatus(1, 'approved'),
        isFalse,
      );
    });

    test('updateSubmissionStatus returns true via perform fake', () async {
      String? capturedStatus;
      ProductImageService.fakePerformSubmissionStatusUpdate =
          (id, status) async {
            expect(id, 5);
            capturedStatus = status;
          };

      expect(
        await ProductImageService.updateSubmissionStatus(5, 'rejected'),
        isTrue,
      );
      expect(capturedStatus, 'rejected');
    });
  });
}
