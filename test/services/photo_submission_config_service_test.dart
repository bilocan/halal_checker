import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/photo_submission_config_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('PhotoSubmissionConfigService', () {
    test('isAutoApproveEnabled uses injected config fetcher', () async {
      final service = PhotoSubmissionConfigService(
        fetchConfigValue: (key) async {
          expect(
            key,
            PhotoSubmissionConfigService.photoSubmissionsAutoApproveKey,
          );
          return 'true';
        },
      );
      expect(await service.isAutoApproveEnabled(), isTrue);
    });

    test('isAutoApproveEnabled false when fetcher returns false', () async {
      final service = PhotoSubmissionConfigService(
        fetchConfigValue: (_) async => 'false',
      );
      expect(await service.isAutoApproveEnabled(), isFalse);
    });

    test('isAutoApproveEnabled reads app_config via anon REST', () async {
      final service = PhotoSubmissionConfigService(
        hasSupabase: true,
        supabaseUrl: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/app_config');
          expect(
            request.url.query,
            contains('key=eq.photo_submissions_auto_approve'),
          );
          return http.Response(
            jsonEncode([
              {'value': 'true'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      expect(await service.isAutoApproveEnabled(), isTrue);
    });

    test('isAutoApproveEnabled false when REST returns empty rows', () async {
      final service = PhotoSubmissionConfigService(
        hasSupabase: true,
        supabaseUrl: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(await service.isAutoApproveEnabled(), isFalse);
    });
  });
}
