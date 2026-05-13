import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/models/product_analysis.dart';
import 'package:halal_checker/services/analysis_service.dart';

const _fakeUrl = 'https://test.supabase.co';
const _fakeJwt = 'test-jwt-token';
const _fakeBarcode = '111222333';
const _ts = '2026-01-01T12:00:00.000Z';

AnalysisService _service(MockClient client) => AnalysisService(
  httpClient: client,
  hasSupabase: true,
  supabaseUrl: _fakeUrl,
);

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
            'summary': 'Product is halal.',
            'ingredients': [
              {
                'name': 'sugar',
                'verdict': 'halal',
                'confidence': 'high',
                'reason': 'Plant-derived',
                'islamicBasis': '',
                'alternativeNames': [],
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
  // ── requestDeepAnalysis with Product data ────────────────────────────────

  group('AnalysisService.requestDeepAnalysis — with product data', () {
    test('includes productData in request body', () async {
      late Map<String, dynamic> capturedBody;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(_analysisResponse(), 200);
      });

      final product = Product(
        barcode: _fakeBarcode,
        name: 'Test Product',
        ingredients: ['sugar', 'water'],
        isHalal: false,
        haramIngredients: ['alcohol'],
        suspiciousIngredients: ['gelatin'],
        ingredientWarnings: {},
        labels: [],
        explanation: 'Test',
      );

      await _service(client).requestDeepAnalysis(
        _fakeBarcode,
        product: product,
        jwtOverride: _fakeJwt,
      );

      expect(capturedBody['barcode'], _fakeBarcode);
      expect(capturedBody['productData'], isNotNull);
      expect(capturedBody['productData']['name'], 'Test Product');
      expect(capturedBody['productData']['ingredients'], ['sugar', 'water']);
      expect(capturedBody['productData']['haram_ingredients'], ['alcohol']);
      expect(capturedBody['productData']['suspicious_ingredients'], [
        'gelatin',
      ]);
    });

    test('omits productData when product is null', () async {
      late Map<String, dynamic> capturedBody;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(_analysisResponse(), 200);
      });

      await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);

      expect(capturedBody.containsKey('productData'), isFalse);
    });
  });

  // ── requestDeepAnalysis — jwt guard ──────────────────────────────────────

  group('AnalysisService.requestDeepAnalysis — jwt guard', () {
    test('returns null when no jwtOverride and hasSupabase false', () async {
      final service = AnalysisService(hasSupabase: false);
      final result = await service.requestDeepAnalysis(_fakeBarcode);
      expect(result, isNull);
    });

    test('bypasses hasSupabase guard when jwtOverride is provided', () async {
      final client = MockClient(
        (_) async => http.Response(_analysisResponse(), 200),
      );
      final service = AnalysisService(
        httpClient: client,
        hasSupabase: false,
        supabaseUrl: _fakeUrl,
      );

      final result = await service.requestDeepAnalysis(
        _fakeBarcode,
        jwtOverride: _fakeJwt,
      );
      expect(result, isNotNull);
      expect(result!.barcode, _fakeBarcode);
    });
  });

  // ── runBatch with ids ──────────────────────────────────────────────────────

  group('AnalysisService.runBatch — with ids', () {
    test('sends ids in request body when provided', () async {
      late Map<String, dynamic> capturedBody;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'processed': 2}), 200);
      });

      await _service(
        client,
      ).runBatch(ids: ['id-1', 'id-2'], jwtOverride: _fakeJwt);

      expect(capturedBody['ids'], ['id-1', 'id-2']);
    });

    test('omits ids from body when not provided', () async {
      late Map<String, dynamic> capturedBody;
      final client = MockClient((req) async {
        capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'processed': 0}), 200);
      });

      await _service(client).runBatch(jwtOverride: _fakeJwt);

      expect(capturedBody.containsKey('ids'), isFalse);
    });

    test('bypasses hasSupabase guard when jwtOverride is provided', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'processed': 0}), 200),
      );
      final service = AnalysisService(
        httpClient: client,
        hasSupabase: false,
        supabaseUrl: _fakeUrl,
      );

      final result = await service.runBatch(jwtOverride: _fakeJwt);
      expect(result, isNotNull);
    });
  });

  // ── isAdmin — no Supabase ────────────────────────────────────────────────

  group('AnalysisService.isAdmin — no Supabase config', () {
    test('returns false', () async {
      final service = AnalysisService(hasSupabase: false);
      expect(await service.isAdmin(), isFalse);
    });
  });

  // ── getAnalysisList — no Supabase ────────────────────────────────────────

  group('AnalysisService.getAnalysisList — no Supabase config', () {
    test('returns null', () async {
      final service = AnalysisService(hasSupabase: false);
      expect(await service.getAnalysisList(), isNull);
    });
  });

  // ── getAnalysis — no Supabase ────────────────────────────────────────────

  group('AnalysisService.getAnalysis — no Supabase config', () {
    test('returns null', () async {
      final service = AnalysisService(hasSupabase: false);
      expect(await service.getAnalysis(_fakeBarcode), isNull);
    });
  });

  // ── requestDeepAnalysis — response parsing ───────────────────────────────

  group('AnalysisService.requestDeepAnalysis — response parsing', () {
    test('parses resolved record with final_verdict', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'analysis': {
              'id': 'analysis-uuid',
              'barcode': _fakeBarcode,
              'status': 'resolved',
              'ai_analysis': null,
              'final_verdict': 'halal',
              'final_verdict_reason': 'Reviewed by admin',
              'created_at': _ts,
              'updated_at': _ts,
            },
          }),
          200,
        ),
      );

      final result = await _service(
        client,
      ).requestDeepAnalysis(_fakeBarcode, jwtOverride: _fakeJwt);
      expect(result, isNotNull);
      expect(result!.status, AnalysisStatus.resolved);
      expect(result.finalVerdict, 'halal');
      expect(result.finalVerdictReason, 'Reviewed by admin');
    });
  });

  // ── runBatch — sends POST to correct URL ─────────────────────────────────

  group('AnalysisService.runBatch — URL and headers', () {
    test('sends POST to batch-analyze Edge Function', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      final client = MockClient((req) async {
        capturedUri = req.url;
        capturedHeaders = req.headers;
        return http.Response(jsonEncode({'processed': 0}), 200);
      });

      await _service(client).runBatch(jwtOverride: _fakeJwt);

      expect(capturedUri.host, 'test.supabase.co');
      expect(capturedUri.path, '/functions/v1/batch-analyze');
      expect(capturedHeaders['Authorization'], 'Bearer $_fakeJwt');
      expect(capturedHeaders['Content-Type'], contains('application/json'));
    });
  });
}
