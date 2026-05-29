import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/profile_service.dart';

void main() {
  tearDown(ProfileService.resetForTesting);

  group('ProfileService.validateUsername', () {
    test('accepts letters, numbers, spaces, and allowed punctuation', () {
      expect(ProfileService.validateUsername('Bilal Günay'), isNull);
      expect(ProfileService.validateUsername('user_42'), isNull);
      expect(ProfileService.validateUsername("O'Brien"), isNull);
    });

    test('rejects empty and too short', () {
      expect(
        ProfileService.validateUsername(''),
        UsernameValidationError.empty,
      );
      expect(
        ProfileService.validateUsername('  '),
        UsernameValidationError.empty,
      );
      expect(
        ProfileService.validateUsername('a'),
        UsernameValidationError.tooShort,
      );
    });

    test('rejects too long', () {
      expect(
        ProfileService.validateUsername('a' * 41),
        UsernameValidationError.tooLong,
      );
    });

    test('rejects invalid characters', () {
      expect(
        ProfileService.validateUsername('bad@name'),
        UsernameValidationError.invalidCharacters,
      );
    });
  });

  group('ProfileService — no Supabase config', () {
    test('fetchProfile returns null', () async {
      expect(await ProfileService.fetchProfile(), isNull);
    });

    test('updateUsername returns failure without validation error', () async {
      final result = await ProfileService.updateUsername('Valid Name');
      expect(result.success, isFalse);
      expect(result.validationError, isNull);
    });

    test('confirmUsername returns false', () async {
      expect(await ProfileService.confirmUsername(), isFalse);
    });
  });

  group('ProfileService — testing seams', () {
    setUp(() => ProfileService.enableForTesting());

    test('fetchProfile maps row fields', () async {
      ProfileService.fakeFetchProfile = () async => {
        'username': 'alice',
        'avatar_url': 'https://example.com/a.png',
        'username_customized': false,
        'role': 'admin',
      };
      final profile = await ProfileService.fetchProfile();
      expect(profile?.username, 'alice');
      expect(profile?.avatarUrl, 'https://example.com/a.png');
      expect(profile?.usernameCustomized, isFalse);
      expect(profile?.role, 'admin');
    });

    test('fetchProfile defaults role to user when absent', () async {
      ProfileService.fakeFetchProfile = () async => {
        'username': 'bob',
        'username_customized': true,
      };
      final profile = await ProfileService.fetchProfile();
      expect(profile?.role, 'user');
    });

    test('updateUsername delegates to fake', () async {
      String? captured;
      ProfileService.fakeUpdateUsername = (name) async {
        captured = name;
        return true;
      };
      final result = await ProfileService.updateUsername('  New Name  ');
      expect(result.success, isTrue);
      expect(captured, 'New Name');
    });

    test('updateUsername returns validation error before fake', () async {
      ProfileService.fakeUpdateUsername = (_) async => true;
      final result = await ProfileService.updateUsername('x');
      expect(result.success, isFalse);
      expect(result.validationError, UsernameValidationError.tooShort);
    });

    test('confirmUsername delegates to fake', () async {
      var called = false;
      ProfileService.fakeConfirmUsername = () async {
        called = true;
        return true;
      };
      expect(await ProfileService.confirmUsername(), isTrue);
      expect(called, isTrue);
    });
  });
}
