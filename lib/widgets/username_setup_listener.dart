import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'change_username_sheet.dart';

bool _promptInFlight = false;

/// After sign-in, prompts new users to confirm their public display name.
Future<void> maybePromptUsernameSetup(BuildContext context) async {
  if (_promptInFlight) return;
  if (AuthService.currentUser == null) return;
  final profile = await ProfileService.fetchProfile();
  if (profile == null || profile.usernameCustomized) return;
  if (!context.mounted) return;
  _promptInFlight = true;
  try {
    await showChangeUsernameSheet(context, isFirstLogin: true);
  } finally {
    _promptInFlight = false;
  }
}

/// Listens for [AuthChangeEvent.signedIn] and runs [maybePromptUsernameSetup].
class UsernameSetupListener extends StatefulWidget {
  final Widget child;

  const UsernameSetupListener({super.key, required this.child});

  @override
  State<UsernameSetupListener> createState() => _UsernameSetupListenerState();
}

class _UsernameSetupListenerState extends State<UsernameSetupListener> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService.authStateChanges.listen(_onAuthState);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkExistingSession(),
    );
  }

  Future<void> _checkExistingSession() async {
    if (AuthService.currentUser == null) return;
    if (!mounted) return;
    await maybePromptUsernameSetup(context);
  }

  void _onAuthState(AuthState state) {
    if (state.event != AuthChangeEvent.signedIn) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await maybePromptUsernameSetup(context);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
