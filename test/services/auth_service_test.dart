import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    test('ensureInitialized returns false without Supabase config', () async {
      expect(await AuthService.ensureInitialized(), isFalse);
    });

    test(
      'authStateChanges is a broadcast stream that accepts multiple listeners',
      () async {
        // A single-subscription stream throws StateError on a second listen;
        // a broadcast stream must not.
        final sub1 = AuthService.authStateChanges.listen((_) {});
        final sub2 = AuthService.authStateChanges.listen((_) {});
        await sub1.cancel();
        await sub2.cancel();
      },
    );

    test('signOut can be called repeatedly without error', () async {
      await expectLater(AuthService.signOut(), completes);
      await expectLater(AuthService.signOut(), completes);
    });

    test(
      'currentUser, displayName, and avatarUrl are all null before init',
      () {
        expect(AuthService.currentUser, isNull);
        expect(AuthService.displayName, isNull);
        expect(AuthService.avatarUrl, isNull);
      },
    );

    test('authStateChanges is a broadcast stream (isBroadcast == true)', () {
      expect(AuthService.authStateChanges.isBroadcast, isTrue);
    });
  });

  // ── currentUser override ──────────────────────────────────────────────────

  group('AuthService — currentUser override', () {
    const fakeUser = User(
      id: 'test-uid',
      appMetadata: {},
      userMetadata: {
        'full_name': 'Bilal Günay',
        'avatar_url': 'https://example.com/avatar.jpg',
      },
      aud: 'authenticated',
      createdAt: '2024-01-01T00:00:00',
      isAnonymous: false,
    );

    tearDown(AuthService.resetForTesting);

    test('setCurrentUserForTesting makes currentUser non-null', () {
      AuthService.setCurrentUserForTesting(fakeUser);
      expect(AuthService.currentUser, isNotNull);
      expect(AuthService.currentUser!.id, 'test-uid');
    });

    test('resetForTesting clears the override → currentUser null again', () {
      AuthService.setCurrentUserForTesting(fakeUser);
      AuthService.resetForTesting();
      expect(AuthService.currentUser, isNull);
    });

    test('displayName returns full_name from userMetadata', () {
      AuthService.setCurrentUserForTesting(fakeUser);
      expect(AuthService.displayName, 'Bilal Günay');
    });

    test('avatarUrl returns avatar_url from userMetadata', () {
      AuthService.setCurrentUserForTesting(fakeUser);
      expect(AuthService.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('displayName returns null when full_name absent from metadata', () {
      AuthService.setCurrentUserForTesting(
        const User(
          id: 'uid',
          appMetadata: {},
          userMetadata: {'avatar_url': 'https://example.com/avatar.jpg'},
          aud: 'authenticated',
          createdAt: '2024-01-01T00:00:00',
          isAnonymous: false,
        ),
      );
      expect(AuthService.displayName, isNull);
    });

    test('avatarUrl returns null when avatar_url absent from metadata', () {
      AuthService.setCurrentUserForTesting(
        const User(
          id: 'uid',
          appMetadata: {},
          userMetadata: {'full_name': 'Test User'},
          aud: 'authenticated',
          createdAt: '2024-01-01T00:00:00',
          isAnonymous: false,
        ),
      );
      expect(AuthService.avatarUrl, isNull);
    });

    test('displayName and avatarUrl both null when userMetadata is null', () {
      AuthService.setCurrentUserForTesting(
        const User(
          id: 'uid',
          appMetadata: {},
          userMetadata: null,
          aud: 'authenticated',
          createdAt: '2024-01-01T00:00:00',
          isAnonymous: false,
        ),
      );
      expect(AuthService.displayName, isNull);
      expect(AuthService.avatarUrl, isNull);
    });
  });

  // ── initializeIfSessionExists — SharedPreferences paths ──────────────────

  group('AuthService.initializeIfSessionExists — SharedPreferences', () {
    setUp(() {
      AuthService.enableForTesting();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(AuthService.resetForTesting);

    test(
      'session flag absent → completes without error, currentUser null',
      () async {
        // No session key set → prefs.getBool returns null → _initialize not called.
        await expectLater(AuthService.initializeIfSessionExists(), completes);
        expect(AuthService.currentUser, isNull);
      },
    );

    test(
      'session flag false → completes without error, currentUser null',
      () async {
        SharedPreferences.setMockInitialValues({
          'supabase_session_active': false,
        });
        await expectLater(AuthService.initializeIfSessionExists(), completes);
        expect(AuthService.currentUser, isNull);
      },
    );

    test(
      'session flag true → Supabase init attempted but fails gracefully',
      () async {
        // _initialize() hits the AppConfig.hasSupabase guard (false in tests)
        // and returns false — no crash, currentUser stays null.
        SharedPreferences.setMockInitialValues({
          'supabase_session_active': true,
        });
        await expectLater(AuthService.initializeIfSessionExists(), completes);
        expect(AuthService.currentUser, isNull);
      },
    );
  });
}
