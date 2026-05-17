import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:halal_checker/services/version_service.dart';

const _config = {
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

  // ── isNewerVersion ────────────────────────────────────────────────────────

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

    test('installed newer than store minor → false', () {
      expect(VersionService.isNewerVersion('1.0.0', '1.1.0'), isFalse);
    });

    test('installed newer than store patch → false', () {
      expect(VersionService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
    });

    test('missing patch segment treated as 0 → newer', () {
      expect(VersionService.isNewerVersion('1.1', '1.0.0'), isTrue);
    });

    test('both missing patch segment, equal → false', () {
      expect(VersionService.isNewerVersion('1.1', '1.1.0'), isFalse);
    });

    test('single-segment store newer → true', () {
      expect(VersionService.isNewerVersion('2', '1.0.0'), isTrue);
    });

    test('single-segment store older → false', () {
      expect(VersionService.isNewerVersion('1', '2.0.0'), isFalse);
    });

    test('non-numeric segment treated as 0', () {
      // '1.0.beta' → [1, 0, 0] vs [1, 0, 0] → false
      expect(VersionService.isNewerVersion('1.0.beta', '1.0.0'), isFalse);
    });

    test('4+ segment version: only first 3 compared', () {
      // '1.0.0.9' vs '1.0.0.0' → same first 3, loop stops → false
      expect(VersionService.isNewerVersion('1.0.0.9', '1.0.0.0'), isFalse);
    });

    test('all-zero versions → false', () {
      expect(VersionService.isNewerVersion('0.0.0', '0.0.0'), isFalse);
    });

    test('major equal, store minor older → false', () {
      expect(VersionService.isNewerVersion('2.0.0', '2.1.0'), isFalse);
    });
  });

  // ── StoreVersionInfo model ────────────────────────────────────────────────

  group('StoreVersionInfo', () {
    test('upToDate status with storeVersion and storeUrl', () {
      const info = StoreVersionInfo(
        UpdateStatus.upToDate,
        storeVersion: '1.0.0',
        storeUrl: 'https://example.com',
      );
      expect(info.status, UpdateStatus.upToDate);
      expect(info.storeVersion, '1.0.0');
      expect(info.storeUrl, 'https://example.com');
    });

    test('checkFailed has null storeVersion and storeUrl by default', () {
      const info = StoreVersionInfo(UpdateStatus.checkFailed);
      expect(info.status, UpdateStatus.checkFailed);
      expect(info.storeVersion, isNull);
      expect(info.storeUrl, isNull);
    });
  });

  // ── checkWithConfig ───────────────────────────────────────────────────────

  group(
    'VersionService.checkWithConfig — version matches installed (1.0.0)',
    () {
      test('status is upToDate', () async {
        final result = await VersionService().checkWithConfig(_config);
        expect(result.status, UpdateStatus.upToDate);
      });

      test('storeVersion is populated', () async {
        final result = await VersionService().checkWithConfig(_config);
        expect(result.storeVersion, '1.0.0');
      });

      test('storeUrl is populated', () async {
        final result = await VersionService().checkWithConfig(_config);
        // On desktop Platform.isAndroid is false → ios_store_url is used.
        expect(result.storeUrl, isNotNull);
      });
    },
  );

  group(
    'VersionService.checkWithConfig — update available (store 2.0.0 vs 1.0.0)',
    () {
      final config = {..._config, 'latest_version': '2.0.0'};

      test('status is updateAvailable', () async {
        final result = await VersionService().checkWithConfig(config);
        expect(result.status, UpdateStatus.updateAvailable);
      });

      test('storeVersion reflects the newer version', () async {
        final result = await VersionService().checkWithConfig(config);
        expect(result.storeVersion, '2.0.0');
      });

      test('storeUrl is populated when update available', () async {
        final result = await VersionService().checkWithConfig(config);
        expect(result.storeUrl, isNotNull);
      });
    },
  );

  group('VersionService.checkWithConfig — error cases', () {
    test('missing latest_version → checkFailed', () async {
      final result = await VersionService().checkWithConfig({
        'android_store_url': 'https://example.com',
      });
      expect(result.status, UpdateStatus.checkFailed);
    });

    test('missing latest_version → storeVersion is null', () async {
      final result = await VersionService().checkWithConfig({});
      expect(result.storeVersion, isNull);
    });

    test('empty config map → checkFailed', () async {
      final result = await VersionService().checkWithConfig({});
      expect(result.status, UpdateStatus.checkFailed);
    });
  });

  // ── checkForUpdate — platform guard on desktop ────────────────────────────

  group('VersionService.checkForUpdate — desktop (non-mobile) platform', () {
    test('returns checkFailed on desktop since no mobile platform', () async {
      // Tests run on Linux; Platform.isAndroid and Platform.isIOS are false.
      final result = await VersionService().checkForUpdate();
      expect(result.status, UpdateStatus.checkFailed);
    });

    test(
      'configFetcher is NOT called on desktop (platform guard fires first)',
      () async {
        var fetcherCalled = false;
        final service = VersionService(
          configFetcher: () async {
            fetcherCalled = true;
            return _config;
          },
        );
        await service.checkForUpdate();
        expect(fetcherCalled, isFalse);
      },
    );
  });

  // ── lookupIosStoreUrl ─────────────────────────────────────────────────────

  group('VersionService.lookupIosStoreUrl', () {
    test('returns trackViewUrl on HTTP 200 with results', () async {
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

    test('returns null when results is empty', () async {
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

    test('returns null when results key is missing from response', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'resultCount': 0}), 200),
      );
      final url = await VersionService.lookupIosStoreUrl(httpClient: client);
      expect(url, isNull);
    });

    test('returns null when trackViewUrl is null in first result', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'resultCount': 1,
            'results': [
              {'wrapperType': 'software'},
            ],
          }),
          200,
        ),
      );
      final url = await VersionService.lookupIosStoreUrl(httpClient: client);
      expect(url, isNull);
    });

    test('returns null on HTTP 404', () async {
      final client = MockClient((_) async => http.Response('Not Found', 404));
      final url = await VersionService.lookupIosStoreUrl(httpClient: client);
      expect(url, isNull);
    });

    test('returns null on HTTP 500', () async {
      final client = MockClient((_) async => http.Response('Error', 500));
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

    test('sends correct iTunes lookup URL with bundleId query param', () async {
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

    test('uses custom bundleId in lookup URL', () async {
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
        bundleId: 'com.example.myapp',
      );
      expect(capturedUri.queryParameters['bundleId'], 'com.example.myapp');
    });
  });
}
