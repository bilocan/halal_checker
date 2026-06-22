import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../constants/ingredient_guides.dart';
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

  /// All DB slug card copy keyed by slug.
  Future<Map<String, IngredientGuideCopy>> fetchSlugMetadata() async {
    if (!_hasSupabase) return {};
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/ingredient_guide_slug_metadata'
              '?select=slug,title_en,description_en,title_de,description_de,title_tr,description_tr',
            ),
            headers: _readHeaders,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return {};
      final rows = List<Map<String, dynamic>>.from(
        json.decode(response.body) as List,
      );
      final out = <String, IngredientGuideCopy>{};
      for (final row in rows) {
        final copy = _parseSlugMetadataRow(row);
        if (copy != null) out[row['slug'] as String] = copy;
      }
      return out;
    } catch (e, st) {
      debugPrint('[IngredientGuideLinkService] fetchSlugMetadata: $e\n$st');
      return {};
    }
  }

  /// Upserts card copy for [slug]. [descriptionEn] required; [titleEn] defaults when empty.
  Future<bool> upsertSlugMetadata({
    required String slug,
    required String descriptionEn,
    String? titleEn,
    String? descriptionDe,
    String? descriptionTr,
    String? titleDe,
    String? titleTr,
  }) async {
    if (!_hasSupabase || AuthService.currentUser == null) return false;
    final s = slug.trim().toLowerCase();
    final descEn = descriptionEn.trim();
    if (s.isEmpty || descEn.isEmpty) return false;

    final title = (titleEn ?? IngredientGuides.fallbackTitleForSlug(s)).trim();
    if (title.isEmpty) return false;

    try {
      final body = <String, dynamic>{
        'slug': s,
        'title_en': title,
        'description_en': descEn,
        if (titleDe?.trim().isNotEmpty == true) 'title_de': titleDe!.trim(),
        if (descriptionDe?.trim().isNotEmpty == true)
          'description_de': descriptionDe!.trim(),
        if (titleTr?.trim().isNotEmpty == true) 'title_tr': titleTr!.trim(),
        if (descriptionTr?.trim().isNotEmpty == true)
          'description_tr': descriptionTr!.trim(),
      };
      final response = await _client
          .post(
            Uri.parse('$_supabaseUrl/rest/v1/ingredient_guide_slug_metadata'),
            headers: {
              ..._adminHeaders,
              'Prefer': 'resolution=merge-duplicates,return=minimal',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e, st) {
      debugPrint('[IngredientGuideLinkService] upsertSlugMetadata: $e\n$st');
      return false;
    }
  }

  IngredientGuideCopy? _parseSlugMetadataRow(Map<String, dynamic> row) {
    final titleEn = (row['title_en'] as String?)?.trim() ?? '';
    if (titleEn.isEmpty) return null;
    return IngredientGuideCopy(
      titleEn: titleEn,
      descriptionEn: (row['description_en'] as String?)?.trim() ?? '',
      titleDe: _optionalString(row['title_de']),
      descriptionDe: _optionalString(row['description_de']),
      titleTr: _optionalString(row['title_tr']),
      descriptionTr: _optionalString(row['description_tr']),
    );
  }

  String? _optionalString(dynamic value) {
    if (value is! String) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
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
