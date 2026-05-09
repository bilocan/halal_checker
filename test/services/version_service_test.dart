import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:halal_checker/services/version_service.dart';

String _itunesResponse(String version) => jsonEncode({
  'resultCount': 1,
  'results': [
    {
      'version': version,
      'trackViewUrl': 'https://apps.apple.com/app/idapp.halalscan',
    },
  ],
});

const String _playStorePageWithVersion =
    '..."softwareVersion":"2.0.0"...rest of page content';

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
    test('returns false when versions are equal', () {
      expect(VersionService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    });

    test('returns true when store major is higher', () {
      expect(VersionService.isNewerVersion('2.0.0', '1.0.0'), isTrue);
    });

    test('returns true when store minor is higher', () {
      expect(VersionService.isNewerVersion('1.1.0', '1.0.0'), isTrue);
    });

    test('returns true when store patch is higher', () {
      expect(VersionService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
    });

    test('returns false when installed is newer', () {
      expect(VersionService.isNewerVersion('1.0.0', '1.1.0'), isFalse);
    });

    test('handles missing patch segment gracefully', () {
      expect(VersionService.isNewerVersion('1.1', '1.0.0'), isTrue);
    });
  });

  group('VersionService iOS — store version matches installed (1.0.0)', () {
    test('status is upToDate', () async {
      final client = MockClient(
        (_) async => http.Response(_itunesResponse('1.0.0'), 200),
      );
      final result = await VersionService(httpClient: client).checkIOS();
      expect(result.status, UpdateStatus.upToDate);
    });

    test('storeVersion is populated', () async {
      final client = MockClient(
        (_) async => http.Response(_itunesResponse('1.0.0'), 200),
      );
      final result = await VersionService(httpClient: client).checkIOS();
      expect(result.storeVersion, '1.0.0');
    });

    test('storeUrl is populated', () async {
      final client = MockClient(
        (_) async => http.Response(_itunesResponse('1.0.0'), 200),
      );
      final result = await VersionService(httpClient: client).checkIOS();
      expect(result.storeUrl, isNotNull);
    });
  });

  group('VersionService iOS — update available on store (2.0.0 vs 1.0.0)', () {
    test('status is updateAvailable', () async {
      final client = MockClient(
        (_) async => http.Response(_itunesResponse('2.0.0'), 200),
      );
      final result = await VersionService(httpClient: client).checkIOS();
      expect(result.status, UpdateStatus.updateAvailable);
    });

    test('storeVersion reflects the newer store version', () async {
      final client = MockClient(
        (_) async => http.Response(_itunesResponse('2.0.0'), 200),
      );
      final result = await VersionService(httpClient: client).checkIOS();
      expect(result.storeVersion, '2.0.0');
    });
  });

  group('VersionService iOS — error cases', () {
    test('returns checkFailed on HTTP 500', () async {
      final client = MockClient((_) async => http.Response('', 500));
      final result = await VersionService(httpClient: client).checkIOS();
      expect(result.status, UpdateStatus.checkFailed);
    });

    test('returns checkFailed when results list is empty', () async {
      final client = MockClient(
        (_) async =>
            http.Response(jsonEncode({'resultCount': 0, 'results': []}), 200),
      );
      final result = await VersionService(httpClient: client).checkIOS();
      expect(result.status, UpdateStatus.checkFailed);
    });
  });

  group('VersionService Android — Play Store version scraping', () {
    test(
      'returns updateAvailable when Play Store page contains newer version',
      () async {
        final client = MockClient(
          (_) async => http.Response(_playStorePageWithVersion, 200),
        );
        final result = await VersionService(httpClient: client).checkAndroid();
        expect(result.status, UpdateStatus.updateAvailable);
        expect(result.storeVersion, '2.0.0');
      },
    );

    test(
      'returns checkFailed when Play Store page returns HTTP error',
      () async {
        final client = MockClient((_) async => http.Response('', 500));
        final result = await VersionService(httpClient: client).checkAndroid();
        expect(result.status, UpdateStatus.checkFailed);
      },
    );

    test(
      'returns checkFailed when page contains no softwareVersion field',
      () async {
        final client = MockClient(
          (_) async => http.Response('<html>no version here</html>', 200),
        );
        final result = await VersionService(httpClient: client).checkAndroid();
        expect(result.status, UpdateStatus.checkFailed);
      },
    );
  });
}
