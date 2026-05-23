import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/screens/start/widgets/start_home_tab.dart';
import 'package:halal_checker/services/database_service.dart';
import '../helpers/database_test_setup.dart';
import '../helpers/test_app.dart';

/// Lightweight [StartHomeTab] smoke test without [StartScreen] (no lazy tabs/map).
/// Scan list data paths are covered in [start_screen_scans_test] at the DB layer.
void main() {
  setUpAll(initTestDatabase);

  setUp(clearTestScans);

  testWidgets('mounts and shows empty state without full StartScreen shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(const StartHomeTab(canBatchImport: false)),
    );
    await tester.pump();
    await tester.runAsync(() => DatabaseService.instance.getRecentScans());
    await tester.pump();

    expect(find.text('No recent scans saved yet.'), findsOneWidget);
    expect(find.text('All scans'), findsOneWidget);
  });
}
