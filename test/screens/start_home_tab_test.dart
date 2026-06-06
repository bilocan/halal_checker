import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:halal_checker/screens/start/widgets/start_home_tab.dart';
import 'package:halal_checker/services/beta_program_service.dart';
import 'package:halal_checker/services/database_service.dart';
import 'package:halal_checker/widgets/closed_beta_banner.dart';
import '../helpers/database_test_setup.dart';
import '../helpers/test_app.dart';

Map<String, dynamic> _sampleScan({
  String barcode = '1234567890123',
  String productName = 'Test Halal Snack',
  bool isHalal = true,
  bool isFlagged = false,
  String? notes,
  int? timestamp,
}) {
  return {
    'barcode': barcode,
    'productName': productName,
    'isHalal': isHalal,
    'isFlagged': isFlagged,
    'notes': notes,
    'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
  };
}

/// Pumps [homeTab] and waits for [StartHomeTab]'s initial scan load to finish.
Future<void> pumpStartHomeTab(
  WidgetTester tester, {
  required StartHomeTab homeTab,
}) async {
  await tester.pumpWidget(wrapWithTestApp(homeTab));
  await tester.pump();
  await tester.runAsync(() async {
    if (homeTab.loadRecentScans != null) {
      await homeTab.loadRecentScans!();
    } else {
      await DatabaseService.instance.ensureInitialized();
    }
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Lightweight [StartHomeTab] tests without [StartScreen] (no lazy tabs/map).
///
/// Populated list tests inject scan rows (often loaded from the test DB first)
/// with [StartHomeTab.enableSwipeToDelete] false — [Dismissible] also leaves
/// pending timers when combined with sqflite FFI under the test binding.
void main() {
  setUpAll(initTestDatabase);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(clearTestScans);

  testWidgets('mounts and shows empty state without full StartScreen shell', (
    WidgetTester tester,
  ) async {
    await pumpStartHomeTab(
      tester,
      homeTab: StartHomeTab(
        canBatchImport: false,
        loadRecentScans: () async => <Map<String, dynamic>>[],
      ),
    );

    expect(find.text('No recent scans saved yet.'), findsOneWidget);
    expect(find.text('All scans'), findsOneWidget);
  });

  testWidgets('shows scan rows from injected loader without Dismissible', (
    WidgetTester tester,
  ) async {
    await pumpStartHomeTab(
      tester,
      homeTab: StartHomeTab(
        canBatchImport: false,
        enableSwipeToDelete: false,
        loadRecentScans: () async => [
          _sampleScan(productName: 'Injected Snack'),
        ],
      ),
    );

    expect(find.text('Injected Snack'), findsOneWidget);
    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets('shows retry UI when loadRecentScans throws', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithTestApp(
        StartHomeTab(
          canBatchImport: false,
          loadRecentScans: () async {
            throw Exception('db failed');
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Could not load scan history.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('flagged filter hides non-flagged scans', (
    WidgetTester tester,
  ) async {
    await pumpStartHomeTab(
      tester,
      homeTab: StartHomeTab(
        canBatchImport: false,
        enableSwipeToDelete: false,
        loadRecentScans: () async => [
          _sampleScan(barcode: '1', productName: 'Plain', isFlagged: false),
          _sampleScan(barcode: '2', productName: 'Flagged', isFlagged: true),
        ],
      ),
    );

    expect(find.text('Plain'), findsOneWidget);
    expect(find.text('Flagged'), findsOneWidget);

    await tester.tap(find.text('Flagged only'));
    await tester.pump();

    expect(find.text('Plain'), findsNothing);
    expect(find.text('Flagged'), findsOneWidget);
  });

  testWidgets('shows closed beta banner when enabled and user not signed in', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStartHomeTab(
      tester,
      homeTab: StartHomeTab(
        canBatchImport: false,
        loadRecentScans: () async => <Map<String, dynamic>>[],
        betaProgramService: BetaProgramService(
          fetchConfigValue: (_) async => 'true',
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    expect(find.byType(ClosedBetaBanner), findsOneWidget);
    expect(find.text('Closed beta — help us test'), findsOneWidget);
  });
}
