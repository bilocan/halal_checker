import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'auth_service.dart';
import 'keyword_normalization.dart';

/// Loads and admin-edits [ingredient_guide_links] (canonical → blog slugs).
class IngredientGuideLinkService {
  IngredientGuideLinkService({
    http.Client? client,
    bool? hasSupabase,
    String? supabaseUrl,
    String? anonKey,
  }) : _client = client ?? http.Client(),
       _hasSupabase = hasSupabase ?? AppConfig.hasSupabase,
       _supabaseUrl = supabaseUrl ?? AppConfig.supabaseUrl,
       _anonKey = anonKey ?? AppConfig.supabaseAnonKey;

  final http.Client _client;
  final bool _hasSupabase;
  final String _supabaseUrl;
  final String _anonKey;

  static String? get _jwt {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> get _readHeaders => {
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
  };

  Map<String, String> get _adminHeaders => {
    'apikey': _anonKey,
    'Authorization': 'Bearer ${_jwt ?? _anonKey}',
    'Content-Type': 'application/json',
  };

  /// All DB guide rows keyed by canonical.
  Future<Map<String, List<String>>> fetchAllByCanonical() async {
    if (!_hasSupabase) return {};
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/ingredient_guide_links'
              '?select=canonical,guide_slugs',
            ),
            headers: _readHeaders,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return {};
      final rows = List<Map<String, dynamic>>.from(
        json.decode(response.body) as List,
      );
      final out = <String, List<String>>{};
      for (final row in rows) {
        final canonical = row['canonical'] as String?;
        if (canonical == null) continue;
        final slugs = KeywordNormalization.parseGuideSlugs(row['guide_slugs']);
        if (slugs.isNotEmpty) out[canonical] = slugs;
      }
      return out;
    } catch (e, st) {
      debugPrint('[IngredientGuideLinkService] fetchAllByCanonical: $e\n$st');
      return {};
    }
  }

  /// Creates or updates guide slugs for [canonical]. Deletes the row when empty.
  Future<bool> upsertGuideLinks({
    required String canonical,
    required List<String> guideSlugs,
  }) async {
    if (!_hasSupabase || AuthService.currentUser == null) return false;
    final c = canonical.trim().toLowerCase();
    if (c.isEmpty) return false;

    final normalized = KeywordNormalization.normalizeGuideSlugsList(guideSlugs);
    try {
      if (normalized.isEmpty) {
        final response = await _client
            .delete(
              Uri.parse(
                '$_supabaseUrl/rest/v1/ingredient_guide_links'
                '?canonical=eq.${Uri.encodeComponent(c)}',
              ),
              headers: _adminHeaders,
            )
            .timeout(const Duration(seconds: 15));
        return response.statusCode == 200 ||
            response.statusCode == 204 ||
            response.statusCode == 404;
      }

      final response = await _client
          .post(
            Uri.parse('$_supabaseUrl/rest/v1/ingredient_guide_links'),
            headers: {
              ..._adminHeaders,
              'Prefer': 'resolution=merge-duplicates,return=minimal',
            },
            body: jsonEncode({'canonical': c, 'guide_slugs': normalized}),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e, st) {
      debugPrint('[IngredientGuideLinkService] upsertGuideLinks: $e\n$st');
      return false;
    }
  }
}
