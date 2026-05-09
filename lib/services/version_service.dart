import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateStatus { upToDate, updateAvailable, checkFailed }

class StoreVersionInfo {
  final UpdateStatus status;
  final String? storeVersion;
  final String? storeUrl;

  const StoreVersionInfo(this.status, {this.storeVersion, this.storeUrl});
}

typedef ConfigFetcher = Future<Map<String, String>?> Function();

class VersionService {
  static const String _bundleId = 'app.halalscan';

  final ConfigFetcher? _configFetcher;

  VersionService({ConfigFetcher? configFetcher})
    : _configFetcher = configFetcher;

  Future<StoreVersionInfo> checkForUpdate() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const StoreVersionInfo(UpdateStatus.checkFailed);
    }
    try {
      final config = await _loadConfig();
      if (config == null)
        return const StoreVersionInfo(UpdateStatus.checkFailed);
      return _evaluate(config);
    } catch (_) {
      return const StoreVersionInfo(UpdateStatus.checkFailed);
    }
  }

  // Exposed so tests can call it without platform guards.
  @visibleForTesting
  Future<StoreVersionInfo> checkWithConfig(Map<String, String> config) =>
      _evaluate(config);

  Future<StoreVersionInfo> _evaluate(Map<String, String> config) async {
    final storeVersion = config['latest_version'];
    if (storeVersion == null) {
      return const StoreVersionInfo(UpdateStatus.checkFailed);
    }
    final storeUrl = Platform.isAndroid
        ? config['android_store_url']
        : config['ios_store_url'];
    final packageInfo = await PackageInfo.fromPlatform();
    final newer = isNewerVersion(storeVersion, packageInfo.version);
    return StoreVersionInfo(
      newer ? UpdateStatus.updateAvailable : UpdateStatus.upToDate,
      storeVersion: storeVersion,
      storeUrl: storeUrl,
    );
  }

  Future<Map<String, String>?> _loadConfig() async {
    if (_configFetcher != null) return _configFetcher();
    final rows = await Supabase.instance.client
        .from('app_config')
        .select('key, value')
        .inFilter('key', [
          'latest_version',
          'android_store_url',
          'ios_store_url',
        ]);
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
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
    final url =
        storeUrl ??
        (Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=$_bundleId'
            : 'https://apps.apple.com/app/id$_bundleId');
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
