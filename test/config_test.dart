import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/config.dart';

void main() {
  // Tests run without --dart-define flags, so all String.fromEnvironment
  // values resolve to their defaultValue ('').

  group('AppConfig — no dart-define flags (test environment)', () {
    test('supabaseUrl defaults to empty string', () {
      expect(AppConfig.supabaseUrl, isEmpty);
    });

    test('supabaseAnonKey defaults to empty string', () {
      expect(AppConfig.supabaseAnonKey, isEmpty);
    });

    test('googleIosClientId defaults to empty string', () {
      expect(AppConfig.googleIosClientId, isEmpty);
    });

    test('hasGoogleIosClientId is false when iOS client ID is empty', () {
      expect(AppConfig.hasGoogleIosClientId, isFalse);
    });

    test('googleWebClientId defaults to empty string', () {
      expect(AppConfig.googleWebClientId, isEmpty);
    });

    test('hasSupabase is false when both URL and key are empty', () {
      expect(AppConfig.hasSupabase, isFalse);
    });

    test('hasGoogleAuth is false when client ID is empty', () {
      expect(AppConfig.hasGoogleAuth, isFalse);
    });
  });
}
