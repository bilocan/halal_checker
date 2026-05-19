import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class AuthService {
  static const _sessionKey = 'supabase_session_active';
  static bool _initialized = false;
  static bool _supabaseAvailable = AppConfig.hasSupabase;
  static User? _currentUserOverride;

  static final _authController = StreamController<AuthState>.broadcast();

  /// Always-available stream — widgets subscribe once and receive events
  /// whenever Supabase eventually initializes and emits auth state changes.
  static Stream<AuthState> get authStateChanges => _authController.stream;

  @visibleForTesting
  static void setCurrentUserForTesting(User? user) =>
      _currentUserOverride = user;

  @visibleForTesting
  static void enableForTesting() => _supabaseAvailable = true;

  @visibleForTesting
  static void resetForTesting() {
    _currentUserOverride = null;
    _supabaseAvailable = AppConfig.hasSupabase;
    _initialized = false;
  }

  /// Call once from main() — initializes Supabase only if the user previously
  /// signed in and has a stored session. Skipped entirely for new installs.
  static Future<void> initializeIfSessionExists() async {
    if (!_supabaseAvailable) return;
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
      Supabase.instance.client.auth.onAuthStateChange.listen((state) async {
        _authController.add(state);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
          _sessionKey,
          state.event == AuthChangeEvent.signedIn ||
              state.event == AuthChangeEvent.tokenRefreshed,
        );
      }, onError: _authController.addError);
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
        redirectTo: 'app.halalscan://callback/',
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );
      return true;
    } catch (e) {
      debugPrint('Google OAuth Sign In error: $e');
      return false;
    }
  }

  static Future<bool> signInWithApple() async {
    if (!AppConfig.hasSupabase) return false;
    if (!await _initialize()) return false;
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) return false;

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      return true;
    } catch (e) {
      debugPrint('Apple Sign In error: $e');
      return false;
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  static User? get currentUser {
    if (_currentUserOverride != null) return _currentUserOverride;
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

  /// Permanently deletes the current user's account via a server-side Edge
  /// Function (which uses the admin API). Returns true on success.
  static Future<bool> deleteAccount() async {
    if (!_initialized) return false;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'delete-account',
        method: HttpMethod.post,
      );
      if (response.status != 200) return false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sessionKey, false);
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      return false;
    }
  }

  static String? get displayName =>
      currentUser?.userMetadata?['full_name'] as String?;
  static String? get avatarUrl =>
      currentUser?.userMetadata?['avatar_url'] as String?;
}
