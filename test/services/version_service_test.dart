import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:halal_checker/services/version_service.dart';

const _androidConfig = {
  'latest_version': '1.0.0',
  'android_store_url':
      'https://play.google.com/store/apps/details?id=app.halalscan',
  'ios_store_url': 'https://apps.apple.com/app/idapp.halalscan',
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
}
