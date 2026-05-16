import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'auth_service.dart';

class IngredientContributionService {
  IngredientContributionService._();

  static SupabaseClient get _db => Supabase.instance.client;

  /// Submit user-contributed ingredient text for a barcode.
  /// Returns true on success, false on failure.
  static Future<bool> submitIngredients({
    required String barcode,
    required String ingredientText,
  }) async {
    if (!AppConfig.hasSupabase) return false;
    try {
      final user = AuthService.currentUser;
      final response = await http
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
  static Future<List<Map<String, dynamic>>> getContributions({
    String status = 'pending',
  }) async {
    if (!AppConfig.hasSupabase) return [];
    try {
      final rows = await _db
          .from('ingredient_contributions')
          .select('*, products(name)')
          .eq('status', status)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (e) {
      debugPrint('getContributions error: $e');
      return [];
    }
  }

  /// Sets a contribution's status to 'approved' or 'rejected'.
  /// Returns true on success, false on failure.
  static Future<bool> updateStatus(int id, String status) async {
    if (!AppConfig.hasSupabase) return false;
    try {
      await _db
          .from('ingredient_contributions')
          .update({'status': status})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('updateStatus error: $e');
      return false;
    }
  }
}
