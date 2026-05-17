import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/issue_report_service.dart';

void main() {
  // ── ExpectedResult.value ──────────────────────────────────────────────────

  group('ExpectedResult.value', () {
    test('halal → "halal"', () {
      expect(ExpectedResult.halal.value, 'halal');
    });

    test('haram → "haram"', () {
      expect(ExpectedResult.haram.value, 'haram');
    });

    test('nonFood → "non_food"', () {
      expect(ExpectedResult.nonFood.value, 'non_food');
    });

    test('unknown → "unknown"', () {
      expect(ExpectedResult.unknown.value, 'unknown');
    });
  });

  // ── IssueReportResult ─────────────────────────────────────────────────────

  group('IssueReportResult', () {
    test('stores success, issueUrl, and issueNumber', () {
      const result = IssueReportResult(
        success: true,
        issueUrl: 'https://github.com/example/issues/1',
        issueNumber: 1,
      );
      expect(result.success, isTrue);
      expect(result.issueUrl, 'https://github.com/example/issues/1');
      expect(result.issueNumber, 1);
    });

    test('optional fields default to null', () {
      const result = IssueReportResult(success: false);
      expect(result.success, isFalse);
      expect(result.issueUrl, isNull);
      expect(result.issueNumber, isNull);
    });
  });

  // ── IssueReportService — no Supabase config ───────────────────────────────
  // AppConfig.hasSupabase is false in tests (no --dart-define flags), so
  // reportWrongResult returns failure immediately without network calls.

  // AppConfig.hasSupabase is false in tests (no --dart-define flags), so
  // reportWrongResult returns failure immediately without any network call.
  group('IssueReportService — no Supabase config', () {
    test(
      'reportWrongResult returns success: false for haram expected',
      () async {
        final result = await IssueReportService.reportWrongResult(
          barcode: '111222333',
          productName: 'Test Product',
          currentResult: 'halal',
          expectedResult: ExpectedResult.haram,
        );
        expect(result.success, isFalse);
        expect(result.issueUrl, isNull);
        expect(result.issueNumber, isNull);
      },
    );

    test(
      'reportWrongResult returns success: false for halal expected',
      () async {
        final result = await IssueReportService.reportWrongResult(
          barcode: '111222333',
          productName: 'Test Product',
          currentResult: 'haram',
          expectedResult: ExpectedResult.halal,
        );
        expect(result.success, isFalse);
      },
    );

    test(
      'reportWrongResult returns success: false for nonFood expected',
      () async {
        final result = await IssueReportService.reportWrongResult(
          barcode: '111222333',
          productName: 'Test Product',
          currentResult: 'halal',
          expectedResult: ExpectedResult.nonFood,
        );
        expect(result.success, isFalse);
      },
    );

    test(
      'reportWrongResult returns success: false for unknown expected',
      () async {
        final result = await IssueReportService.reportWrongResult(
          barcode: '111222333',
          productName: 'Test Product',
          currentResult: 'halal',
          expectedResult: ExpectedResult.unknown,
        );
        expect(result.success, isFalse);
      },
    );

    test('reportWrongResult with note returns success: false', () async {
      final result = await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.haram,
        note: 'Contains gelatin',
      );
      expect(result.success, isFalse);
    });

    test('reportWrongResult with empty note returns success: false', () async {
      final result = await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.haram,
        note: '',
      );
      expect(result.success, isFalse);
    });
  });
}
