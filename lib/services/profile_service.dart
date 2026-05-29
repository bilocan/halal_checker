import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'auth_service.dart';

class UserProfile {
  final String username;
  final String? avatarUrl;
  final bool usernameCustomized;
  final String role;

  const UserProfile({
    required this.username,
    this.avatarUrl,
    required this.usernameCustomized,
    this.role = 'user',
  });
}

enum UsernameValidationError { empty, tooShort, tooLong, invalidCharacters }

class ProfileService {
  static SupabaseClient get _db => Supabase.instance.client;

  static bool _supabaseAvailable = AppConfig.hasSupabase;

  @visibleForTesting
  static Future<Map<String, dynamic>?> Function()? fakeFetchProfile;

  @visibleForTesting
  static Future<bool> Function(String username)? fakeUpdateUsername;

  @visibleForTesting
  static Future<bool> Function()? fakeConfirmUsername;

  @visibleForTesting
  static void enableForTesting() => _supabaseAvailable = true;

  @visibleForTesting
  static void resetForTesting() {
    _supabaseAvailable = AppConfig.hasSupabase;
    fakeFetchProfile = null;
    fakeUpdateUsername = null;
    fakeConfirmUsername = null;
  }

  /// Validates a public display name (2–40 chars; letters, numbers, spaces, . _ - ').
  static UsernameValidationError? validateUsername(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return UsernameValidationError.empty;
    if (name.length < 2) return UsernameValidationError.tooShort;
    if (name.length > 40) return UsernameValidationError.tooLong;
    final valid = RegExp(r"^[\p{L}\p{N} _.\-']+$", unicode: true);
    if (!valid.hasMatch(name)) {
      return UsernameValidationError.invalidCharacters;
    }
    return null;
  }

  static Future<UserProfile?> fetchProfile() async {
    if (!_supabaseAvailable) return null;
    if (fakeFetchProfile != null) {
      final row = await fakeFetchProfile!();
      return row == null ? null : _profileFromRow(row);
    }
    if (!await AuthService.ensureInitialized()) return null;
    final uid = AuthService.currentUser?.id;
    if (uid == null) return null;
    try {
      await _ensureOwnProfile(AuthService.currentUser!);
      final row = await _db
          .from('profiles')
          .select('username, avatar_url, username_customized, role')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return null;
      return _profileFromRow(Map<String, dynamic>.from(row as Map));
    } catch (e, st) {
      debugPrint('ProfileService.fetchProfile: $e\n$st');
      return null;
    }
  }

  static UserProfile _profileFromRow(Map<String, dynamic> row) => UserProfile(
    username: (row['username'] as String? ?? '').trim(),
    avatarUrl: row['avatar_url'] as String?,
    usernameCustomized: row['username_customized'] as bool? ?? false,
    role: row['role'] as String? ?? 'user',
  );

  /// Saves a new public display name and marks it as customized.
  static Future<({bool success, UsernameValidationError? validationError})>
  updateUsername(String raw) async {
    final validation = validateUsername(raw);
    if (validation != null) {
      return (success: false, validationError: validation);
    }
    final name = raw.trim();
    if (fakeUpdateUsername != null) {
      final ok = await fakeUpdateUsername!(name);
      return (success: ok, validationError: null);
    }
    if (!_supabaseAvailable) {
      return (success: false, validationError: null);
    }
    if (!await AuthService.ensureInitialized()) {
      return (success: false, validationError: null);
    }
    final uid = AuthService.currentUser?.id;
    if (uid == null) return (success: false, validationError: null);
    try {
      await _ensureOwnProfile(AuthService.currentUser!);
      await _db
          .from('profiles')
          .update({'username': name, 'username_customized': true})
          .eq('id', uid);
      return (success: true, validationError: null);
    } catch (e, st) {
      debugPrint('ProfileService.updateUsername: $e\n$st');
      return (success: false, validationError: null);
    }
  }

  /// Accepts the current display name without changing it (first-login flow).
  static Future<bool> confirmUsername() async {
    if (fakeConfirmUsername != null) return fakeConfirmUsername!();
    if (!_supabaseAvailable) return false;
    if (!await AuthService.ensureInitialized()) return false;
    final uid = AuthService.currentUser?.id;
    if (uid == null) return false;
    try {
      await _db
          .from('profiles')
          .update({'username_customized': true})
          .eq('id', uid);
      return true;
    } catch (e, st) {
      debugPrint('ProfileService.confirmUsername: $e\n$st');
      return false;
    }
  }

  static Future<void> _ensureOwnProfile(User user) async {
    try {
      final existing = await _db
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existing != null) return;
      await _db.from('profiles').insert({
        'id': user.id,
        'username': _usernameFromUser(user),
        'avatar_url': user.userMetadata?['avatar_url'],
        'username_customized': false,
      });
    } catch (e) {
      debugPrint('ProfileService._ensureOwnProfile: $e');
    }
  }

  static String _usernameFromUser(User user) {
    final fullName = user.userMetadata?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Anonymous';
  }
}
