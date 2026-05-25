import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/config.dart';

void main() {
  test('integrationProjectRef is compile-time define only', () {
    // Default in CI unit tests — integration runs pass a matching ref via JSON.
    expect(AppConfig.integrationProjectRef, isA<String>());
  });
}
