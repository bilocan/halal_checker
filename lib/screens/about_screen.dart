import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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

  factory _ReleaseNote.fromJson(Map<String, dynamic> json) {
    final version = (json['tag_name'] as String).replaceFirst('v', '');
    final publishedAt = DateTime.tryParse(
      json['published_at'] as String? ?? '',
    );
    final date = publishedAt != null ? _formatDate(publishedAt) : '';
    final changes = _parseBody((json['body'] as String?) ?? '');
    return _ReleaseNote(version: version, date: date, changes: changes);
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  static List<String> _parseBody(String body) {
    return body
        .split('\n')
        .where((l) => l.startsWith('* ') || l.startsWith('- '))
        .map((l) {
          var text = l.replaceFirst(RegExp(r'^[*\-] '), '').trim();
          // Strip conventional commit prefix (feat:, fix:, chore:, etc.)
          text = text.replaceFirst(
            RegExp(
              r'^(feat|fix|chore|refactor|docs|style|test|ci|build)(\([^)]+\))?: ',
              caseSensitive: false,
            ),
            '',
          );
          // Strip trailing "by @user in #N" added by GitHub auto-notes
          text = text.replaceFirst(RegExp(r'\s+by @\S+.*$'), '').trim();
          return text;
        })
        .where((l) => l.isNotEmpty)
        .toList();
  }
}

List<_ReleaseNote>? _releaseNotesCache;

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _checkingUpdate = false;
  List<_ReleaseNote> _releaseNotes = [];
  AppUpdateInfo? _updateInfo;
  bool _autoCheckDone = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadReleaseNotes();
    if (Platform.isAndroid) _autoCheckForUpdate();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadReleaseNotes() async {
    if (_releaseNotesCache != null) {
      if (mounted) setState(() => _releaseNotes = _releaseNotesCache!);
      return;
    }
    try {
      final jsonString = await rootBundle.loadString(
        'assets/release_notes.json',
      );
      final data = jsonDecode(jsonString) as List<dynamic>;
      if (data.isNotEmpty) {
        _releaseNotesCache = data
            .map((e) => _ReleaseNote.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) setState(() => _releaseNotes = _releaseNotesCache!);
        return;
      }
    } catch (_) {}
    // Bundle is empty (local build) — fetch from GitHub API once
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/bilocan/halal_checker/releases',
        ),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (response.statusCode == 200) {
        _releaseNotesCache = (jsonDecode(response.body) as List<dynamic>)
            .map((e) => _ReleaseNote.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) setState(() => _releaseNotes = _releaseNotesCache!);
      }
    } catch (_) {}
  }

  Future<void> _autoCheckForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (mounted) {
        setState(() {
          _updateInfo = info;
          _autoCheckDone = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _autoCheckDone = true);
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (!mounted) return;
      setState(() {
        _updateInfo = info;
        _autoCheckDone = true;
      });
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Widget _buildVersionInfo(AppLocalizations loc) {
    final updateAvailable =
        _updateInfo?.updateAvailability == UpdateAvailability.updateAvailable;
    final latestVersion = _releaseNotes.isNotEmpty
        ? _releaseNotes.first.version
        : null;

    Widget latestValue;
    if (!_autoCheckDone) {
      latestValue = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 11,
            height: 11,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '...',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      );
    } else if (updateAvailable) {
      latestValue = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (latestVersion != null) ...[
            Text(
              'v$latestVersion',
              style: const TextStyle(
                color: kGreenDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kGreenSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGreenLight),
            ),
            child: Text(
              loc.updateAvailable,
              style: const TextStyle(
                color: kGreenDark,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else {
      latestValue = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            latestVersion != null ? 'v$latestVersion' : 'v$_version',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.check_circle_outline, color: kGreen, size: 15),
        ],
      );
    }

    return DefaultTextStyle(
      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: Text('${loc.installed}:'),
              ),
              Text(
                'v$_version (build $_buildNumber)',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (Platform.isAndroid)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('${loc.latest}:'),
                ),
                latestValue,
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(AppLocalizations loc) {
    final updateAvailable =
        _updateInfo?.updateAvailability == UpdateAvailability.updateAvailable;
    return ElevatedButton.icon(
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
          : Icon(
              updateAvailable
                  ? Icons.system_update_outlined
                  : Icons.refresh_outlined,
            ),
      label: Text(updateAvailable ? loc.updateNow : loc.checkForUpdates),
      style: ElevatedButton.styleFrom(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kGreenMid,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                if (_version.isNotEmpty) _buildVersionInfo(loc),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (Platform.isAndroid) ...[
            _buildUpdateButton(loc),
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
          if (_releaseNotes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Release notes are available in production builds.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            )
          else
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
