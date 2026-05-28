import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/integration_test_keys.dart';
import 'package:halal_checker/screens/home_screen.dart';
import 'package:halal_checker/screens/result_screen.dart';
import '../helpers/test_app.dart';
import '../helpers/test_product_fixture.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxTicks = 50,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

void main() {
  testWidgets('navigates to result when persistScan fails', (
    WidgetTester tester,
  ) async {
    const barcode = '4006381333931';
    final product = testProduct(barcode, isUnknown: false);

    await tester.pumpWidget(
      wrapWithTestApp(
        HomeScreen(
          skipScannerInit: true,
          lookupProduct: (_) async => product,
          persistScan:
              ({
                required String barcode,
                required String productName,
                required bool isHalal,
                String? verdict,
              }) async {
                throw Exception('history db failed');
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(IntegrationTestKeys.homeManualEntry));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(IntegrationTestKeys.barcodeField),
      barcode,
    );
    await tester.tap(find.byKey(IntegrationTestKeys.barcodeSubmit));
    await tester.pump();
    await pumpUntilFound(tester, find.byType(ResultScreen));

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Product $barcode'), findsWidgets);
    expect(find.text('Could not refresh product data'), findsNothing);
  });
}
