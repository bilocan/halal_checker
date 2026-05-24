import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:halal_checker/models/feedback.dart';
import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/models/product_analysis.dart';
import 'package:halal_checker/screens/result/result_controller.dart';
import 'package:halal_checker/services/database_service.dart';
import '../helpers/database_test_setup.dart';
import '../helpers/stub_feedback_service.dart';
import '../helpers/stub_result_analysis_service.dart';

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
  }) {
    return ResultController(
      barcode: barcode,
      product: product,
      feedbackService: feedbackService,
      analysisService: analysisService,
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
  });
}
