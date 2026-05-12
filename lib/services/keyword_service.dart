import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'auth_service.dart';

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
              '?select=canonical,reason,category,variants',
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
  }) async {
    if (!_hasSupabase) return false;
    try {
      final response = await _client
          .post(
            Uri.parse('$_supabaseUrl/rest/v1/keyword_suggestions'),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal',
            },
            body: jsonEncode({
              'keyword': keyword.trim().toLowerCase(),
              'category': category,
              'reason': reason.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Admin CRUD for keywords table ─────────────────────────────────────────

  static String? get _jwt =>
      Supabase.instance.client.auth.currentSession?.accessToken;

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
              '?select=id,canonical,reason,category,variants,created_at'
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

  Future<bool> createRule({
    required String canonical,
    required String category,
    required String reason,
    List<String>? variants,
  }) async {
    if (!_hasSupabase || AuthService.currentUser == null) return false;
    try {
      final body = <String, dynamic>{
        'canonical': canonical.trim().toLowerCase(),
        'category': category,
        'reason': reason.trim(),
      };
      if (variants != null && variants.isNotEmpty) {
        body['variants'] = variants;
      }
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
  }) async {
    if (!_hasSupabase || AuthService.currentUser == null) return false;
    try {
      final body = <String, dynamic>{
        'canonical': canonical.trim().toLowerCase(),
        'category': category,
        'reason': reason.trim(),
      };
      if (variants != null) {
        body['variants'] = variants;
      }
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
              '?select=id,keyword,category,reason,created_at'
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
      debugPrint('[KeywordService] fetchSuggestions error: $e');
      return [];
    }
  }

  Future<bool> approveSuggestion(Map<String, dynamic> suggestion) async {
    final ok = await createRule(
      canonical: suggestion['keyword'] as String,
      category: suggestion['category'] as String,
      reason: suggestion['reason'] as String,
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
