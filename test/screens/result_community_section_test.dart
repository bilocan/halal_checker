import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/localization/app_localizations.dart';
import 'package:halal_checker/screens/result/widgets/result_community_section.dart';

void main() {
  group('ResultCommunitySection', () {
    testWidgets('hides Deep Analysis when showDeepAnalysis is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return ResultCommunitySection(
                loc: loc,
                showDeepAnalysis: false,
                analysis: null,
                isRequestingAnalysis: false,
                discussionCount: 0,
                onRequestAnalysis: () {},
                onOpenAnalysis: () {},
                onOpenDiscussion: () {},
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deep Analysis'), findsNothing);
      expect(find.text('Analyse'), findsNothing);
      expect(find.text('Community Discussion'), findsOneWidget);
    });

    testWidgets('shows Deep Analysis when showDeepAnalysis is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              return ResultCommunitySection(
                loc: loc,
                showDeepAnalysis: true,
                analysis: null,
                isRequestingAnalysis: false,
                discussionCount: 0,
                onRequestAnalysis: () {},
                onOpenAnalysis: () {},
                onOpenDiscussion: () {},
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deep Analysis'), findsOneWidget);
      expect(find.text('Analyse'), findsOneWidget);
    });
  });
}
