import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/beta_program_service.dart';
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
  });
}
