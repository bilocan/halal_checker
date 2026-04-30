import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

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
}
