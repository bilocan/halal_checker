import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';

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
    if (!AppConfig.hasSupabase) return null;
    final rows = await Supabase.instance.client
        .from('app_config')
        .select('key, value')
        .inFilter('key', [
          'latest_version',
          'android_store_url',
          'ios_store_url',
        ]);
    if (rows.isEmpty) {
      debugPrint('[VersionService] app_config returned no rows');
      return null;
    }
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
    var url = storeUrl;
    if (url == null) {
      url = await _fetchStoreUrlFromConfig();
    }
    if (url == null && Platform.isIOS) {
      url = await _lookupIosStoreUrl();
    }
    url ??= Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=$_bundleId'
        : 'https://apps.apple.com/app/$_bundleId';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  static Future<String?> _fetchStoreUrlFromConfig() async {
    if (!AppConfig.hasSupabase) return null;
    try {
      final key = Platform.isAndroid ? 'android_store_url' : 'ios_store_url';
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', key)
          .limit(1);
      if (rows.isNotEmpty) return rows.first['value'] as String?;
    } catch (e) {
      debugPrint('[VersionService] _fetchStoreUrlFromConfig error: $e');
    }
    return null;
  }

  /// Resolve the iOS App Store URL via the iTunes Search API using the
  /// bundle identifier. This is used as a fallback when no `ios_store_url`
  /// is configured in `app_config`.
  @visibleForTesting
  static Future<String?> lookupIosStoreUrl({
    http.Client? httpClient,
    String bundleId = _bundleId,
  }) async {
    return _lookupIosStoreUrl(httpClient: httpClient, bundleId: bundleId);
  }

  static Future<String?> _lookupIosStoreUrl({
    http.Client? httpClient,
    String bundleId = _bundleId,
  }) async {
    try {
      final client = httpClient ?? http.Client();
      try {
        final response = await client
            .get(
              Uri.parse('https://itunes.apple.com/lookup?bundleId=$bundleId'),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return null;
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) return null;
        return results.first['trackViewUrl'] as String?;
      } finally {
        if (httpClient == null) client.close();
      }
    } catch (e) {
      debugPrint('[VersionService] iTunes lookup error: $e');
      return null;
    }
  }
}
