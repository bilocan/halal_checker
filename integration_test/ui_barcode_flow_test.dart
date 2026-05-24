// UI E2E: full app, real ProductService, manual barcode entry — no widget mocks.
// Guide: TESTING.md (local Supabase + dart_defines.e2e.json)
//
//   .\run_ui_e2e_test.ps1
//   .\run_ui_e2e_test.ps1 -LiveLookup

// @Tags(['e2e'])

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/integration_test_keys.dart';
import 'package:halal_checker/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_barcodes.dart';
import 'helpers/e2e_pump.dart';

const _barcodesFile = String.fromEnvironment(
  'E2E_BARCODES_FILE',
  defaultValue: 'test/barcodes_e2e.txt',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Let the app paint between network/async work (default onlyPumps can stall).
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  late List<E2eBarcodeEntry> entries;

  setUpAll(() async {
    final loaded = await loadE2eBarcodes(path: _barcodesFile);
    entries = loaded.where((e) => e.expected != null).toList();
    if (entries.isEmpty) {
      throw StateError('No barcodes with expected outcomes in $_barcodesFile');
    }
  });

  // SCN-001–003 — see test/barcodes_e2e.txt and TESTING.md UI E2E coverage.
  testWidgets('manual barcode lookup shows correct result UI', (tester) async {
    app.main();
    await pumpUntilFound(tester, find.byKey(IntegrationTestKeys.startScan));

    for (final entry in entries) {
      await _lookupBarcode(tester, entry.barcode);
      await pumpUntilResultScreen(tester);
      assertExpectedResultVisible(tester, entry.expected!);
      await pumpUntilStartScan(tester);
    }
  });
}

Future<void> _lookupBarcode(WidgetTester tester, String barcode) async {
  await tester.tap(find.byKey(IntegrationTestKeys.startScan));
  await pumpUntilFound(tester, find.byKey(IntegrationTestKeys.homeManualEntry));

  await tester.tap(find.byKey(IntegrationTestKeys.homeManualEntry));
  await pumpUntilFound(tester, find.byKey(IntegrationTestKeys.barcodeField));

  await tester.enterText(find.byKey(IntegrationTestKeys.barcodeField), barcode);
  await tester.tap(find.byKey(IntegrationTestKeys.barcodeSubmit));
  // Dialog must close before we wait for the result route.
  await pumpUntilGone(tester, find.byKey(IntegrationTestKeys.barcodeField));
}
