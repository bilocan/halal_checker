import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'auth_service.dart';

class IngredientReportService {
  IngredientReportService._();

  static SupabaseClient get _db => Supabase.instance.client;
  static bool _supabaseAvailable = AppConfig.hasSupabase;

  @visibleForTesting
  static Future<bool> Function({
    required String barcode,
    required String productName,
    required List<String> ingredients,
    String? explanation,
  })?
  fakeSubmitReport;

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(String status)?
  fakeGetReports;

  @visibleForTesting
  static Future<List<dynamic>> Function(String status)? fakeFetchReports;

  @visibleForTesting
  static Future<bool> Function(int id, String status)? fakeUpdateStatus;

  @visibleForTesting
  static Future<bool> Function()? fakeEnsureReady;

  @visibleForTesting
  static Future<void> Function({
    required String barcode,
    required String productName,
    required List<String> ingredients,
    String? explanation,
    String? userId,
  })?
  fakeInsertReport;

  @visibleForTesting
  static Future<void> Function(int id, String status)? fakePerformStatusUpdate;

  @visibleForTesting
  static void enableForTesting() => _supabaseAvailable = true;

  @visibleForTesting
  static void resetForTesting() {
    _supabaseAvailable = AppConfig.hasSupabase;
    fakeSubmitReport = null;
    fakeGetReports = null;
    fakeFetchReports = null;
    fakeUpdateStatus = null;
    fakeEnsureReady = null;
    fakeInsertReport = null;
    fakePerformStatusUpdate = null;
  }

  static Future<bool> _ensureReady() async {
    if (fakeEnsureReady != null) return fakeEnsureReady!();
    return AuthService.ensureInitialized();
  }

  static Future<bool> submitReport({
    required String barcode,
    required String productName,
    required List<String> ingredients,
    String? explanation,
  }) async {
    if (!_supabaseAvailable) return false;
    if (fakeSubmitReport != null) {
      return fakeSubmitReport!(
        barcode: barcode,
        productName: productName,
        ingredients: ingredients,
        explanation: explanation,
      );
    }
    if (!await _ensureReady()) return false;
    try {
      final user = AuthService.currentUser;
      if (fakeInsertReport != null) {
        await fakeInsertReport!(
          barcode: barcode,
          productName: productName,
          ingredients: ingredients,
          explanation: explanation,
          userId: user?.id,
        );
      } else {
        await _db.from('ingredient_reports').insert({
          'barcode': barcode,
          'product_name': productName,
          'reported_ingredients': ingredients,
          if (explanation != null && explanation.isNotEmpty)
            'explanation': explanation,
          if (user != null) 'user_id': user.id,
        });
      }
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
    if (fakeGetReports != null) return fakeGetReports!(status);
    if (!await _ensureReady()) return [];
    try {
      final raw = fakeFetchReports != null
          ? await fakeFetchReports!(status)
          : await _db
                .from('ingredient_reports')
                .select()
                .eq('status', status)
                .order('created_at', ascending: false);
      final rows = List<Map<String, dynamic>>.from(raw);
      return rows;
    } catch (e) {
      debugPrint('IngredientReportService.getReports error: $e');
      return [];
    }
  }

  static Future<bool> updateStatus(int id, String status) async {
    if (!_supabaseAvailable) return false;
    if (fakeUpdateStatus != null) return fakeUpdateStatus!(id, status);
    if (!await _ensureReady()) return false;
    try {
      if (fakePerformStatusUpdate != null) {
        await fakePerformStatusUpdate!(id, status);
      } else {
        await _db
            .from('ingredient_reports')
            .update({'status': status})
            .eq('id', id);
      }
      return true;
    } catch (e) {
      debugPrint('IngredientReportService.updateStatus error: $e');
      return false;
    }
  }
}
