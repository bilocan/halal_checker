import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/localization/app_localizations.dart';
import 'package:halal_checker/localization/profile_role_label.dart';

void main() {
  testWidgets('localizedProfileRole maps known roles', (tester) async {
    late AppLocalizations loc;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            loc = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(localizedProfileRole(loc, 'user'), loc.roleUser);
    expect(localizedProfileRole(loc, 'admin'), loc.roleAdmin);
    expect(localizedProfileRole(loc, 'superadmin'), loc.roleSuperadmin);
    expect(
      profileRoleLine(loc, 'moderator'),
      loc.profileRole(loc.roleModerator),
    );
  });
}
