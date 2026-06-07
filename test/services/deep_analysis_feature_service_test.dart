import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/deep_analysis_feature_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('DeepAnalysisFeatureService', () {
    test('isEnabled uses injected config fetcher', () async {
      final service = DeepAnalysisFeatureService(
        fetchConfigValue: (key) async {
          expect(key, DeepAnalysisFeatureService.deepAnalysisEnabledKey);
          return 'true';
        },
      );
      expect(await service.isEnabled(), isTrue);
    });

    test('isEnabled false when injected fetcher returns false', () async {
      final service = DeepAnalysisFeatureService(
        fetchConfigValue: (_) async => 'false',
      );
      expect(await service.isEnabled(), isFalse);
    });

    test('isEnabled reads app_config via anon REST', () async {
      final service = DeepAnalysisFeatureService(
        hasSupabase: true,
        supabaseUrl: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/app_config');
          expect(request.url.query, contains('key=eq.deep_analysis_enabled'));
          return http.Response(
            jsonEncode([
              {'value': 'true'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      expect(await service.isEnabled(), isTrue);
    });

    test('isEnabled false when REST returns empty rows', () async {
      final service = DeepAnalysisFeatureService(
        hasSupabase: true,
        supabaseUrl: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(await service.isEnabled(), isFalse);
    });
  });
}
