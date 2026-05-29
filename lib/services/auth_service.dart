import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class AuthService {
  static const _sessionKey = 'supabase_session_active';
  static const _googleScopes = ['email', 'profile'];
  static bool _initialized = false;
  static bool _googleSignInInitialized = false;
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
    _googleSignInInitialized = false;
  }

  /// Call once from main() — initializes Supabase only if the user previously
  /// signed in and has a stored session. Skipped entirely for new installs.
  /// Initializes Supabase when config is present. Does not require a signed-in
  /// user (e.g. anonymous ingredient reports).
  static Future<bool> ensureInitialized() async {
    if (!_supabaseAvailable) return false;
    return _initialize();
  }

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

    if (_supportsNativeGoogleSignIn) {
      final nativeResult = await _signInWithGoogleNative();
      if (nativeResult != null) return nativeResult;
    }

    return _signInWithGoogleOAuth();
  }

  static bool get _supportsNativeGoogleSignIn {
    if (kIsWeb || !AppConfig.hasGoogleAuth) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => AppConfig.hasGoogleIosClientId,
      _ => false,
    };
  }

  static Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleWebClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? AppConfig.googleIosClientId
          : null,
    );
    _googleSignInInitialized = true;
  }

  /// Returns `true`/`false` when native sign-in completes or is cancelled;
  /// returns `null` when browser OAuth fallback should run (e.g. no GMS).
  static Future<bool?> _signInWithGoogleNative() async {
    try {
      await _ensureGoogleSignInInitialized();

      GoogleSignInAccount? googleUser;
      final lightweightFuture = GoogleSignIn.instance
          .attemptLightweightAuthentication();
      if (lightweightFuture != null) {
        googleUser = await lightweightFuture;
      }
      googleUser ??= await GoogleSignIn.instance.authenticate();

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(
            _googleScopes,
          ) ??
          await googleUser.authorizationClient.authorizeScopes(_googleScopes);

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        debugPrint('Native Google sign-in: no ID token, using browser OAuth');
        return null;
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      if (_shouldFallbackToBrowserOAuth(e)) {
        debugPrint(
          'Native Google sign-in unavailable, using browser OAuth: $e',
        );
        return null;
      }
      debugPrint('Native Google sign-in error: $e');
      return false;
    } catch (e) {
      debugPrint('Native Google sign-in failed, using browser OAuth: $e');
      return null;
    }
  }

  static bool _shouldFallbackToBrowserOAuth(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.providerConfigurationError:
        return true;
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return defaultTargetPlatform == TargetPlatform.android;
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
        return false;
    }
  }

  static Future<bool> _signInWithGoogleOAuth() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'app.halalscan://callback/',
        // External browser on Android so Huawei devices (no GMS) can sign in.
        authScreenLaunchMode: defaultTargetPlatform == TargetPlatform.android
            ? LaunchMode.externalApplication
            : LaunchMode.inAppBrowserView,
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
    if (_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google sign out error: $e');
      }
    }
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
      await Supabase.instance.client.auth.signOut();
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
