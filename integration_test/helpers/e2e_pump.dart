import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/integration_test_keys.dart';
import 'package:halal_checker/screens/result_screen.dart';
import 'package:integration_test/integration_test.dart';

IntegrationTestWidgetsFlutterBinding get _binding =>
    IntegrationTestWidgetsFlutterBinding.instance;

/// Pumps until [finder] matches or [timeout] elapses.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 90),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await _binding.pump();
    await Future<void>.delayed(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out after ${timeout.inSeconds}s waiting for $finder');
}

/// Pumps until [finder] has no matches.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await _binding.pump();
    await Future<void>.delayed(step);
    if (finder.evaluate().isEmpty) return;
  }
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for $finder to disappear',
  );
}

/// Result route is open (lookup finished and [ResultScreen] was pushed).
Future<void> pumpUntilResultScreen(WidgetTester tester) async {
  await pumpUntilFound(
    tester,
    _resultScreenFinder,
    timeout: const Duration(seconds: 120),
  );
}

/// Result → scanner → start home tab ([IntegrationTestKeys.startScan]).
Future<void> pumpUntilStartScan(WidgetTester tester) async {
  final startScan = find.byKey(IntegrationTestKeys.startScan);
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    if (startScan.evaluate().isNotEmpty) return;

    final resultHome = find.byKey(IntegrationTestKeys.resultHome);
    if (resultHome.evaluate().isNotEmpty) {
      await tester.tap(resultHome, warnIfMissed: false);
    } else {
      final scannerBack = find.byKey(IntegrationTestKeys.scannerBack);
      if (scannerBack.evaluate().isNotEmpty) {
        await tester.tap(scannerBack, warnIfMissed: false);
      } else {
        await tester.pageBack();
      }
    }
    await _binding.pump();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  fail(
    'Timed out returning to start screen (expected ${IntegrationTestKeys.startScan})',
  );
}

final Finder _resultScreenFinder = find.byWidgetPredicate((widget) {
  if (widget is ResultScreen) return true;
  final key = widget.key;
  if (key == null) return false;
  if (key == IntegrationTestKeys.productNotFound ||
      key == IntegrationTestKeys.resultHome) {
    return true;
  }
  if (key is ValueKey) {
    final v = key.value;
    if (v is String && v.startsWith('e2e-result-')) return true;
  }
  return false;
}, description: 'ResultScreen or e2e result marker');

/// If the expected result key is missing, fail with the outcome actually shown.
void assertExpectedResultVisible(WidgetTester tester, String expected) {
  if (expected == 'not_found') {
    expect(find.byKey(IntegrationTestKeys.productNotFound), findsOneWidget);
    return;
  }

  if (expected == 'unknown') {
    expect(
      find.byKey(IntegrationTestKeys.resultStatus('unknown')),
      findsOneWidget,
    );
    return;
  }

  final expectedFinder = find.byKey(IntegrationTestKeys.resultStatus(expected));
  if (expectedFinder.evaluate().isNotEmpty) {
    expect(expectedFinder, findsOneWidget);
    return;
  }

  for (final outcome in ['halal', 'haram', 'unknown']) {
    if (outcome == expected) continue;
    if (find
        .byKey(IntegrationTestKeys.resultStatus(outcome))
        .evaluate()
        .isNotEmpty) {
      fail(
        'Expected e2e-result-$expected but UI shows e2e-result-$outcome '
        '(live lookup verdict may differ from test/barcodes_e2e.txt)',
      );
    }
  }
  if (find.byKey(IntegrationTestKeys.productNotFound).evaluate().isNotEmpty) {
    fail(
      'Expected e2e-result-$expected but product-not-found is shown '
      '(use expected: not_found in barcodes_e2e.txt)',
    );
  }
  if (find
      .byKey(IntegrationTestKeys.resultStatus('unknown'))
      .evaluate()
      .isNotEmpty) {
    fail(
      'Expected e2e-result-$expected but inconclusive (unknown) banner is shown '
      '(use expected: unknown in barcodes_e2e.txt)',
    );
  }
  fail('Expected e2e-result-$expected but no result UI marker was found');
}
