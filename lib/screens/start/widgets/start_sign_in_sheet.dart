import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../localization/app_localizations.dart';
import '../../../services/auth_service.dart';

/// Sign-in bottom sheet from the start screen app bar (Google + Apple on iOS).
Future<void> showStartSignInSheet(BuildContext context) async {
  final loc = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.signIn,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (Platform.isIOS) ...[
              SignInWithAppleButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  signInWithApple(context);
                },
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                signInWithGoogle(context);
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Future<void> signInWithApple(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final loc = AppLocalizations.of(context);
  try {
    final success = await AuthService.signInWithApple();
    if (!context.mounted) return;
    if (!success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.signInFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(loc.signInFailed)));
  }
}

Future<void> signInWithGoogle(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final loc = AppLocalizations.of(context);
  try {
    final success = await AuthService.signInWithGoogle();
    if (!context.mounted) return;
    if (!success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(loc.signInFailed),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(loc.signInFailed)));
  }
}

Future<void> confirmDeleteAccount(BuildContext context) async {
  final loc = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(loc.deleteAccountTitle),
      content: Text(loc.deleteAccountConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(loc.deleteAccount),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final success = await AuthService.deleteAccount();
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        success ? loc.deleteAccountSuccess : loc.deleteAccountFailed,
      ),
    ),
  );
}
