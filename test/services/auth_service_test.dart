import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/auth_service.dart';

void main() {
  // AppConfig.hasSupabase is false in tests (no --dart-define flags), so
  // all methods hit the hasSupabase guard and return their zero-value.

  group('AuthService — no Supabase config', () {
    test('currentUser returns null', () {
      expect(AuthService.currentUser, isNull);
    });

    test('displayName returns null', () {
      expect(AuthService.displayName, isNull);
    });

    test('avatarUrl returns null', () {
      expect(AuthService.avatarUrl, isNull);
    });

    test('authStateChanges emits no events on its own', () async {
      // Should not throw, just returns an empty stream
      final events = <dynamic>[];
      final sub = AuthService.authStateChanges.listen(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('signInWithGoogle returns false', () async {
      final result = await AuthService.signInWithGoogle();
      expect(result, isFalse);
    });

    test('signOut completes without error', () async {
      await expectLater(AuthService.signOut(), completes);
    });

    test('initializeIfSessionExists completes without error', () async {
      await expectLater(AuthService.initializeIfSessionExists(), completes);
    });
  });
}
