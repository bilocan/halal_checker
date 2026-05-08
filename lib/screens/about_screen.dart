import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../services/version_service.dart';
import '../widgets/halal_scan_logo.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _checkingUpdate = false;
  StoreVersionInfo? _storeInfo;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
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

  Future<void> _checkForUpdate() async {
    setState(() {
      _checkingUpdate = true;
      _checked = false;
    });
    try {
      final info = await VersionService.checkForUpdate();
      if (!mounted) return;
      setState(() => _storeInfo = info);
    } finally {
      if (mounted) {
        setState(() {
          _checkingUpdate = false;
          _checked = true;
        });
      }
    }
  }

  Future<void> _performUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      await VersionService.performUpdate(storeUrl: _storeInfo?.storeUrl);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  String _storeVersionLabel(AppLocalizations loc, bool updateAvailable) {
    final info = _storeInfo!;
    if (info.status == UpdateStatus.checkFailed) return '—';
    // iOS: we have the real version string from iTunes
    if (info.storeVersion != null) return 'v${info.storeVersion}';
    // Android: in_app_update gives no version string, only availability
    return updateAvailable ? loc.updateAvailable : 'v$_version';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final updateAvailable = _storeInfo?.status == UpdateStatus.updateAvailable;
    final isSupported = Platform.isAndroid || Platform.isIOS;

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
                const SizedBox(height: 12),
                _buildVersionTable(loc, updateAvailable),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (isSupported)
            ElevatedButton.icon(
              onPressed: _checkingUpdate
                  ? null
                  : (updateAvailable ? _performUpdate : _checkForUpdate),
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
              label: Text(
                updateAvailable ? loc.updateNow : loc.checkForUpdates,
              ),
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
        ],
      ),
    );
  }

  Widget _buildVersionTable(AppLocalizations loc, bool updateAvailable) {
    return DefaultTextStyle(
      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 4),
                child: Text('${loc.installed}:'),
              ),
              Text(
                _version.isNotEmpty ? 'v$_version (build $_buildNumber)' : '—',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_checked && _storeInfo != null)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text('${loc.store}:'),
                ),
                Text(
                  _storeVersionLabel(loc, updateAvailable),
                  style: TextStyle(
                    color: _storeInfo!.status == UpdateStatus.checkFailed
                        ? Colors.grey.shade400
                        : updateAvailable
                        ? kGreenDark
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
