import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/product_analysis.dart';
import 'auth_service.dart';

class AnalysisService {
  static String? get _jwt =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  // ── queue / trigger ────────────────────────────────────────────────────────

  /// Queues a product for deep analysis and returns the resulting record.
  /// If analysis already exists (and is not pending), returns it immediately.
  static Future<ProductAnalysis?> requestDeepAnalysis(String barcode) async {
    if (!AppConfig.hasSupabase || AuthService.currentUser == null) return null;
    final jwt = _jwt;
    if (jwt == null) return null;
    try {
      final res = await http
          .post(
            Uri.parse(
              '${AppConfig.supabaseUrl}/functions/v1/deep-analyze-product',
            ),
            headers: {
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'barcode': barcode}),
          )
          .timeout(const Duration(seconds: 90));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ProductAnalysis.fromJson(data['analysis'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── fetch existing ─────────────────────────────────────────────────────────

  /// Returns the current analysis record for a barcode, or null if none exists.
  static Future<ProductAnalysis?> getAnalysis(String barcode) async {
    if (!AppConfig.hasSupabase) return null;
    try {
      final row = await Supabase.instance.client
          .from('product_analyses')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();
      if (row == null) return null;
      return ProductAnalysis.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  // ── admin batch ────────────────────────────────────────────────────────────

  /// Admin-only: triggers batch AI analysis on all pending products.
  static Future<Map<String, dynamic>?> runBatch({int limit = 10}) async {
    if (!AppConfig.hasSupabase || AuthService.currentUser == null) return null;
    final jwt = _jwt;
    if (jwt == null) return null;
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.supabaseUrl}/functions/v1/batch-analyze'),
            headers: {
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'limit': limit}),
          )
          .timeout(const Duration(seconds: 300));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
