import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  // ── HTTP mock tests ───────────────────────────────────────────────────────

  group('IssueReportService — HTTP responses', () {
    tearDown(IssueReportService.resetForTesting);

    test(
      'HTTP 200 with issueUrl and issueNumber → success=true, fields set',
      () async {
        IssueReportService.setHttpClientForTesting(
          MockClient(
            (_) async => http.Response(
              jsonEncode({
                'issueUrl': 'https://github.com/x/y/issues/42',
                'issueNumber': 42,
              }),
              200,
            ),
          ),
        );
        final result = await IssueReportService.reportWrongResult(
          barcode: '111222333',
          productName: 'Test Product',
          currentResult: 'halal',
          expectedResult: ExpectedResult.haram,
        );
        expect(result.success, isTrue);
        expect(result.issueUrl, 'https://github.com/x/y/issues/42');
        expect(result.issueNumber, 42);
      },
    );

    test('HTTP 200 with missing fields → success=true, fields null', () async {
      IssueReportService.setHttpClientForTesting(
        MockClient((_) async => http.Response(jsonEncode({}), 200)),
      );
      final result = await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.haram,
      );
      expect(result.success, isTrue);
      expect(result.issueUrl, isNull);
      expect(result.issueNumber, isNull);
    });

    test('HTTP 400 → success=false', () async {
      IssueReportService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 400)),
      );
      final result = await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.haram,
      );
      expect(result.success, isFalse);
    });

    test('HTTP 500 → success=false', () async {
      IssueReportService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 500)),
      );
      final result = await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.haram,
      );
      expect(result.success, isFalse);
    });

    test('network exception → success=false', () async {
      IssueReportService.setHttpClientForTesting(
        MockClient((_) async => throw Exception('network error')),
      );
      final result = await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.haram,
      );
      expect(result.success, isFalse);
    });

    test('malformed JSON body → success=false', () async {
      IssueReportService.setHttpClientForTesting(
        MockClient((_) async => http.Response('not-json', 200)),
      );
      final result = await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.haram,
      );
      expect(result.success, isFalse);
    });

    test('non-empty note is included in request body', () async {
      late http.Request captured;
      IssueReportService.setHttpClientForTesting(
        MockClient((req) async {
          captured = req;
          return http.Response(jsonEncode({}), 200);
        }),
      );
      await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.haram,
        note: 'Contains gelatin',
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['note'], 'Contains gelatin');
    });

    test('empty note is omitted from request body', () async {
      late http.Request captured;
      IssueReportService.setHttpClientForTesting(
        MockClient((req) async {
          captured = req;
          return http.Response(jsonEncode({}), 200);
        }),
      );
      await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.haram,
        note: '',
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body.containsKey('note'), isFalse);
    });

    test('expectedResult.value is sent in request body', () async {
      late http.Request captured;
      IssueReportService.setHttpClientForTesting(
        MockClient((req) async {
          captured = req;
          return http.Response(jsonEncode({}), 200);
        }),
      );
      await IssueReportService.reportWrongResult(
        barcode: '111222333',
        productName: 'Test Product',
        currentResult: 'halal',
        expectedResult: ExpectedResult.nonFood,
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['expectedResult'], 'non_food');
    });
  });
}
