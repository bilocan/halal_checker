import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../../../localization/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/sign_in_sheet.dart';

/// App-bar auth control: sign-in button or signed-in account menu.
class StartAuthAppBarAction extends StatelessWidget {
  const StartAuthAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = AuthService.currentUser;
        if (user == null) {
          return IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppLocalizations.of(context).signIn,
            onPressed: () => showStartSignInSheet(context),
          );
        }
        final avatarUrl = AuthService.avatarUrl;
        return PopupMenuButton<String>(
          offset: const Offset(0, 40),
          onSelected: (value) async {
            if (value == 'signout') {
              await AuthService.signOut();
              return;
            }
            if (value == 'delete') {
              if (!context.mounted) return;
              await confirmDeleteAccount(context);
            }
          },
          itemBuilder: (_) {
            final loc = AppLocalizations.of(context);
            return [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  AuthService.displayName ?? user.email ?? loc.signedIn,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18),
                    const SizedBox(width: 8),
                    Text(loc.signOut),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_forever,
                      size: 18,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.deleteAccount,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ];
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: avatarUrl != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: CachedNetworkImageProvider(avatarUrl),
                  )
                : const Icon(Icons.person),
          ),
        );
      },
    );
  }
}
