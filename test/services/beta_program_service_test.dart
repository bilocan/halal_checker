import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/beta_program_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BetaProgramService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('fetchBannerEnabled uses injected config fetcher', () async {
      final service = BetaProgramService(
        fetchConfigValue: (key) async {
          expect(key, BetaProgramService.closedBetaBannerKey);
          return 'true';
        },
      );
      expect(await service.fetchBannerEnabled(), isTrue);
    });

    test('shouldShowHomeBanner false when dismissed locally', () async {
      final service = BetaProgramService(fetchConfigValue: (_) async => 'true');
      await BetaProgramService.dismissBanner();
      expect(await service.shouldShowHomeBanner(), isFalse);
    });

    test('shouldShowHomeBanner true when enabled and not dismissed', () async {
      final service = BetaProgramService(fetchConfigValue: (_) async => 'true');
      expect(await service.shouldShowHomeBanner(), isTrue);
    });
    test(
      'fetchBannerEnabled false without injector on non-Android test host',
      () async {
        expect(await BetaProgramService().fetchBannerEnabled(), isFalse);
      },
    );

    test(
      'fetchBannerEnabled reads app_config via anon REST without sign-in',
      () async {
        final service = BetaProgramService(
          isAndroid: true,
          hasSupabase: true,
          supabaseUrl: 'https://example.supabase.co',
          anonKey: 'test-anon-key',
          httpClient: MockClient((request) async {
            expect(request.url.path, '/rest/v1/app_config');
            expect(request.url.query, contains('key=eq.closed_beta_banner'));
            expect(request.headers['Authorization'], isNotNull);
            return http.Response(
              jsonEncode([
                {'value': 'true'},
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        expect(await service.fetchBannerEnabled(), isTrue);
      },
    );

    test('fetchBannerEnabled false when REST returns empty rows', () async {
      final service = BetaProgramService(
        isAndroid: true,
        hasSupabase: true,
        supabaseUrl: 'https://example.supabase.co',
        anonKey: 'test-anon-key',
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(await service.fetchBannerEnabled(), isFalse);
    });
  });
}
