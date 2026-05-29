import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../services/auth_service.dart';

/// Bottom sheet for sign-in from the start screen (Google + Apple on iOS).
Future<void> showStartSignInSheet(BuildContext context) =>
    showSignInSheet(context, gated: false);

/// Bottom sheet when an action requires authentication (e.g. result screen).
Future<void> showSignInRequiredSheet(BuildContext context) =>
    showSignInSheet(context, gated: true);

Future<void> showSignInSheet(
  BuildContext context, {
  required bool gated,
}) async {
  final loc = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(gated ? 20 : 16),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, gated ? 24 : 20, 24, gated ? 40 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (gated) ...[
              const Icon(Icons.lock_outline, size: 48, color: kGreen),
              const SizedBox(height: 16),
            ],
            Text(
              gated ? loc.signInRequired : loc.signIn,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (gated) ...[
              const SizedBox(height: 8),
              Text(
                loc.signInRequiredMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            if (!gated) ...[
              const SizedBox(height: 8),
              Text(
                loc.signInDisplayNameHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            SizedBox(height: gated ? 24 : 20),
            if (!gated && Platform.isIOS) ...[
              SignInWithAppleButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  signInWithApple(context);
                },
              ),
              const SizedBox(height: 12),
            ],
            if (gated)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: Text(loc.signInWithGoogle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    signInWithGoogle(context);
                  },
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  signInWithGoogle(context);
                },
                icon: const Icon(Icons.login),
                label: Text(loc.signInWithGoogle),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            if (!gated) const SizedBox(height: 8),
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
