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

  @visibleForTesting
  static void setHttpClientForTesting(http.Client client) {
    _httpClient = client;
    _supabaseAvailable = true;
  }

  @visibleForTesting
  static void resetForTesting() {
    _httpClient = http.Client();
    _supabaseAvailable = AppConfig.hasSupabase;
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
    if (!AppConfig.hasSupabase) return [];
    try {
      // Use the foreign key constraint name for the join
      final rows = await _db
          .from('ingredient_contributions')
          .select('*, products!ingredient_contributions_barcode_fkey(name)')
          .eq('status', status)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
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
    if (!AppConfig.hasSupabase) return false;
    try {
      // First, get the contribution to extract barcode and ingredient_text
      final response = await _db
          .from('ingredient_contributions')
          .select('barcode, ingredient_text')
          .eq('id', id)
          .single();

      final barcode = response['barcode'] as String?;
      final ingredientText = response['ingredient_text'] as String?;

      // Update the contribution status
      await _db
          .from('ingredient_contributions')
          .update({'status': status})
          .eq('id', id);

      // If approved and we have ingredient text, update the product and analyze
      if (status == 'approved' && barcode != null && ingredientText != null) {
        // Parse the ingredient text into a clean ingredient list
        final ingredients = IngredientSanitizer.sanitize(ingredientText);

        debugPrint(
          '[IngredientContribution] Approved contribution $id: '
          'parsed ${ingredients.length} ingredients from text',
        );

        // Run rule-based analysis on the ingredients
        final rulesEngine = const HalalRulesEngine();
        final analysisResult = rulesEngine.analyzeIngredients(ingredients);

        // Determine halal status based on analysis
        final isHalal = analysisResult.isHalal;
        final haramList = analysisResult.haram;
        final suspiciousList = analysisResult.suspicious;
        final warnings = analysisResult.warnings;
        final explanation = analysisResult.explanation;

        debugPrint(
          '[IngredientContribution] Analysis for $barcode: '
          'isHalal=$isHalal, haram=${haramList.length}, '
          'suspicious=${suspiciousList.length}',
        );

        // Update the product with ingredients and analysis results
        if (ingredients.isNotEmpty) {
          await _db
              .from('products')
              .update({
                'ingredients': jsonEncode(ingredients),
                'is_halal': isHalal,
                'is_unknown': false,
                'haram_ingredients': jsonEncode(haramList),
                'suspicious_ingredients': jsonEncode(suspiciousList),
                'ingredient_warnings': jsonEncode(warnings),
                'explanation': explanation,
                'analyzed_by_ai': false,
                'is_managed': true,
                'fetched_at': DateTime.now().toIso8601String(),
              })
              .eq('barcode', barcode);

          debugPrint(
            '[IngredientContribution] Updated product $barcode in database: '
            'isHalal=$isHalal, ingredients=${ingredients.length}',
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('updateStatus error: $e');
      return false;
    }
  }
}
