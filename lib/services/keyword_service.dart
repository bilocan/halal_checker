import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'auth_service.dart';
import 'keyword_normalization.dart';

class KeywordService {
  final http.Client _client;
  final bool _hasSupabase;
  final String _supabaseUrl;
  final String _anonKey;

  KeywordService({
    http.Client? client,
    bool? hasSupabase,
    String? supabaseUrl,
    String? anonKey,
  }) : _client = client ?? http.Client(),
       _hasSupabase = hasSupabase ?? AppConfig.hasSupabase,
       _supabaseUrl = supabaseUrl ?? AppConfig.supabaseUrl,
       _anonKey = anonKey ?? AppConfig.supabaseAnonKey;

  Future<List<Map<String, dynamic>>> fetchCustomKeywords() async {
    if (!_hasSupabase) return [];
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/keywords'
              '?select=canonical,reason,category,variants,translations',
            ),
            headers: {'apikey': _anonKey, 'Authorization': 'Bearer $_anonKey'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      return List<Map<String, dynamic>>.from(
        json.decode(response.body) as List,
      );
    } catch (_) {
      return [];
    }
  }

  Future<bool> suggestKeyword({
    required String keyword,
    required String category,
    required String reason,
    List<String>? variants,
  }) async {
    if (!_hasSupabase) return false;
    try {
      final canonical = keyword.trim().toLowerCase();
      final merged = KeywordNormalization.mergeVariants(
        canonical: canonical,
        variants: variants,
      );
      final extraVariants = merged.where((v) => v != canonical).toList();
      final body = <String, dynamic>{
        'keyword': canonical,
        'category': category,
        'reason': reason.trim(),
        'variants': extraVariants,
      };
      final response = await _client
          .post(
            Uri.parse('$_supabaseUrl/rest/v1/keyword_suggestions'),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Admin CRUD for keywords table ─────────────────────────────────────────

  static String? get _jwt {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get _adminHeaders => {
    'apikey': _anonKey,
    'Authorization': 'Bearer ${_jwt ?? _anonKey}',
    'Content-Type': 'application/json',
  };

  Future<List<Map<String, dynamic>>> fetchAllRules() async {
    if (!_hasSupabase) return [];
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/keywords'
              '?select=id,canonical,reason,category,variants,translations,created_at'
              '&order=created_at.desc',
            ),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer ${_jwt ?? _anonKey}',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      return List<Map<String, dynamic>>.from(
        json.decode(response.body) as List,
      );
    } catch (e) {
      debugPrint('[KeywordService] fetchAllRules error: $e');
      return [];
    }
  }

  /// Finds an approved rule whose canonical, variant, or translation matches [alias].
  Future<Map<String, dynamic>?> findRuleByAlias(String alias) async {
    final a = alias.trim().toLowerCase();
    if (a.isEmpty) return null;
    final rules = await fetchAllRules();
    for (final rule in rules) {
      if (KeywordNormalization.ruleContainsAlias(rule, a)) return rule;
    }
    return null;
  }

  Future<bool> createRule({
    required String canonical,
    required String category,
    required String reason,
    List<String>? variants,
    Map<String, String>? translations,
  }) async {
    if (!_hasSupabase || AuthService.currentUser == null) return false;
    try {
      final c = canonical.trim().toLowerCase();
      final mergedVariants = KeywordNormalization.mergeVariants(
        canonical: c,
        variants: variants,
        translations: translations,
      );
      final body = <String, dynamic>{
        'canonical': c,
        'category': category,
        'reason': reason.trim(),
        'variants': mergedVariants,
        'translations': translations ?? {},
      };
      final response = await _client
          .post(
            Uri.parse('$_supabaseUrl/rest/v1/keywords'),
            headers: {..._adminHeaders, 'Prefer': 'return=minimal'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('[KeywordService] createRule error: $e');
      return false;
    }
  }

  Future<bool> updateRule({
    required String id,
    required String canonical,
    required String category,
    required String reason,
    List<String>? variants,
    Map<String, String>? translations,
  }) async {
    if (!_hasSupabase || AuthService.currentUser == null) return false;
    try {
      final c = canonical.trim().toLowerCase();
      final body = <String, dynamic>{
        'canonical': c,
        'category': category,
        'reason': reason.trim(),
        'variants': KeywordNormalization.mergeVariants(
          canonical: c,
          variants: variants,
          translations: translations,
        ),
        'translations': translations ?? {},
      };
      final response = await _client
          .patch(
            Uri.parse('$_supabaseUrl/rest/v1/keywords?id=eq.$id'),
            headers: {..._adminHeaders, 'Prefer': 'return=minimal'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('[KeywordService] updateRule error: $e');
      return false;
    }
  }

  /// Adds [aliases] and optional [translations] to an existing rule (same concept).
  Future<bool> mergeIntoRule({
    required Map<String, dynamic> existing,
    required List<String> aliases,
    Map<String, String>? translations,
  }) async {
    final canonical = existing['canonical'] as String;
    final existingVariants = existing['variants'] is List
        ? List<String>.from(existing['variants'] as List)
        : <String>[];
    final existingTr = KeywordNormalization.parseTranslations(
      existing['translations'],
    );
    return updateRule(
      id: existing['id'] as String,
      canonical: canonical,
      category: existing['category'] as String,
      reason: existing['reason'] as String,
      variants: [...existingVariants, ...aliases],
      translations: {...existingTr, ...?translations},
    );
  }

  Future<bool> deleteRule(String id) async {
    if (!_hasSupabase || AuthService.currentUser == null) return false;
    try {
      final response = await _client
          .delete(
            Uri.parse('$_supabaseUrl/rest/v1/keywords?id=eq.$id'),
            headers: _adminHeaders,
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[KeywordService] deleteRule error: $e');
      return false;
    }
  }

  // ── Admin: keyword suggestions management ─────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchSuggestions() async {
    if (!_hasSupabase) return [];
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/keyword_suggestions'
              '?select=id,keyword,category,reason,variants,submitted_at'
              '&order=submitted_at.desc',
            ),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer ${_jwt ?? _anonKey}',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      return List<Map<String, dynamic>>.from(
        json.decode(response.body) as List,
      );
    } catch (e) {
      debugPrint('[KeywordService] fetchSuggestions error: $e');
      return [];
    }
  }

  /// Approves a suggestion. Merges into an existing rule when [mergeIntoExisting] is set.
  Future<bool> approveSuggestion(
    Map<String, dynamic> suggestion, {
    Map<String, dynamic>? mergeIntoExisting,
  }) async {
    final keyword = (suggestion['keyword'] as String).trim().toLowerCase();
    final rawVariants = suggestion['variants'];
    final extraVariants = rawVariants is List
        ? List<String>.from(rawVariants)
        : <String>[];

    if (mergeIntoExisting != null) {
      final ok = await mergeIntoRule(
        existing: mergeIntoExisting,
        aliases: [keyword, ...extraVariants],
      );
      if (!ok) return false;
      return deleteSuggestion(suggestion['id'] as String);
    }

    final ok = await createRule(
      canonical: keyword,
      category: suggestion['category'] as String,
      reason: suggestion['reason'] as String,
      variants: extraVariants,
    );
    if (!ok) return false;
    return deleteSuggestion(suggestion['id'] as String);
  }

  Future<bool> deleteSuggestion(String id) async {
    if (!_hasSupabase || AuthService.currentUser == null) return false;
    try {
      final response = await _client
          .delete(
            Uri.parse('$_supabaseUrl/rest/v1/keyword_suggestions?id=eq.$id'),
            headers: _adminHeaders,
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[KeywordService] deleteSuggestion error: $e');
      return false;
    }
  }
}
