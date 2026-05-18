import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'auth_service.dart';
import 'halal_rules_engine.dart';
import 'ingredient_sanitizer.dart';

class IngredientContributionService {
  IngredientContributionService._();

  static SupabaseClient get _db => Supabase.instance.client;
  static http.Client _httpClient = http.Client();
  static bool _supabaseAvailable = AppConfig.hasSupabase;

  // ── test seams ─────────────────────────────────────────────────────────────

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(String)?
  fakeFetchContributions;
  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(int)? fakeGetContribution;
  @visibleForTesting
  static Future<void> Function(int, String)? fakeUpdateContributionStatus;
  @visibleForTesting
  static Future<void> Function(String, Map<String, dynamic>)? fakeUpdateProduct;

  @visibleForTesting
  static void enableForTesting() => _supabaseAvailable = true;

  @visibleForTesting
  static void setHttpClientForTesting(http.Client client) {
    _httpClient = client;
    _supabaseAvailable = true;
  }

  @visibleForTesting
  static void resetForTesting() {
    _httpClient = http.Client();
    _supabaseAvailable = AppConfig.hasSupabase;
    fakeFetchContributions = null;
    fakeGetContribution = null;
    fakeUpdateContributionStatus = null;
    fakeUpdateProduct = null;
  }

  /// Submit user-contributed ingredient text for a barcode.
  /// Returns true on success, false on failure.
  static Future<bool> submitIngredients({
    required String barcode,
    required String ingredientText,
  }) async {
    if (!_supabaseAvailable) return false;
    try {
      final user = AuthService.currentUser;
      final response = await _httpClient
          .post(
            Uri.parse(
              '${AppConfig.supabaseUrl}/rest/v1/ingredient_contributions',
            ),
            headers: {
              'Content-Type': 'application/json',
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'Prefer': 'return=minimal',
            },
            body: jsonEncode({
              'barcode': barcode,
              'ingredient_text': ingredientText,
              if (user != null) 'submitted_by': user.id,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Returns all contributions with [status] (default: 'pending'), newest first.
  /// Joins the products table to include the product name.
  /// Requires the foreign key constraint: ingredient_contributions_barcode_fkey
  static Future<List<Map<String, dynamic>>> getContributions({
    String status = 'pending',
  }) async {
    if (!_supabaseAvailable) return [];
    try {
      final rows = fakeFetchContributions != null
          ? await fakeFetchContributions!(status)
          : List<Map<String, dynamic>>.from(
              await _db
                      .from('ingredient_contributions')
                      .select(
                        '*, products!ingredient_contributions_barcode_fkey(name)',
                      )
                      .eq('status', status)
                      .order('created_at', ascending: false)
                  as List,
            );
      return rows;
    } catch (e) {
      debugPrint('getContributions error: $e');
      return [];
    }
  }

  /// Sets a contribution's status to 'approved' or 'rejected'.
  /// When approved, also updates the product's ingredients in the database,
  /// runs the rule machine analysis, and updates the product's halal status.
  /// Returns true on success, false on failure.
  static Future<bool> updateStatus(int id, String status) async {
    if (!_supabaseAvailable) return false;
    try {
      final response = fakeGetContribution != null
          ? await fakeGetContribution!(id)
          : Map<String, dynamic>.from(
              await _db
                      .from('ingredient_contributions')
                      .select('barcode, ingredient_text')
                      .eq('id', id)
                      .single()
                  as Map,
            );

      final barcode = response?['barcode'] as String?;
      final ingredientText = response?['ingredient_text'] as String?;

      if (fakeUpdateContributionStatus != null) {
        await fakeUpdateContributionStatus!(id, status);
      } else {
        await _db
            .from('ingredient_contributions')
            .update({'status': status})
            .eq('id', id);
      }

      if (status == 'approved' && barcode != null && ingredientText != null) {
        final ingredients = IngredientSanitizer.sanitize(ingredientText);

        if (ingredients.isNotEmpty) {
          final rulesEngine = const HalalRulesEngine();
          final analysisResult = rulesEngine.analyzeIngredients(ingredients);
          final productsData = {
            'ingredients': jsonEncode(ingredients),
            'is_managed': true,
            'fetched_at': DateTime.now().toIso8601String(),
          };
          final analysisData = {
            'barcode': barcode,
            'is_halal': analysisResult.isHalal,
            'is_unknown': false,
            'haram_ingredients': jsonEncode(analysisResult.haram),
            'suspicious_ingredients': jsonEncode(analysisResult.suspicious),
            'ingredient_warnings': jsonEncode(analysisResult.warnings),
            'explanation': analysisResult.explanation,
            'analyzed_by_ai': false,
            'analyzed_at': DateTime.now().toIso8601String(),
          };
          if (fakeUpdateProduct != null) {
            await fakeUpdateProduct!(barcode, productsData);
          } else {
            // Best-effort: the DB trigger already updated products/product_analysis
            // via SECURITY DEFINER. These writes fail silently if RLS blocks them.
            try {
              await _db
                  .from('products')
                  .update(productsData)
                  .eq('barcode', barcode);
              await _db.from('product_analysis').upsert(analysisData);
            } catch (_) {}
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('updateStatus error: $e');
      return false;
    }
  }
}
