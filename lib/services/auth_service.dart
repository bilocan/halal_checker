import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class AuthService {
  static const _sessionKey = 'supabase_session_active';
  static bool _initialized = false;

  static final _authController = StreamController<AuthState>.broadcast();

  /// Always-available stream — widgets subscribe once and receive events
  /// whenever Supabase eventually initializes and emits auth state changes.
  static Stream<AuthState> get authStateChanges => _authController.stream;

  /// Call once from main() — initializes Supabase only if the user previously
  /// signed in and has a stored session. Skipped entirely for new installs.
  static Future<void> initializeIfSessionExists() async {
    if (!AppConfig.hasSupabase) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_sessionKey) ?? false) {
        await _initialize();
        // Session token may have expired — clear the flag if so.
        if (_initialized && currentUser == null) {
          await prefs.setBool(_sessionKey, false);
        }
      }
    } catch (e) {
      debugPrint('Session restore failed: $e');
    }
  }

  static Future<bool> _initialize() async {
    if (_initialized) return true;
    if (!AppConfig.hasSupabase) return false;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      _initialized = true;
      Supabase.instance.client.auth.onAuthStateChange
          .listen(_authController.add, onError: _authController.addError);
      return true;
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      return false;
    }
  }

  static Future<bool> signInWithGoogle() async {
    if (!AppConfig.hasSupabase) return false;
    if (!await _initialize()) return false;
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.halal_checker.app://callback',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sessionKey, true);
      return true;
    } catch (e) {
      debugPrint('Google OAuth Sign In error: $e');
      return false;
    }
  }

  static User? get currentUser {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  static Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await Supabase.instance.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sessionKey, false);
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  static String? get displayName =>
      currentUser?.userMetadata?['full_name'] as String?;
  static String? get avatarUrl =>
      currentUser?.userMetadata?['avatar_url'] as String?;
}
