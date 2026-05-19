import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'auth_service.dart';

class IngredientReportService {
  IngredientReportService._();

  static SupabaseClient get _db => Supabase.instance.client;
  static bool _supabaseAvailable = AppConfig.hasSupabase;

  @visibleForTesting
  static void enableForTesting() => _supabaseAvailable = true;

  @visibleForTesting
  static void resetForTesting() => _supabaseAvailable = AppConfig.hasSupabase;

  static Future<bool> submitReport({
    required String barcode,
    required String productName,
    required List<String> ingredients,
    String? explanation,
  }) async {
    if (!_supabaseAvailable) return false;
    try {
      final user = AuthService.currentUser;
      await _db.from('ingredient_reports').insert({
        'barcode': barcode,
        'product_name': productName,
        'reported_ingredients': ingredients,
        if (explanation != null && explanation.isNotEmpty)
          'explanation': explanation,
        if (user != null) 'user_id': user.id,
      });
      return true;
    } catch (e) {
      debugPrint('IngredientReportService.submitReport error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getReports({
    String status = 'pending',
  }) async {
    if (!_supabaseAvailable) return [];
    try {
      final rows = List<Map<String, dynamic>>.from(
        await _db
                .from('ingredient_reports')
                .select()
                .eq('status', status)
                .order('created_at', ascending: false)
            as List,
      );
      return rows;
    } catch (e) {
      debugPrint('IngredientReportService.getReports error: $e');
      return [];
    }
  }

  static Future<bool> updateStatus(int id, String status) async {
    if (!_supabaseAvailable) return false;
    try {
      await _db
          .from('ingredient_reports')
          .update({'status': status})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('IngredientReportService.updateStatus error: $e');
      return false;
    }
  }
}
