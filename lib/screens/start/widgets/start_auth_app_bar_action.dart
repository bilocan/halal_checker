import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../../../localization/app_localizations.dart';
import '../../../localization/profile_role_label.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../widgets/change_username_sheet.dart';
import '../../../widgets/sign_in_sheet.dart';
import '../../my_contributions_screen.dart';

/// App-bar auth control: sign-in button or signed-in account menu.
class StartAuthAppBarAction extends StatefulWidget {
  const StartAuthAppBarAction({super.key});

  @override
  State<StartAuthAppBarAction> createState() => _StartAuthAppBarActionState();
}

class _StartAuthAppBarActionState extends State<StartAuthAppBarAction> {
  UserProfile? _profile;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (AuthService.currentUser == null) {
      if (mounted) setState(() => _profile = null);
      return;
    }
    setState(() => _loadingProfile = true);
    final profile = await ProfileService.fetchProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loadingProfile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = AuthService.currentUser;
        if (user == null) {
          if (_profile != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _profile = null);
            });
          }
          return IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: AppLocalizations.of(context).signIn,
            onPressed: () => showStartSignInSheet(context),
          );
        }
        if (!_loadingProfile && _profile == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
        }
        final avatarUrl = _profile?.avatarUrl ?? AuthService.avatarUrl;
        final displayLabel = _profile != null && _profile!.username.isNotEmpty
            ? _profile!.username
            : (AuthService.displayName ??
                  user.email ??
                  AppLocalizations.of(context).signedIn);
        return PopupMenuButton<String>(
          offset: const Offset(0, 40),
          onSelected: (value) async {
            if (value == 'contributions') {
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyContributionsScreen(),
                ),
              );
              return;
            }
            if (value == 'username') {
              final updated = await showChangeUsernameSheet(context);
              if (updated == true && mounted) await _loadProfile();
              return;
            }
            if (value == 'signout') {
              await AuthService.signOut();
              if (mounted) setState(() => _profile = null);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_profile != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        profileRoleLine(loc, _profile!.role),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'contributions',
                child: Row(
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(loc.myContributions),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'username',
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(loc.changeUsername),
                  ],
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
