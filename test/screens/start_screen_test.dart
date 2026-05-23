import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/screens/start_screen.dart';
import 'package:halal_checker/services/database_service.dart';
import '../helpers/database_test_setup.dart';
import '../helpers/stub_analysis_service.dart';
import '../helpers/test_app.dart';

const testAdminPanelKey = Key('test-admin-panel');
const testAdminPanel = SizedBox(key: testAdminPanelKey);

Future<void> pumpStartScreen(WidgetTester tester, StartScreen screen) async {
  await tester.pumpWidget(wrapWithTestApp(screen));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

StartScreen nonAdminScreen() =>
    StartScreen(analysisService: StubAnalysisService(admin: false));

StartScreen adminScreen({bool batchImport = false}) => StartScreen(
  analysisService: StubAnalysisService(admin: true, batchImport: batchImport),
  adminPanel: testAdminPanel,
);

void main() {
  setUpAll(initTestDatabase);

  setUp(clearTestScans);

  group('StartScreen', () {
    testWidgets('loads home tab for non-admin without mounting admin panel', (
      WidgetTester tester,
    ) async {
      await pumpStartScreen(tester, nonAdminScreen());

      expect(find.byKey(testAdminPanelKey, skipOffstage: false), findsNothing);
      expect(find.byIcon(Icons.home), findsWidgets);
      expect(find.byIcon(Icons.admin_panel_settings_outlined), findsNothing);

      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.items.length, 4);
    });

    testWidgets('mounts admin panel slot when user is admin', (
      WidgetTester tester,
    ) async {
      await pumpStartScreen(tester, adminScreen());

      expect(
        find.byKey(testAdminPanelKey, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);

      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.items.length, 5);
    });

    testWidgets('shows batch import when admin has batch_import operation', (
      WidgetTester tester,
    ) async {
      await pumpStartScreen(tester, adminScreen(batchImport: true));

      expect(find.text('Batch Import'), findsOneWidget);
    });

    testWidgets('hides batch import without batch_import operation', (
      WidgetTester tester,
    ) async {
      await pumpStartScreen(tester, adminScreen());

      expect(find.text('Batch Import'), findsNothing);
    });

    testWidgets('switches to About tab', (WidgetTester tester) async {
      await pumpStartScreen(tester, nonAdminScreen());

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(
        find.text('Transparent halal, powered by community.'),
        findsOneWidget,
      );
    });
  });
}
