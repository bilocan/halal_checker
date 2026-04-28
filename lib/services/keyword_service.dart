import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class KeywordService {
  Future<List<Map<String, dynamic>>> fetchCustomKeywords() async {
    if (!AppConfig.hasSupabase) return [];
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConfig.supabaseUrl}/rest/v1/keywords'
              '?select=canonical,reason,category,variants',
            ),
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            },
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
    if (!AppConfig.hasSupabase) return false;
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.supabaseUrl}/rest/v1/keyword_suggestions'),
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
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
