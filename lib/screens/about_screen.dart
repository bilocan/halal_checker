import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../widgets/halal_scan_logo.dart';

class _ReleaseNote {
  final String version;
  final String date;
  final List<String> changes;

  const _ReleaseNote({
    required this.version,
    required this.date,
    required this.changes,
  });
}

const _releaseNotes = [
  _ReleaseNote(
    version: '1.0.0',
    date: 'May 2026',
    changes: [
      'Initial release',
      'Barcode scanning with halal ingredient analysis',
      'Community feedback system for products',
      'Multi-language support: English, Turkish, German',
      'Custom keyword suggestions reviewed by the team',
      'Scan history stored locally on your device',
      'Transparency panel showing every keyword we check',
    ],
  ),
];

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!mounted) return;
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).upToDate),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).upToDate),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.about),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kGreenDark, kGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const HalalScanLogo(size: 56, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'HalalScan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kGreenDark,
                  ),
                ),
                const SizedBox(height: 4),
                if (_version.isNotEmpty)
                  Text(
                    '${loc.version} $_version+$_buildNumber',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (Platform.isAndroid) ...[
            ElevatedButton.icon(
              onPressed: _checkingUpdate ? null : _checkForUpdate,
              icon: _checkingUpdate
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.system_update_outlined),
              label: Text(loc.checkForUpdates),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kGreenMid,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
          Text(
            loc.releaseNotes,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ..._releaseNotes.map(_buildReleaseNoteCard),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildReleaseNoteCard(_ReleaseNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kGreenSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGreenLight),
                  ),
                  child: Text(
                    'v${note.version}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kGreenDark,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  note.date,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...note.changes.map(
              (change) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: kGreen),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        change,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
