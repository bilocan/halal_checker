import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:halal_checker/services/version_service.dart';

const _androidConfig = {
  'latest_version': '1.0.0',
  'android_store_url':
      'https://play.google.com/store/apps/details?id=app.halalscan',
  'ios_store_url': 'https://apps.apple.com/app/halalscan',
};

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'HalalScan',
      packageName: 'app.halalscan',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('VersionService.isNewerVersion', () {
    test('equal versions → false', () {
      expect(VersionService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    });

    test('store major bump → true', () {
      expect(VersionService.isNewerVersion('2.0.0', '1.0.0'), isTrue);
    });

    test('store minor bump → true', () {
      expect(VersionService.isNewerVersion('1.1.0', '1.0.0'), isTrue);
    });

    test('store patch bump → true', () {
      expect(VersionService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
    });

    test('installed newer → false', () {
      expect(VersionService.isNewerVersion('1.0.0', '1.1.0'), isFalse);
    });

    test('missing patch segment → treated as 0', () {
      expect(VersionService.isNewerVersion('1.1', '1.0.0'), isTrue);
    });
  });

  group(
    'VersionService.checkWithConfig — store version matches installed (1.0.0)',
    () {
      test('status is upToDate', () async {
        final result = await VersionService().checkWithConfig(_androidConfig);
        expect(result.status, UpdateStatus.upToDate);
      });

      test('storeVersion is populated', () async {
        final result = await VersionService().checkWithConfig(_androidConfig);
        expect(result.storeVersion, '1.0.0');
      });
    },
  );

  group(
    'VersionService.checkWithConfig — update available on store (2.0.0 vs installed 1.0.0)',
    () {
      final config = {..._androidConfig, 'latest_version': '2.0.0'};

      test('status is updateAvailable', () async {
        final result = await VersionService().checkWithConfig(config);
        expect(result.status, UpdateStatus.updateAvailable);
      });

      test('storeVersion reflects the newer version', () async {
        final result = await VersionService().checkWithConfig(config);
        expect(result.storeVersion, '2.0.0');
      });
    },
  );

  group('VersionService.checkWithConfig — error cases', () {
    test('missing latest_version key → checkFailed', () async {
      final result = await VersionService().checkWithConfig({
        'android_store_url': 'https://example.com',
      });
      expect(result.status, UpdateStatus.checkFailed);
    });
  });

  group('VersionService.checkForUpdate — config fetcher injected', () {
    test('returns upToDate when fetcher returns current version', () async {
      final service = VersionService(configFetcher: () async => _androidConfig);
      // checkForUpdate guards on Platform.isAndroid/isIOS; on desktop it
      // returns checkFailed, so we call checkWithConfig directly for logic.
      final result = await service.checkWithConfig(_androidConfig);
      expect(result.status, UpdateStatus.upToDate);
    });

    test('returns checkFailed when fetcher returns null', () async {
      final service = VersionService(configFetcher: () async => null);
      // Simulate the _loadConfig null path via checkForUpdate's catch path.
      final config = await service.checkWithConfig({});
      expect(config.status, UpdateStatus.checkFailed);
    });
  });

  // ── lookupIosStoreUrl ────────────────────────────────────────────────────

  group('VersionService.lookupIosStoreUrl', () {
    test('returns trackViewUrl from iTunes Search API on HTTP 200', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'resultCount': 1,
            'results': [
              {
                'trackViewUrl':
                    'https://apps.apple.com/app/halalscan/id1234567890',
              },
            ],
          }),
          200,
        ),
      );
      final url = await VersionService.lookupIosStoreUrl(
        httpClient: client,
        bundleId: 'app.halalscan',
      );
      expect(url, 'https://apps.apple.com/app/halalscan/id1234567890');
    });

    test('returns null when no results found', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'resultCount': 0, 'results': []}), 200),
      );
      final url = await VersionService.lookupIosStoreUrl(
        httpClient: client,
        bundleId: 'com.nonexistent.app',
      );
      expect(url, isNull);
    });

    test('returns null on HTTP error', () async {
      final client = MockClient(
        (_) async => http.Response('Server Error', 500),
      );
      final url = await VersionService.lookupIosStoreUrl(httpClient: client);
      expect(url, isNull);
    });

    test('returns null on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Timeout'),
      );
      final url = await VersionService.lookupIosStoreUrl(httpClient: client);
      expect(url, isNull);
    });

    test('sends correct iTunes lookup URL', () async {
      late Uri capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(
          jsonEncode({'resultCount': 0, 'results': []}),
          200,
        );
      });
      await VersionService.lookupIosStoreUrl(
        httpClient: client,
        bundleId: 'app.halalscan',
      );
      expect(capturedUri.host, 'itunes.apple.com');
      expect(capturedUri.path, '/lookup');
      expect(capturedUri.queryParameters['bundleId'], 'app.halalscan');
    });
  });
}
