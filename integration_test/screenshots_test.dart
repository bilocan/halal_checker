import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:halal_checker/main.dart' as app;
import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/screens/result_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Store screenshots', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // 01 — Start screen (scan history + main actions visible)
    await binding.takeScreenshot('01_start');

    // 02 — Scanner screen
    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('02_scanner');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 03 — Halal directory
    await tester.tap(find.byIcon(Icons.store));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await binding.takeScreenshot('03_directory');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 04 — Result: halal product
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          product: _halalProduct,
          barcode: _halalProduct.barcode,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04_result_halal');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 05 — Result: haram product
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          product: _haramProduct,
          barcode: _haramProduct.barcode,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05_result_haram');
  });
}

final _halalProduct = Product(
  barcode: '3068320114094',
  name: 'Evian Natural Mineral Water 1.5L',
  ingredients: ['Natural mineral water'],
  isHalal: true,
  haramIngredients: [],
  suspiciousIngredients: [],
  ingredientWarnings: {},
  labels: ['en:halal', 'en:mineral-water'],
  explanation:
      'This product contains only natural mineral water. No haram or suspicious ingredients detected.',
  analyzedByAI: true,
  analysisMethod: 'ai',
);

final _haramProduct = Product(
  barcode: '0037600000871',
  name: 'Spam Classic',
  ingredients: [
    'Pork with Ham',
    'Salt',
    'Water',
    'Modified Potato Starch',
    'Sugar',
    'Sodium Nitrite',
  ],
  isHalal: false,
  haramIngredients: ['Pork with Ham'],
  suspiciousIngredients: [],
  ingredientWarnings: {'Pork with Ham': 'Contains pork — haram'},
  labels: [],
  explanation:
      'This product contains pork (Pork with Ham), which is haram. Do not consume.',
  analyzedByAI: true,
  analysisMethod: 'ai',
);
