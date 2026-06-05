import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../services/app_config_admin_service.dart';

class SystemSettingsTab extends StatefulWidget {
  const SystemSettingsTab({super.key});

  @override
  State<SystemSettingsTab> createState() => SystemSettingsTabState();
}

class SystemSettingsTabState extends State<SystemSettingsTab> {
  bool _loading = true;
  bool _saving = false;
  bool _geminiLookupEmptyOff = false;
  bool _closedBetaBanner = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final gemini = await AppConfigAdminService.fetchGeminiLookupEmptyOff();
    final betaBanner = await AppConfigAdminService.fetchClosedBetaBanner();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (gemini == null || betaBanner == null) {
        _error = AppLocalizations.of(context).systemSettingsLoadFailed;
      } else {
        _geminiLookupEmptyOff = gemini;
        _closedBetaBanner = betaBanner;
      }
    });
  }

  Future<void> _onGeminiToggle(bool value) async {
    setState(() => _saving = true);
    final ok = await AppConfigAdminService.setGeminiLookupEmptyOff(value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).systemSettingsSaveFailed),
        ),
      );
      return;
    }
    setState(() => _geminiLookupEmptyOff = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? AppLocalizations.of(context).geminiLookupEmptyOffEnabled
              : AppLocalizations.of(context).geminiLookupEmptyOffDisabled,
        ),
      ),
    );
  }

  Future<void> _onClosedBetaBannerToggle(bool value) async {
    setState(() => _saving = true);
    final ok = await AppConfigAdminService.setClosedBetaBanner(value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).systemSettingsSaveFailed),
        ),
      );
      return;
    }
    setState(() => _closedBetaBanner = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? AppLocalizations.of(context).closedBetaBannerEnabled
              : AppLocalizations.of(context).closedBetaBannerDisabled,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          loc.systemSettingsTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          loc.systemSettingsSubtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            title: Text(loc.geminiLookupEmptyOffTitle),
            subtitle: Text(loc.geminiLookupEmptyOffDescription),
            value: _geminiLookupEmptyOff,
            onChanged: _saving ? null : _onGeminiToggle,
            activeThumbColor: kGreen,
            secondary: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.auto_awesome_outlined,
                    color: Color(0xFF7C3AED),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            title: Text(loc.closedBetaBannerAdminTitle),
            subtitle: Text(loc.closedBetaBannerAdminDescription),
            value: _closedBetaBanner,
            onChanged: _saving ? null : _onClosedBetaBannerToggle,
            activeThumbColor: kGreen,
            secondary: _saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.science_outlined, color: kGreenDark),
          ),
        ),
      ],
    );
  }
}
