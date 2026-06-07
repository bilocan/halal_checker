import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'auth_service.dart';

/// Superadmin-only runtime flags in `app_config` (via RPC).
class AppConfigAdminService {
  static const geminiLookupEmptyOffKey = 'gemini_lookup_empty_off';
  static const closedBetaBannerKey = 'closed_beta_banner';
  static const deepAnalysisEnabledKey = 'deep_analysis_enabled';

  static bool _supabaseAvailable = AppConfig.hasSupabase;

  @visibleForTesting
  static Future<bool> Function()? fakeIsSuperAdmin;

  @visibleForTesting
  static Future<bool?> Function()? fakeFetchGeminiLookupEmptyOff;

  @visibleForTesting
  static Future<bool> Function(bool enabled)? fakeSetGeminiLookupEmptyOff;

  @visibleForTesting
  static Future<bool?> Function()? fakeFetchClosedBetaBanner;

  @visibleForTesting
  static Future<bool> Function(bool enabled)? fakeSetClosedBetaBanner;

  @visibleForTesting
  static Future<bool?> Function()? fakeFetchDeepAnalysisEnabled;

  @visibleForTesting
  static Future<bool> Function(bool enabled)? fakeSetDeepAnalysisEnabled;

  static void resetTestOverrides() {
    fakeIsSuperAdmin = null;
    fakeFetchGeminiLookupEmptyOff = null;
    fakeSetGeminiLookupEmptyOff = null;
    fakeFetchClosedBetaBanner = null;
    fakeSetClosedBetaBanner = null;
    fakeFetchDeepAnalysisEnabled = null;
    fakeSetDeepAnalysisEnabled = null;
    _supabaseAvailable = AppConfig.hasSupabase;
  }

  static Future<bool> _isSuperAdmin() async {
    if (fakeIsSuperAdmin != null) return fakeIsSuperAdmin!();
    if (!_supabaseAvailable || AuthService.currentUser == null) return false;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', AuthService.currentUser!.id)
          .maybeSingle();
      return row?['role'] == 'superadmin';
    } catch (e) {
      debugPrint('[AppConfigAdminService] isSuperAdmin failed: $e');
      return false;
    }
  }

  static Future<bool?> fetchGeminiLookupEmptyOff() async {
    if (fakeFetchGeminiLookupEmptyOff != null) {
      return fakeFetchGeminiLookupEmptyOff!();
    }
    if (!_supabaseAvailable) return null;
    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', geminiLookupEmptyOffKey)
          .maybeSingle();
      if (row == null) return false;
      return row['value'] == 'true';
    } catch (e) {
      debugPrint('[AppConfigAdminService] fetchGeminiLookupEmptyOff: $e');
      return null;
    }
  }

  static Future<bool> setGeminiLookupEmptyOff(bool enabled) async {
    if (!_supabaseAvailable && fakeSetGeminiLookupEmptyOff == null) {
      return false;
    }
    if (!await _isSuperAdmin()) return false;
    if (fakeSetGeminiLookupEmptyOff != null) {
      return fakeSetGeminiLookupEmptyOff!(enabled);
    }
    try {
      await Supabase.instance.client.rpc(
        'set_superadmin_app_config_flag',
        params: {
          'p_key': geminiLookupEmptyOffKey,
          'p_value': enabled ? 'true' : 'false',
        },
      );
      return true;
    } catch (e) {
      debugPrint('[AppConfigAdminService] setGeminiLookupEmptyOff: $e');
      return false;
    }
  }

  static Future<bool?> fetchClosedBetaBanner() async {
    if (fakeFetchClosedBetaBanner != null) {
      return fakeFetchClosedBetaBanner!();
    }
    if (!_supabaseAvailable) return null;
    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', closedBetaBannerKey)
          .maybeSingle();
      if (row == null) return false;
      return row['value'] == 'true';
    } catch (e) {
      debugPrint('[AppConfigAdminService] fetchClosedBetaBanner: $e');
      return null;
    }
  }

  static Future<bool> setClosedBetaBanner(bool enabled) async {
    if (!_supabaseAvailable && fakeSetClosedBetaBanner == null) {
      return false;
    }
    if (!await _isSuperAdmin()) return false;
    if (fakeSetClosedBetaBanner != null) {
      return fakeSetClosedBetaBanner!(enabled);
    }
    try {
      await Supabase.instance.client.rpc(
        'set_superadmin_app_config_flag',
        params: {
          'p_key': closedBetaBannerKey,
          'p_value': enabled ? 'true' : 'false',
        },
      );
      return true;
    } catch (e) {
      debugPrint('[AppConfigAdminService] setClosedBetaBanner: $e');
      return false;
    }
  }

  static Future<bool?> fetchDeepAnalysisEnabled() async {
    if (fakeFetchDeepAnalysisEnabled != null) {
      return fakeFetchDeepAnalysisEnabled!();
    }
    if (!_supabaseAvailable) return null;
    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', deepAnalysisEnabledKey)
          .maybeSingle();
      if (row == null) return false;
      return row['value'] == 'true';
    } catch (e) {
      debugPrint('[AppConfigAdminService] fetchDeepAnalysisEnabled: $e');
      return null;
    }
  }

  static Future<bool> setDeepAnalysisEnabled(bool enabled) async {
    if (!_supabaseAvailable && fakeSetDeepAnalysisEnabled == null) {
      return false;
    }
    if (!await _isSuperAdmin()) return false;
    if (fakeSetDeepAnalysisEnabled != null) {
      return fakeSetDeepAnalysisEnabled!(enabled);
    }
    try {
      await Supabase.instance.client.rpc(
        'set_superadmin_app_config_flag',
        params: {
          'p_key': deepAnalysisEnabledKey,
          'p_value': enabled ? 'true' : 'false',
        },
      );
      return true;
    } catch (e) {
      debugPrint('[AppConfigAdminService] setDeepAnalysisEnabled: $e');
      return false;
    }
  }
}
