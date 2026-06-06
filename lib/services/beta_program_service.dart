import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

typedef AppConfigFetcher = Future<String?> Function(String key);

/// Closed-test banner flag from `app_config` + local dismiss state.
/// Android only — iOS is already in App Store production.
class BetaProgramService {
  static const closedBetaBannerKey = 'closed_beta_banner';
  static const dismissPrefsKey = 'closed_beta_banner_dismissed';

  final AppConfigFetcher? _fetchConfigValue;
  final http.Client? _httpClient;
  final bool _isAndroid;
  final bool _hasSupabase;
  final String _supabaseUrl;
  final String _anonKey;

  BetaProgramService({
    AppConfigFetcher? fetchConfigValue,
    http.Client? httpClient,
    @visibleForTesting bool? isAndroid,
    @visibleForTesting bool? hasSupabase,
    @visibleForTesting String? supabaseUrl,
    @visibleForTesting String? anonKey,
  }) : _fetchConfigValue = fetchConfigValue,
       _httpClient = httpClient,
       _isAndroid = isAndroid ?? Platform.isAndroid,
       _hasSupabase = hasSupabase ?? AppConfig.hasSupabase,
       _supabaseUrl = _trimTrailingSlash(supabaseUrl ?? AppConfig.supabaseUrl),
       _anonKey = anonKey ?? AppConfig.supabaseAnonKey;

  static String _trimTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  http.Client get _client => _httpClient ?? http.Client();

  Future<bool> fetchBannerEnabled() async {
    final fetch = _fetchConfigValue;
    if (fetch != null) {
      return await fetch(closedBetaBannerKey) == 'true';
    }
    if (!_isAndroid) {
      _logDecision('skipped: not Android');
      return false;
    }
    if (!_hasSupabase) {
      _logDecision('skipped: Supabase not configured');
      return false;
    }
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/app_config'
              '?select=value'
              '&key=eq.${Uri.encodeComponent(closedBetaBannerKey)}',
            ),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        _logDecision('HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
      final rows = json.decode(response.body) as List;
      if (rows.isEmpty) {
        _logDecision('no app_config row for $closedBetaBannerKey');
        return false;
      }
      final value = (rows.first as Map<String, dynamic>)['value']?.toString();
      final enabled = value?.trim() == 'true';
      _logDecision('remote value=${value ?? 'null'} -> $enabled');
      return enabled;
    } catch (e) {
      _logDecision('error: $e');
      return false;
    }
  }

  static void _logDecision(String detail) {
    if (!kDebugMode) return;
    final host = AppConfig.hasSupabase
        ? Uri.tryParse(AppConfig.supabaseUrl)?.host ?? '?'
        : '?';
    debugPrint('[BetaProgramService] ($host) $detail');
  }

  static Future<bool> isBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dismissPrefsKey) ?? false;
  }

  static Future<void> dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dismissPrefsKey, true);
  }

  /// Whether the home banner should show (remote flag on and not dismissed locally).
  Future<bool> shouldShowHomeBanner() async {
    if (await isBannerDismissed()) {
      _logDecision('hidden: dismissed locally');
      return false;
    }
    return fetchBannerEnabled();
  }
}
