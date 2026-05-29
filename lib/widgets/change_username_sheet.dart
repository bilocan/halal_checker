import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../localization/profile_role_label.dart';
import '../services/profile_service.dart';

/// Bottom sheet to set or confirm the public community display name.
Future<bool?> showChangeUsernameSheet(
  BuildContext context, {
  bool isFirstLogin = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: !isFirstLogin,
    enableDrag: !isFirstLogin,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ChangeUsernameSheet(isFirstLogin: isFirstLogin),
  );
}

class _ChangeUsernameSheet extends StatefulWidget {
  final bool isFirstLogin;

  const _ChangeUsernameSheet({required this.isFirstLogin});

  @override
  State<_ChangeUsernameSheet> createState() => _ChangeUsernameSheetState();
}

class _ChangeUsernameSheetState extends State<_ChangeUsernameSheet> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _errorText;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.fetchProfile();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _profile = profile;
      if (profile != null && profile.username.isNotEmpty) {
        _controller.text = profile.username;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _validationMessage(AppLocalizations loc, UsernameValidationError? e) {
    switch (e) {
      case UsernameValidationError.empty:
      case UsernameValidationError.tooShort:
      case UsernameValidationError.tooLong:
      case UsernameValidationError.invalidCharacters:
        return loc.usernameInvalid;
      case null:
        return loc.usernameSaveFailed;
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    final loc = AppLocalizations.of(context);
    final result = await ProfileService.updateUsername(_controller.text);
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.usernameSaved)));
      return;
    }
    setState(() {
      _saving = false;
      _errorText = _validationMessage(loc, result.validationError);
    });
  }

  Future<void> _keepCurrentName() async {
    setState(() => _saving = true);
    final loc = AppLocalizations.of(context);
    final ok = await ProfileService.confirmUsername();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _errorText = loc.usernameSaveFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 24),
      child: _loading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isFirstLogin
                      ? loc.firstLoginUsernameTitle
                      : loc.changeUsername,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.publicDisplayNameHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (_profile != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    profileRoleLine(loc, _profile!.role),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: loc.changeUsername,
                    errorText: _errorText,
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 40,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(loc.save),
                  ),
                ),
                if (widget.isFirstLogin) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _saving ? null : _keepCurrentName,
                    child: Text(loc.keepThisName),
                  ),
                ],
              ],
            ),
    );
  }
}
