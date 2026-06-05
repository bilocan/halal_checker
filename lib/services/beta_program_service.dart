import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

typedef AppConfigFetcher = Future<String?> Function(String key);

/// Closed-test banner flag from `app_config` + local dismiss state.
/// Android only — iOS is already in App Store production.
class BetaProgramService {
  static const closedBetaBannerKey = 'closed_beta_banner';
  static const dismissPrefsKey = 'closed_beta_banner_dismissed';

  final AppConfigFetcher? _fetchConfigValue;

  BetaProgramService({AppConfigFetcher? fetchConfigValue})
    : _fetchConfigValue = fetchConfigValue;

  Future<bool> fetchBannerEnabled() async {
    if (_fetchConfigValue != null) {
      return await _fetchConfigValue(closedBetaBannerKey) == 'true';
    }
    if (!Platform.isAndroid) return false;
    if (!AppConfig.hasSupabase) return false;
    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', closedBetaBannerKey)
          .maybeSingle();
      return row?['value'] == 'true';
    } catch (e) {
      debugPrint('[BetaProgramService] fetchBannerEnabled: $e');
      return false;
    }
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
    if (await isBannerDismissed()) return false;
    return fetchBannerEnabled();
  }
}
