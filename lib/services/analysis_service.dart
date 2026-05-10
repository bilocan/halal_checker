import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/product.dart';
import '../models/product_analysis.dart';
import 'auth_service.dart';

class AnalysisService {
  final http.Client _httpClient;
  final bool _hasSupabase;
  final String _supabaseUrl;

  AnalysisService({
    http.Client? httpClient,
    @visibleForTesting bool? hasSupabase,
    @visibleForTesting String? supabaseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _hasSupabase = hasSupabase ?? AppConfig.hasSupabase,
       _supabaseUrl = supabaseUrl ?? AppConfig.supabaseUrl;

  static String? get _jwt =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  // ── queue / trigger ────────────────────────────────────────────────────────

  /// Queues a product for deep analysis and returns the resulting record.
  /// If analysis already exists (and is not pending), returns it immediately.
  ///
  /// [jwtOverride] is for testing only — bypasses the Supabase + auth guards.
  Future<ProductAnalysis?> requestDeepAnalysis(
    String barcode, {
    Product? product,
    @visibleForTesting String? jwtOverride,
  }) async {
    if (!_hasSupabase && jwtOverride == null) return null;
    final jwt = jwtOverride ?? (AuthService.currentUser == null ? null : _jwt);
    if (jwt == null) return null;
    try {
      final body = <String, dynamic>{'barcode': barcode};
      if (product != null) {
        body['productData'] = {
          'name': product.name,
          'ingredients': product.ingredients,
          'haram_ingredients': product.haramIngredients,
          'suspicious_ingredients': product.suspiciousIngredients,
        };
      }
      final res = await _httpClient
          .post(
            Uri.parse('$_supabaseUrl/functions/v1/deep-analyze-product'),
            headers: {
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
      if (res.statusCode != 200) {
        debugPrint(
          '[AnalysisService] deep-analyze-product '
          'HTTP ${res.statusCode}: ${res.body}',
        );
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ProductAnalysis.fromJson(data['analysis'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[AnalysisService] requestDeepAnalysis error: $e');
      return null;
    }
  }

  // ── admin helpers ──────────────────────────────────────────────────────────

  Future<bool> isAdmin() async {
    if (!_hasSupabase) return false;
    try {
      final uid = AuthService.currentUser?.id;
      if (uid == null) return false;
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      return row?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getAnalysisList() async {
    if (!_hasSupabase) return null;
    try {
      final rows = await Supabase.instance.client
          .from('product_analyses')
          .select('*, products(name)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return null;
    }
  }

  // ── fetch existing ─────────────────────────────────────────────────────────

  /// Returns the current analysis record for a barcode, or null if none exists.
  Future<ProductAnalysis?> getAnalysis(String barcode) async {
    if (!_hasSupabase) return null;
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
  ///
  /// [jwtOverride] is for testing only — bypasses the Supabase + auth guards.
  Future<Map<String, dynamic>?> runBatch({
    int limit = 10,
    List<String>? ids,
    @visibleForTesting String? jwtOverride,
  }) async {
    if (!_hasSupabase && jwtOverride == null) return null;
    final jwt = jwtOverride ?? (AuthService.currentUser == null ? null : _jwt);
    if (jwt == null) return null;
    try {
      final body = <String, dynamic>{'limit': limit};
      if (ids != null) body['ids'] = ids;
      final res = await _httpClient
          .post(
            Uri.parse('$_supabaseUrl/functions/v1/batch-analyze'),
            headers: {
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 300));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
