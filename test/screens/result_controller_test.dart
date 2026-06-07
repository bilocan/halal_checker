import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:halal_checker/models/feedback.dart';
import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/models/product_analysis.dart';
import 'package:halal_checker/models/review_status.dart';
import 'package:halal_checker/screens/result/result_controller.dart';
import 'package:halal_checker/services/ai_ingredient_request_service.dart';
import 'package:halal_checker/services/auth_service.dart';
import 'package:halal_checker/services/database_service.dart';
import 'package:halal_checker/services/deep_analysis_feature_service.dart';
import 'package:halal_checker/services/product_service.dart';
import '../helpers/database_test_setup.dart';
import '../helpers/stub_feedback_service.dart';
import '../helpers/stub_result_analysis_service.dart';
import '../helpers/test_product_fixture.dart';

void main() {
  setUpAll(initTestDatabase);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await clearTestScans();
  });

  ResultController controller({
    String barcode = '1234567890123',
    Product? product,
    StubFeedbackService? feedbackService,
    StubResultAnalysisService? analysisService,
    DeepAnalysisFeatureService? deepAnalysisFeatureService,
  }) {
    return ResultController(
      barcode: barcode,
      product: product,
      feedbackService: feedbackService,
      analysisService: analysisService,
      deepAnalysisFeatureService:
          deepAnalysisFeatureService ??
          DeepAnalysisFeatureService(fetchConfigValue: (_) async => 'true'),
    );
  }

  group('ResultController', () {
    test('loadFeedbacks sets items on success', () async {
      final feedback = FeedbackItem(
        id: '1',
        barcode: '1234567890123',
        userFeedback: 'Looks good',
        submittedAt: DateTime(2024, 1, 1),
      );
      final c = controller(
        feedbackService: StubFeedbackService(items: [feedback]),
      );

      await c.loadFeedbacks();

      expect(c.feedbacks, [feedback]);
      expect(c.feedbackLoadFailed, isFalse);
      expect(c.isLoadingFeedback, isFalse);
    });

    test('loadFeedbacks sets feedbackLoadFailed on error', () async {
      final c = controller(
        feedbackService: StubFeedbackService(failOnLoad: true),
      );

      await c.loadFeedbacks();

      expect(c.feedbacks, isEmpty);
      expect(c.feedbackLoadFailed, isTrue);
    });

    test('saveNote and toggleFlag persist via DatabaseService', () async {
      await DatabaseService.instance.insertScan(
        barcode: '1234567890123',
        productName: 'Snack',
        isHalal: true,
      );
      final c = controller();

      await c.loadNote();
      expect(c.note, isEmpty);
      expect(c.isFlagged, isFalse);

      await c.saveNote('  halal note  ');
      expect(c.note, 'halal note');

      await c.toggleFlag('halal note');
      expect(c.isFlagged, isTrue);

      final data = await DatabaseService.instance.getScanNote('1234567890123');
      expect(data?['notes'], 'halal note');
      expect(data?['isFlagged'], isTrue);
    });

    test('loadAdminStatus reflects analysis service', () async {
      final c = controller(
        analysisService: StubResultAnalysisService(admin: true),
      );

      await c.loadAdminStatus();

      expect(c.isAdmin, isTrue);
    });

    test('loadAnalysis stores product analysis', () async {
      final analysis = ProductAnalysis(
        id: 'a1',
        barcode: '1234567890123',
        status: AnalysisStatus.aiDone,
        aiAnalysis: const DeepAnalysisResult(summary: 'ok', ingredients: []),
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
      );
      final c = controller(
        analysisService: StubResultAnalysisService(analysis: analysis),
      );

      await c.loadAnalysis();

      expect(c.analysis, analysis);
    });

    test(
      'requestDeepAnalysis returns null when user is not signed in',
      () async {
        final c = controller(
          analysisService: StubResultAnalysisService(
            analysis: ProductAnalysis(
              id: 'a2',
              barcode: '1234567890123',
              status: AnalysisStatus.aiDone,
              createdAt: DateTime(2024, 6, 1),
              updatedAt: DateTime(2024, 6, 1),
            ),
          ),
        );

        expect(await c.requestDeepAnalysis(), isNull);
        expect(c.isRequestingAnalysis, isFalse);
      },
    );

    test('requestDeepAnalysis returns null when feature disabled', () async {
      final c = controller(
        deepAnalysisFeatureService: DeepAnalysisFeatureService(
          fetchConfigValue: (_) async => 'false',
        ),
      );
      c.deepAnalysisEnabled = false;

      expect(await c.requestDeepAnalysis(), isNull);
      expect(c.isRequestingAnalysis, isFalse);
    });

    group('requestAiIngredients', () {
      const barcode = '1234567890123';
      const fakeUser = User(
        id: 'test-uid',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2024-01-01T00:00:00',
        isAnonymous: false,
      );

      setUp(() {
        AiIngredientRequestService.enableForTesting();
        AiIngredientRequestService.fakeEnsureReady = () async => true;
        AiIngredientRequestService.fakeIsAdmin = () async => false;
        AuthService.setCurrentUserForTesting(fakeUser);
      });

      tearDown(() {
        AiIngredientRequestService.resetForTesting();
        AuthService.resetForTesting();
        ProductService().resetForTesting();
      });

      test('returns null when user is not signed in', () async {
        AuthService.resetForTesting();
        final c = controller(barcode: barcode);

        expect(await c.requestAiIngredients(), isNull);
        expect(c.isFetchingAiIngredients, isFalse);
      });

      test('sets pending and does not fetch for regular user', () async {
        AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => null;
        AiIngredientRequestService.fakeInsertRequest =
            ({required barcode, productName, required userId}) async {};
        var fetchCalled = false;
        ProductService().testFetchIngredientsByAI = (_) async {
          fetchCalled = true;
          return null;
        };

        final c = controller(barcode: barcode);
        expect(await c.requestAiIngredients(), isTrue);
        expect(c.aiRequestStatus, ReviewStatus.pending);
        expect(c.aiRefreshedProduct, isNull);
        expect(fetchCalled, isFalse);
      });

      test('admin auto-approve fetches and sets aiRefreshedProduct', () async {
        final refreshed = testProduct(
          barcode,
          ingredients: ['sugar', 'cocoa'],
          isUnknown: false,
          ingredientSource: 'ai',
        );
        AiIngredientRequestService.fakeIsAdmin = () async => true;
        AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => null;
        AiIngredientRequestService.fakeInsertRequest =
            ({required barcode, productName, required userId}) async {};
        ProductService().testFetchIngredientsByAI = (_) async => refreshed;

        final c = controller(barcode: barcode);
        expect(await c.requestAiIngredients(), isTrue);
        expect(c.aiRequestStatus, ReviewStatus.approved);
        expect(c.aiRefreshedProduct, refreshed);
      });

      test('admin promoting pending request fetches ingredients', () async {
        final refreshed = testProduct(
          barcode,
          ingredients: ['milk'],
          isUnknown: false,
          ingredientSource: 'ai',
        );
        AiIngredientRequestService.fakeIsAdmin = () async => true;
        AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => {
          'id': 3,
        };
        AiIngredientRequestService.fakePerformStatusUpdate =
            (id, status, userId) async {
              expect(id, 3);
              expect(status, 'approved');
              return [
                {'id': 3},
              ];
            };
        ProductService().testFetchIngredientsByAI = (_) async => refreshed;

        final c = controller(barcode: barcode);
        expect(await c.requestAiIngredients(), isTrue);
        expect(c.aiRequestStatus, ReviewStatus.approved);
        expect(c.aiRefreshedProduct, refreshed);
      });

      test(
        'returns false when non-admin and request already pending',
        () async {
          AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => {
            'id': 1,
          };

          final c = controller(barcode: barcode);
          expect(await c.requestAiIngredients(), isFalse);
          expect(c.aiRefreshedProduct, isNull);
        },
      );

      test('clears isFetchingAiIngredients after completion', () async {
        AiIngredientRequestService.fakeFindPendingByBarcode = (_) async => null;
        AiIngredientRequestService.fakeInsertRequest =
            ({required barcode, productName, required userId}) async {};

        final c = controller(barcode: barcode);
        await c.requestAiIngredients();

        expect(c.isFetchingAiIngredients, isFalse);
      });
    });
  });
}
