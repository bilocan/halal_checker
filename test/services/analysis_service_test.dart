import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:halal_checker/models/product_analysis.dart';
import 'package:halal_checker/services/analysis_service.dart';

const _fakeUrl = 'https://test.supabase.co';
const _fakeJwt = 'test-jwt-token';
const _fakeBarcode = '111222333';
const _ts = '2026-01-01T12:00:00.000Z';

// Builds an AnalysisService that bypasses Supabase config and auth checks.
AnalysisService _service(MockClient client) => AnalysisService(
  httpClient: client,
  hasSupabase: true,
  supabaseUrl: _fakeUrl,
);

// Full Edge Function response body for a completed analysis.
String _analysisResponse({
  String status = 'ai_done',
  bool withAiAnalysis = true,
}) => jsonEncode({
  'analysis': {
    'id': 'analysis-uuid',
    'barcode': _fakeBarcode,
    'status': status,
    'ai_analysis': withAiAnalysis
        ? {
            'summary': 'Product contains one suspicious ingredient.',
            'ingredients': [
              {
                'name': 'gelatin',
                'verdict': 'suspicious',
                'confidence': 'medium',
                'reason': 'Source unspecified',
                'islamicBasis': '',
                'alternativeNames': ['E441'],
              },
            ],
          }
        : null,
    'final_verdict': null,
    'final_verdict_reason': null,
    'created_at': _ts,
    'updated_at': _ts,
  },
});

void main() {
  // ── guard paths ────────────────────────────────────────────────────────────

  group('AnalysisService — hasSupabase: false (no config)', () {
    late AnalysisService service;

    setUp(() => service = AnalysisService(hasSupabase: false));

    test('requestDeepAnalysis returns null without jwtOverride', () async {
      expect(await service.requestDeepAnalysis(_fakeBarcode), isNull);
    });

    test('getAnalysis returns null', () async {
      expect(await service.getAnalysis(_fakeBarcode), isNull);
    });

    test('runBatch returns null without jwtOverride', () async {
      expect(await service.runBatch(), isNull);
    });
  });

  // ── requestDeepAnalysis ────────────────────────────────────────────────────

  group('AnalysisService.requestDeepAnalysis — HTTP paths', () {
    test('returns ProductAnalysis on HTTP 200', () async {
      final client = MockClient(
        (_) async => http.Response(_analysisResponse(), 200),
      );
      final result = await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);

      expect(result, isNotNull);
      expect(result!.barcode, _fakeBarcode);
      expect(result.status, AnalysisStatus.aiDone);
      expect(result.aiAnalysis, isNotNull);
      expect(result.aiAnalysis!.ingredients.length, 1);
      expect(result.aiAnalysis!.ingredients[0].name, 'gelatin');
    });

    test('sends POST to the correct Edge Function URL', () async {
      late Uri capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(_analysisResponse(), 200);
      });

      await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);

      expect(capturedUri.host, 'test.supabase.co');
      expect(capturedUri.path, '/functions/v1/deep-analyze-product');
    });

    test('sends correct Authorization header and barcode body', () async {
      late Map<String, String> capturedHeaders;
      late Map<String, dynamic> capturedBody;

      final client = MockClient((req) async {
        capturedHeaders = req.headers;
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(_analysisResponse(), 200);
      });

      await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);

      expect(capturedHeaders['Authorization'], 'Bearer $_fakeJwt');
      expect(capturedHeaders['Content-Type'], contains('application/json'));
      expect(capturedBody['barcode'], _fakeBarcode);
    });

    test('returns null on HTTP 401', () async {
      final client = MockClient(
        (_) async => http.Response('Unauthorized', 401),
      );
      final result = await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);
      expect(result, isNull);
    });

    test('returns null on HTTP 404 (product not found)', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'Product not found'}), 404),
      );
      final result = await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);
      expect(result, isNull);
    });

    test('returns null on HTTP 503 (AI unavailable)', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'error': 'AI unavailable'}), 503),
      );
      final result = await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);
      expect(result, isNull);
    });

    test('returns null on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Network error'),
      );
      final result = await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);
      expect(result, isNull);
    });

    test('parses pending record (no ai_analysis) without throwing', () async {
      final client = MockClient(
        (_) async => http.Response(
          _analysisResponse(status: 'pending', withAiAnalysis: false),
          200,
        ),
      );
      final result = await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);

      expect(result, isNotNull);
      expect(result!.status, AnalysisStatus.pending);
      expect(result.aiAnalysis, isNull);
    });
  });

  // ── runBatch ───────────────────────────────────────────────────────────────

  group('AnalysisService.runBatch — HTTP paths', () {
    test('returns result map on HTTP 200', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'processed': 3,
            'results': {'done': 2, 'skipped': 1, 'error': 0},
          }),
          200,
        ),
      );
      final result = await _service(
        client,
      ).runBatch(limit: 3, jwtOverride: _fakeJwt);

      expect(result, isNotNull);
      expect(result!['processed'], 3);
    });

    test('sends correct limit in request body', () async {
      late Map<String, dynamic> capturedBody;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'processed': 0}), 200);
      });

      await _service(client).runBatch(limit: 7, jwtOverride: _fakeJwt);

      expect(capturedBody['limit'], 7);
    });

    test('returns null on HTTP 403 (not admin)', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'error': 'Forbidden'}), 403),
      );
      final result = await _service(client).runBatch(jwtOverride: _fakeJwt);
      expect(result, isNull);
    });

    test('returns null on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Timeout'),
      );
      final result = await _service(client).runBatch(jwtOverride: _fakeJwt);
      expect(result, isNull);
    });
  });
}
