import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

typedef DeepAnalysisConfigFetcher = Future<String?> Function(String key);

/// Runtime flag: `app_config.deep_analysis_enabled` (superadmin toggle).
class DeepAnalysisFeatureService {
  DeepAnalysisFeatureService({
    DeepAnalysisConfigFetcher? fetchConfigValue,
    http.Client? httpClient,
    @visibleForTesting bool? hasSupabase,
    @visibleForTesting String? supabaseUrl,
    @visibleForTesting String? anonKey,
  }) : _fetchConfigValue = fetchConfigValue,
       _httpClient = httpClient,
       _hasSupabase = hasSupabase ?? AppConfig.hasSupabase,
       _supabaseUrl = _trimTrailingSlash(supabaseUrl ?? AppConfig.supabaseUrl),
       _anonKey = anonKey ?? AppConfig.supabaseAnonKey;

  static const deepAnalysisEnabledKey = 'deep_analysis_enabled';

  final DeepAnalysisConfigFetcher? _fetchConfigValue;
  final http.Client? _httpClient;
  final bool _hasSupabase;
  final String _supabaseUrl;
  final String _anonKey;

  static String _trimTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  http.Client get _client => _httpClient ?? http.Client();

  Future<bool> isEnabled() async {
    final fetch = _fetchConfigValue;
    if (fetch != null) {
      return await fetch(deepAnalysisEnabledKey) == 'true';
    }
    if (!_hasSupabase) return false;
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/app_config'
              '?select=value'
              '&key=eq.${Uri.encodeComponent(deepAnalysisEnabledKey)}',
            ),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      final rows = json.decode(response.body) as List;
      if (rows.isEmpty) return false;
      final value = (rows.first as Map<String, dynamic>)['value']?.toString();
      return value?.trim() == 'true';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeepAnalysisFeatureService] isEnabled error: $e');
      }
      return false;
    }
  }
}
