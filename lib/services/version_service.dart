import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateStatus { upToDate, updateAvailable, checkFailed }

class StoreVersionInfo {
  final UpdateStatus status;
  final String? storeVersion;
  final String? storeUrl;

  const StoreVersionInfo(this.status, {this.storeVersion, this.storeUrl});
}

class VersionService {
  static const String _bundleId = 'app.halalscan';

  static Future<StoreVersionInfo> checkForUpdate() async {
    if (Platform.isAndroid) return _checkAndroid();
    if (Platform.isIOS) return _checkIOS();
    return const StoreVersionInfo(UpdateStatus.checkFailed);
  }

  static Future<StoreVersionInfo> _checkAndroid() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      final available =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      return StoreVersionInfo(
        available ? UpdateStatus.updateAvailable : UpdateStatus.upToDate,
      );
    } catch (_) {
      return const StoreVersionInfo(UpdateStatus.checkFailed);
    }
  }

  static Future<StoreVersionInfo> _checkIOS() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=$_bundleId',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return const StoreVersionInfo(UpdateStatus.checkFailed);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List?)?.cast<Map<String, dynamic>>();
      if (results == null || results.isEmpty) {
        return const StoreVersionInfo(UpdateStatus.checkFailed);
      }
      final storeVersion = results.first['version'] as String?;
      final storeUrl = results.first['trackViewUrl'] as String?;
      if (storeVersion == null) {
        return const StoreVersionInfo(UpdateStatus.checkFailed);
      }
      final newer = _isNewerVersion(storeVersion, packageInfo.version);
      return StoreVersionInfo(
        newer ? UpdateStatus.updateAvailable : UpdateStatus.upToDate,
        storeVersion: storeVersion,
        storeUrl: storeUrl,
      );
    } catch (_) {
      return const StoreVersionInfo(UpdateStatus.checkFailed);
    }
  }

  // Returns true if store version is strictly newer than installed.
  static bool _isNewerVersion(String store, String installed) {
    List<int> parse(String v) =>
        v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final s = parse(store);
    final i = parse(installed);
    for (var idx = 0; idx < 3; idx++) {
      final sv = idx < s.length ? s[idx] : 0;
      final iv = idx < i.length ? i[idx] : 0;
      if (sv > iv) return true;
      if (sv < iv) return false;
    }
    return false;
  }

  static Future<void> performUpdate({String? storeUrl}) async {
    if (Platform.isAndroid) {
      await InAppUpdate.performImmediateUpdate();
    } else if (Platform.isIOS && storeUrl != null) {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
