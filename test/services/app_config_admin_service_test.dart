import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/app_config_admin_service.dart';

void main() {
  tearDown(AppConfigAdminService.resetTestOverrides);

  group('AppConfigAdminService', () {
    test('fetchGeminiLookupEmptyOff returns fake value', () async {
      AppConfigAdminService.fakeFetchGeminiLookupEmptyOff = () async => true;
      expect(await AppConfigAdminService.fetchGeminiLookupEmptyOff(), isTrue);
    });

    test('setGeminiLookupEmptyOff rejects when not superadmin', () async {
      AppConfigAdminService.fakeIsSuperAdmin = () async => false;
      AppConfigAdminService.fakeSetGeminiLookupEmptyOff = (_) async => true;
      expect(
        await AppConfigAdminService.setGeminiLookupEmptyOff(true),
        isFalse,
      );
    });

    test('setGeminiLookupEmptyOff succeeds for superadmin fake', () async {
      var saved = false;
      AppConfigAdminService.fakeIsSuperAdmin = () async => true;
      AppConfigAdminService.fakeSetGeminiLookupEmptyOff = (enabled) async {
        saved = enabled;
        return true;
      };
      expect(await AppConfigAdminService.setGeminiLookupEmptyOff(true), isTrue);
      expect(saved, isTrue);
    });

    test('fetchClosedBetaBanner returns fake value', () async {
      AppConfigAdminService.fakeFetchClosedBetaBanner = () async => true;
      expect(await AppConfigAdminService.fetchClosedBetaBanner(), isTrue);
    });

    test('setClosedBetaBanner rejects when not superadmin', () async {
      AppConfigAdminService.fakeIsSuperAdmin = () async => false;
      AppConfigAdminService.fakeSetClosedBetaBanner = (_) async => true;
      expect(await AppConfigAdminService.setClosedBetaBanner(true), isFalse);
    });

    test('setClosedBetaBanner succeeds for superadmin fake', () async {
      var saved = false;
      AppConfigAdminService.fakeIsSuperAdmin = () async => true;
      AppConfigAdminService.fakeSetClosedBetaBanner = (enabled) async {
        saved = enabled;
        return true;
      };
      expect(await AppConfigAdminService.setClosedBetaBanner(true), isTrue);
      expect(saved, isTrue);
    });

    test('fetchDeepAnalysisEnabled returns fake value', () async {
      AppConfigAdminService.fakeFetchDeepAnalysisEnabled = () async => true;
      expect(await AppConfigAdminService.fetchDeepAnalysisEnabled(), isTrue);
    });

    test('setDeepAnalysisEnabled rejects when not superadmin', () async {
      AppConfigAdminService.fakeIsSuperAdmin = () async => false;
      AppConfigAdminService.fakeSetDeepAnalysisEnabled = (_) async => true;
      expect(await AppConfigAdminService.setDeepAnalysisEnabled(true), isFalse);
    });

    test('setDeepAnalysisEnabled succeeds for superadmin fake', () async {
      var saved = false;
      AppConfigAdminService.fakeIsSuperAdmin = () async => true;
      AppConfigAdminService.fakeSetDeepAnalysisEnabled = (enabled) async {
        saved = enabled;
        return true;
      };
      expect(await AppConfigAdminService.setDeepAnalysisEnabled(true), isTrue);
      expect(saved, isTrue);
    });

    test('fetchPhotoSubmissionsAutoApprove returns fake value', () async {
      AppConfigAdminService.fakeFetchPhotoSubmissionsAutoApprove = () async =>
          true;
      expect(
        await AppConfigAdminService.fetchPhotoSubmissionsAutoApprove(),
        isTrue,
      );
    });

    test(
      'setPhotoSubmissionsAutoApprove rejects when not superadmin',
      () async {
        AppConfigAdminService.fakeIsSuperAdmin = () async => false;
        AppConfigAdminService.fakeSetPhotoSubmissionsAutoApprove = (_) async =>
            true;
        expect(
          await AppConfigAdminService.setPhotoSubmissionsAutoApprove(true),
          isFalse,
        );
      },
    );

    test(
      'setPhotoSubmissionsAutoApprove succeeds for superadmin fake',
      () async {
        var saved = false;
        AppConfigAdminService.fakeIsSuperAdmin = () async => true;
        AppConfigAdminService.fakeSetPhotoSubmissionsAutoApprove =
            (enabled) async {
              saved = enabled;
              return true;
            };
        expect(
          await AppConfigAdminService.setPhotoSubmissionsAutoApprove(true),
          isTrue,
        );
        expect(saved, isTrue);
      },
    );
  });
}
