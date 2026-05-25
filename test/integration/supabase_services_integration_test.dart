// Live Supabase integration tests for service-layer DB paths.
//
// Run (mirrors the app credentials):
//   flutter test test/integration/supabase_services_integration_test.dart \
//     --dart-define-from-file=dart_defines.json --concurrency 1
//
// Optional defines (add to dart_defines.json for full coverage):
//   SUPABASE_TEST_EMAIL, SUPABASE_TEST_PASSWORD
//   SUPABASE_TEST_ADMIN_EMAIL, SUPABASE_TEST_ADMIN_PASSWORD
//   SUPABASE_SERVICE_ROLE_KEY
//
// On Linux/macOS:
//   ./run_integration_test.sh test/integration/supabase_services_integration_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/ai_ingredient_request.dart';
import 'package:halal_checker/services/ai_ingredient_request_service.dart';
import 'package:halal_checker/services/auth_service.dart';
import 'package:halal_checker/services/ingredient_report_service.dart';
import 'package:halal_checker/services/product_image_service.dart';

import 'helpers/supabase_integration_helper.dart';

/// Minimal valid JPEG bytes for storage upload tests.
final _minimalJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

void main() {
  setUpAll(() async {
    await SupabaseIntegrationHelper.initOnce();
  });

  setUp(SupabaseIntegrationHelper.resetServiceFakes);

  group('IngredientReportService — live Supabase', () {
    String? barcode;

    setUp(() {
      SupabaseIntegrationHelper.skipIfNoSupabase();
      barcode = SupabaseIntegrationHelper.uniqueBarcode(prefix: '9999991');
    });

    tearDown(() async {
      if (barcode != null) {
        await SupabaseIntegrationHelper.deleteIngredientReportsForBarcode(
          barcode!,
        );
      }
      await SupabaseIntegrationHelper.signOut();
    });

    test('submitReport inserts via real PostgREST (anonymous OK)', () async {
      final ok = await IngredientReportService.submitReport(
        barcode: barcode!,
        productName: 'Integration Snack',
        ingredients: ['water', 'salt', 'sugar'],
        explanation: 'integration test row',
      );

      expect(ok, isTrue);
    });

    if (SupabaseIntegrationHelper.hasTestAdmin) {
      test('getReports and updateStatus work for admin', () async {
        await SupabaseIntegrationHelper.signInTestAdmin();

        final submitted = await IngredientReportService.submitReport(
          barcode: barcode!,
          productName: 'Admin Review Snack',
          ingredients: ['water'],
        );
        expect(submitted, isTrue);

        final pending = await IngredientReportService.getReports();
        expect(
          pending.any((row) => row['barcode'] == barcode),
          isTrue,
          reason: 'Admin should see the submitted report',
        );

        final row = pending.firstWhere((r) => r['barcode'] == barcode);
        final id = row['id'] as int;

        final updated = await IngredientReportService.updateStatus(
          id,
          'approved',
        );
        expect(updated, isTrue);

        final approved = await IngredientReportService.getReports(
          status: 'approved',
        );
        expect(approved.any((r) => r['id'] == id), isTrue);
      });
    }
  });

  if (SupabaseIntegrationHelper.hasTestUser) {
    group('AiIngredientRequestService — live Supabase', () {
      String? barcode;

      setUp(() {
        SupabaseIntegrationHelper.skipIfNoSupabase();
        barcode = SupabaseIntegrationHelper.uniqueBarcode(prefix: '9999992');
      });

      tearDown(() async {
        if (barcode != null) {
          await SupabaseIntegrationHelper.deleteAiRequestsForBarcode(barcode!);
        }
        await SupabaseIntegrationHelper.signOut();
      });

      test(
        'submitRequest inserts and getRequestForBarcode reads it back',
        () async {
          await SupabaseIntegrationHelper.signInTestUser();

          final result = await AiIngredientRequestService.submitRequest(
            barcode!,
            productName: 'Integration Chips',
          );
          expect(result, AiIngredientSubmitResult.pending);

          final row = await AiIngredientRequestService.getRequestForBarcode(
            barcode!,
          );
          expect(row, isNotNull);
          expect(row!['status'], 'pending');
          expect(row['id'], isNotNull);
        },
      );

      test(
        'submitRequest rejects duplicate pending request for same barcode',
        () async {
          await SupabaseIntegrationHelper.signInTestUser();

          expect(
            await AiIngredientRequestService.submitRequest(
              barcode!,
              productName: 'First',
            ),
            AiIngredientSubmitResult.pending,
          );
          expect(
            await AiIngredientRequestService.submitRequest(
              barcode!,
              productName: 'Duplicate',
            ),
            AiIngredientSubmitResult.alreadyPending,
          );
        },
      );

      test('getPendingRequests includes submitted barcode', () async {
        await SupabaseIntegrationHelper.signInTestUser();

        await AiIngredientRequestService.submitRequest(
          barcode!,
          productName: 'Pending Item',
        );

        final pending = await AiIngredientRequestService.getPendingRequests();
        expect(pending.any((row) => row['barcode'] == barcode), isTrue);
      });

      if (SupabaseIntegrationHelper.hasTestAdmin) {
        test('admin submitRequest is auto-approved', () async {
          await SupabaseIntegrationHelper.signInTestAdmin();

          final result = await AiIngredientRequestService.submitRequest(
            barcode!,
            productName: 'Admin Auto',
          );
          expect(result, AiIngredientSubmitResult.approved);

          final row = await AiIngredientRequestService.getRequestForBarcode(
            barcode!,
          );
          expect(row?['status'], 'approved');
        });

        test('admin updateStatus approves a pending request', () async {
          await SupabaseIntegrationHelper.signInTestUser();

          await AiIngredientRequestService.submitRequest(
            barcode!,
            productName: 'Awaiting Approval',
          );

          final pending = await AiIngredientRequestService.getPendingRequests();
          final row = pending.firstWhere((r) => r['barcode'] == barcode);
          final id = row['id'] as int;

          await SupabaseIntegrationHelper.signOut();
          await SupabaseIntegrationHelper.signInTestAdmin();

          final updated = await AiIngredientRequestService.updateStatus(
            id,
            'approved',
          );
          expect(updated, isTrue);

          final approved =
              await AiIngredientRequestService.getApprovedRequests();
          expect(approved.any((r) => r['id'] == id), isTrue);
        });
      }
    });

    group('ProductImageService — live Supabase', () {
      String? barcode;
      File? imageFile;
      Directory? tempDir;

      setUp(() {
        SupabaseIntegrationHelper.skipIfNoSupabase();
        barcode = SupabaseIntegrationHelper.uniqueBarcode(prefix: '9999993');
      });

      tearDown(() async {
        if (barcode != null) {
          await SupabaseIntegrationHelper.deleteImageSubmissionsForBarcode(
            barcode!,
          );
        }
        await SupabaseIntegrationHelper.signOut();
        if (tempDir != null && await tempDir!.exists()) {
          await tempDir!.delete(recursive: true);
        }
      });

      test('uploadImage stores submission row', () async {
        await SupabaseIntegrationHelper.signInTestUser();
        tempDir = await Directory.systemTemp.createTemp('halal_img_test_');
        imageFile = File('${tempDir!.path}/label.jpg')
          ..writeAsBytesSync(_minimalJpeg);

        expect(AuthService.currentUser, isNotNull);

        final ok = await ProductImageService.uploadImage(
          barcode: barcode!,
          imageFile: imageFile!,
          type: ProductImageType.ingredients,
          productName: 'Integration Product',
        );

        expect(ok, isTrue);
      });

      test(
        'getSubmissions returns uploaded row with enrichment fields',
        () async {
          await SupabaseIntegrationHelper.signInTestUser();
          tempDir = await Directory.systemTemp.createTemp('halal_img_test_');
          imageFile = File('${tempDir!.path}/label.jpg')
            ..writeAsBytesSync(_minimalJpeg);

          final uploaded = await ProductImageService.uploadImage(
            barcode: barcode!,
            imageFile: imageFile!,
            type: ProductImageType.front,
          );
          expect(uploaded, isTrue);

          final rows = await ProductImageService.getSubmissions(
            status: 'pending',
          );
          final match = rows.where((r) => r['barcode'] == barcode).toList();

          expect(match, isNotEmpty);
          expect(match.first['image_type'], 'front');
          expect(match.first.containsKey('current_image_url'), isTrue);
          expect(match.first['public_url'], isNotNull);
        },
      );

      test('updateSubmissionStatus rejects a submission', () async {
        await SupabaseIntegrationHelper.signInTestUser();
        tempDir = await Directory.systemTemp.createTemp('halal_img_test_');
        imageFile = File('${tempDir!.path}/label.jpg')
          ..writeAsBytesSync(_minimalJpeg);

        final uploaded = await ProductImageService.uploadImage(
          barcode: barcode!,
          imageFile: imageFile!,
        );
        expect(uploaded, isTrue);

        final rows = await ProductImageService.getSubmissions(
          status: 'pending',
        );
        final id = rows.firstWhere((r) => r['barcode'] == barcode)['id'] as int;

        final updated = await ProductImageService.updateSubmissionStatus(
          id,
          'rejected',
        );
        expect(updated, isTrue);

        final rejected = await ProductImageService.getSubmissions(
          status: 'rejected',
        );
        expect(rejected.any((r) => r['id'] == id), isTrue);
      });
    });
  }
}
