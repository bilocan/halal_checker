import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

  final http.Client _httpClient;

  VersionService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<StoreVersionInfo> checkForUpdate() async {
    if (Platform.isAndroid) return checkAndroid();
    if (Platform.isIOS) return checkIOS();
    return const StoreVersionInfo(UpdateStatus.checkFailed);
  }

  @visibleForTesting
  Future<StoreVersionInfo> checkAndroid() async {
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=$_bundleId';
    // market:// is handled by both Play Store and Aurora Store.
    const marketUrl = 'market://details?id=$_bundleId';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final storeVersion = await _fetchPlayStoreVersion();

      var inAppAvailable = false;
      if (!kDebugMode) {
        try {
          final info = await InAppUpdate.checkForUpdate();
          inAppAvailable =
              info.updateAvailability == UpdateAvailability.updateAvailable;
        } catch (_) {}
      }

      if (storeVersion != null) {
        final newer =
            isNewerVersion(storeVersion, packageInfo.version) || inAppAvailable;
        return StoreVersionInfo(
          newer ? UpdateStatus.updateAvailable : UpdateStatus.upToDate,
          storeVersion: storeVersion,
          storeUrl: playStoreUrl,
        );
      }

      // Play Store scrape failed — fall back to market:// so Aurora Store
      // can handle the update prompt if Play Store is not installed.
      return StoreVersionInfo(
        inAppAvailable
            ? UpdateStatus.updateAvailable
            : UpdateStatus.checkFailed,
        storeUrl: marketUrl,
      );
    } catch (_) {
      return const StoreVersionInfo(UpdateStatus.checkFailed);
    }
  }

  Future<String?> _fetchPlayStoreVersion() async {
    try {
      const url =
          'https://play.google.com/store/apps/details?id=$_bundleId&hl=en_US';
      final response = await _httpClient
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      debugPrint(
        '[VersionService] Play Store HTTP ${response.statusCode}'
        ' body_length=${response.body.length}',
      );
      if (response.statusCode != 200) return null;
      final match = RegExp(
        r'"softwareVersion":"([^"]+)"',
      ).firstMatch(response.body);
      debugPrint('[VersionService] softwareVersion match: ${match?.group(1)}');
      return match?.group(1);
    } catch (e) {
      debugPrint('[VersionService] _fetchPlayStoreVersion error: $e');
      return null;
    }
  }

  @visibleForTesting
  Future<StoreVersionInfo> checkIOS() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=$_bundleId',
      );
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 10));
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
      final newer = isNewerVersion(storeVersion, packageInfo.version);
      return StoreVersionInfo(
        newer ? UpdateStatus.updateAvailable : UpdateStatus.upToDate,
        storeVersion: storeVersion,
        storeUrl: storeUrl,
      );
    } catch (_) {
      return const StoreVersionInfo(UpdateStatus.checkFailed);
    }
  }

  @visibleForTesting
  static bool isNewerVersion(String store, String installed) {
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
      try {
        await InAppUpdate.performImmediateUpdate();
      } catch (_) {
        // Try market:// first — handled by both Play Store and Aurora Store.
        // Falls back to the HTTPS Play Store URL if neither is available.
        final candidates = [
          'market://details?id=$_bundleId',
          storeUrl ??
              'https://play.google.com/store/apps/details?id=$_bundleId',
        ];
        for (final url in candidates) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
      }
    } else if (Platform.isIOS) {
      final url = storeUrl ?? 'https://apps.apple.com/app/id$_bundleId';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
