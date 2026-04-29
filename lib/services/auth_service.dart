import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class AuthService {
  static final _googleSignIn = GoogleSignIn(
    serverClientId: AppConfig.googleWebClientId.isNotEmpty
        ? AppConfig.googleWebClientId
        : null,
  );

  static User? get currentUser {
    if (!AppConfig.hasSupabase) return null;
    return Supabase.instance.client.auth.currentUser;
  }

  static Stream<AuthState> get authStateChanges {
    return Supabase.instance.client.auth.onAuthStateChange;
  }

  static Future<bool> signInWithGoogle() async {
    if (!AppConfig.hasSupabase) return false;
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false;
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) return false;
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    return true;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    if (AppConfig.hasSupabase) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  static String? get displayName => currentUser?.userMetadata?['full_name'] as String?;
  static String? get avatarUrl => currentUser?.userMetadata?['avatar_url'] as String?;
}
