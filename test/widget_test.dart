import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(HalalCheckerApp(initialLocale: const Locale('en')));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
