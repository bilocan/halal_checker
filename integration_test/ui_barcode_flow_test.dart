// UI E2E: full app, real ProductService, manual barcode entry — no widget mocks.
// Guide: TESTING.md (local Supabase + dart_defines.e2e.json)
//
//   .\run_ui_e2e_test.ps1
//   .\run_ui_e2e_test.ps1 -LiveLookup

// @Tags(['e2e'])

import 'package:flutter/material.dart';
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late List<E2eBarcodeEntry> entries;

  setUpAll(() async {
    final loaded = await loadE2eBarcodes(path: _barcodesFile);
    entries = loaded.where((e) => e.expected != null).toList();
    if (entries.isEmpty) {
      throw StateError('No barcodes with expected outcomes in $_barcodesFile');
    }
  });

  // SCN-001/002/003 — see test/barcodes_e2e.txt and TESTING.md UI E2E coverage.
  testWidgets('manual barcode lookup shows correct result UI', (tester) async {
    final errorWidgetBuilderBeforeTest = ErrorWidget.builder;
    addTearDown(() => ErrorWidget.builder = errorWidgetBuilderBeforeTest);

    app.main();
    await pumpUntilFound(tester, find.byKey(IntegrationTestKeys.startScan));

    for (final entry in entries) {
      await _lookupBarcode(tester, entry.barcode);
      await _assertExpectedOutcome(tester, entry.expected!);
      await _returnToStart(tester);
    }
  });
}

Future<void> _lookupBarcode(WidgetTester tester, String barcode) async {
  await tester.tap(find.byKey(IntegrationTestKeys.startScan));
  // Camera preview never "settles" — wait for manual entry instead.
  await pumpUntilFound(tester, find.byKey(IntegrationTestKeys.homeManualEntry));

  await tester.tap(find.byKey(IntegrationTestKeys.homeManualEntry));
  await pumpUntilFound(tester, find.byKey(IntegrationTestKeys.barcodeField));

  await tester.enterText(find.byKey(IntegrationTestKeys.barcodeField), barcode);
  await tester.tap(find.byKey(IntegrationTestKeys.barcodeSubmit));
  await tester.pump();
}

Future<void> _assertExpectedOutcome(
  WidgetTester tester,
  String expected,
) async {
  if (expected == 'unknown') {
    await pumpUntilFound(
      tester,
      find.byKey(IntegrationTestKeys.productNotFound),
    );
    return;
  }

  await pumpUntilFound(
    tester,
    find.byKey(IntegrationTestKeys.resultStatus(expected)),
  );
}

Future<void> _returnToStart(WidgetTester tester) async {
  final resultHome = find.byKey(IntegrationTestKeys.resultHome);
  if (resultHome.evaluate().isNotEmpty) {
    await tester.tap(resultHome);
    await tester.pump(const Duration(milliseconds: 400));
  }

  final enabledBack = find.byWidgetPredicate(
    (w) => w is BackButton && w.onPressed != null,
  );
  var safety = 0;
  while (enabledBack.evaluate().isNotEmpty && safety < 3) {
    safety++;
    await tester.tap(enabledBack.first);
    await tester.pump(const Duration(milliseconds: 400));
  }

  await pumpUntilFound(tester, find.byKey(IntegrationTestKeys.startScan));
}
