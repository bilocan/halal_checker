import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/main.dart';

import 'helpers/database_test_setup.dart';

void main() {
  setUpAll(initTestDatabase);

  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(HalalCheckerApp(initialLocale: const Locale('en')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
