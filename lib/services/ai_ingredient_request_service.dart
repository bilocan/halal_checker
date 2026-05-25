import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/ai_ingredient_request.dart';
import 'auth_service.dart';

class AiIngredientRequestService {
  AiIngredientRequestService._();

  static const _queryTimeout = Duration(seconds: 15);

  static SupabaseClient get _db => Supabase.instance.client;
  static bool _supabaseAvailable = AppConfig.hasSupabase;

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function()? fakeGetPendingRequests;

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function()? fakeGetApprovedRequests;

  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(String)?
  fakeGetRequestForBarcode;

  @visibleForTesting
  static Future<AiIngredientSubmitResult> Function(
    String barcode, {
    String? productName,
  })?
  fakeSubmitRequest;

  @visibleForTesting
  static Future<bool> Function()? fakeIsAdmin;

  @visibleForTesting
  static Future<bool> Function(int id, String status)? fakeUpdateStatus;

  @visibleForTesting
  static Future<bool> Function()? fakeEnsureReady;

  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(String barcode)?
  fakeFindPendingByBarcode;

  @visibleForTesting
  static Future<void> Function({
    required String barcode,
    String? productName,
    required String userId,
  })?
  fakeInsertRequest;

  @visibleForTesting
  static Future<List<dynamic>> Function(int id, String status, String? userId)?
  fakePerformStatusUpdate;

  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(String barcode)?
  fakeFetchRequestForBarcode;

  @visibleForTesting
  static Future<List<dynamic>> Function()? fakeFetchPendingRequests;

  @visibleForTesting
  static Future<List<dynamic>> Function()? fakeFetchApprovedRequests;

  @visibleForTesting
  static void enableForTesting() => _supabaseAvailable = true;

  @visibleForTesting
  static void resetForTesting() {
    _supabaseAvailable = AppConfig.hasSupabase;
    fakeGetPendingRequests = null;
    fakeGetApprovedRequests = null;
    fakeGetRequestForBarcode = null;
    fakeSubmitRequest = null;
    fakeIsAdmin = null;
    fakeUpdateStatus = null;
    fakeEnsureReady = null;
    fakeFindPendingByBarcode = null;
    fakeInsertRequest = null;
    fakePerformStatusUpdate = null;
    fakeFetchRequestForBarcode = null;
    fakeFetchPendingRequests = null;
    fakeFetchApprovedRequests = null;
  }

  static Future<bool> _ensureReady() async {
    if (fakeEnsureReady != null) return fakeEnsureReady!();
    if (!_supabaseAvailable) return false;
    return AuthService.ensureInitialized();
  }

  /// Returns the most recent request for [barcode] regardless of status,
  /// or null if none exists or the query fails.
  static Future<Map<String, dynamic>?> getRequestForBarcode(
    String barcode,
  ) async {
    if (fakeGetRequestForBarcode != null) {
      return fakeGetRequestForBarcode!(barcode);
    }
    if (!await _ensureReady()) return null;
    try {
      final res = fakeFetchRequestForBarcode != null
          ? await fakeFetchRequestForBarcode!(barcode)
          : await _db
                .from('ai_ingredient_requests')
                .select('id, status, created_at')
                .eq('barcode', barcode)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle()
                .timeout(_queryTimeout);
      return res;
    } on Object catch (e, stack) {
      _logQueryError('getRequestForBarcode', e, stack);
      return null;
    }
  }

  static Future<bool> _currentUserIsAdmin() async {
    if (fakeIsAdmin != null) return fakeIsAdmin!();
    final uid = AuthService.currentUser?.id;
    if (uid == null) return false;
    try {
      final row = await _db
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .maybeSingle()
          .timeout(_queryTimeout);
      final role = row?['role'] as String?;
      return role == 'admin' || role == 'superadmin';
    } on Object catch (e, stack) {
      _logQueryError('_currentUserIsAdmin', e, stack);
      return false;
    }
  }

  static Future<bool> _approveRequestRow(int id, String userId) async {
    final reviewedAt = DateTime.now().toUtc().toIso8601String();
    final result = fakePerformStatusUpdate != null
        ? await fakePerformStatusUpdate!(id, 'approved', userId)
        : await _db
              .from('ai_ingredient_requests')
              .update({
                'status': 'approved',
                'reviewed_at': reviewedAt,
                'reviewed_by': userId,
              })
              .eq('id', id)
              .select()
              .timeout(_queryTimeout);
    return result.isNotEmpty;
  }

  /// Submits a new AI ingredient request.
  ///
  /// Admins are auto-approved ([AiIngredientSubmitResult.approved]) so the
  /// caller can run [ProductService.fetchIngredientsByAI] immediately.
  static Future<AiIngredientSubmitResult> submitRequest(
    String barcode, {
    String? productName,
  }) async {
    if (fakeSubmitRequest != null) {
      return fakeSubmitRequest!(barcode, productName: productName);
    }
    if (!await _ensureReady()) return AiIngredientSubmitResult.failed;
    final userId = AuthService.currentUser?.id;
    if (userId == null) return AiIngredientSubmitResult.failed;

    try {
      final isAdmin = await _currentUserIsAdmin();
      final existing = fakeFindPendingByBarcode != null
          ? await fakeFindPendingByBarcode!(barcode)
          : await _db
                .from('ai_ingredient_requests')
                .select('id')
                .eq('barcode', barcode)
                .eq('status', 'pending')
                .maybeSingle()
                .timeout(_queryTimeout);

      if (existing != null) {
        if (!isAdmin) return AiIngredientSubmitResult.alreadyPending;
        final rawId = existing['id'];
        final id = rawId is int ? rawId : (rawId as num).toInt();
        return await _approveRequestRow(id, userId)
            ? AiIngredientSubmitResult.approved
            : AiIngredientSubmitResult.failed;
      }

      final reviewedAt = DateTime.now().toUtc().toIso8601String();
      final insertRow = {
        'barcode': barcode,
        'product_name': productName,
        'requested_by': userId,
        if (isAdmin) ...{
          'status': 'approved',
          'reviewed_at': reviewedAt,
          'reviewed_by': userId,
        },
      };

      if (fakeInsertRequest != null) {
        await fakeInsertRequest!(
          barcode: barcode,
          productName: productName,
          userId: userId,
        );
      } else {
        await _db
            .from('ai_ingredient_requests')
            .insert(insertRow)
            .timeout(_queryTimeout);
      }
      return isAdmin
          ? AiIngredientSubmitResult.approved
          : AiIngredientSubmitResult.pending;
    } on Object catch (e, stack) {
      _logQueryError('submitRequest', e, stack);
      return AiIngredientSubmitResult.failed;
    }
  }

  /// Returns all pending AI ingredient requests.
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    if (fakeGetPendingRequests != null) return fakeGetPendingRequests!();
    if (!await _ensureReady()) return [];
    try {
      final res = fakeFetchPendingRequests != null
          ? await fakeFetchPendingRequests!()
          : await _db
                .from('ai_ingredient_requests')
                .select()
                .eq('status', 'pending')
                .order('created_at', ascending: true)
                .timeout(_queryTimeout);
      return List<Map<String, dynamic>>.from(res);
    } on Object catch (e, stack) {
      _logQueryError('getPendingRequests', e, stack);
      return [];
    }
  }

  /// Returns all approved AI ingredient requests.
  static Future<List<Map<String, dynamic>>> getApprovedRequests() async {
    if (fakeGetApprovedRequests != null) return fakeGetApprovedRequests!();
    if (!await _ensureReady()) return [];
    try {
      final res = fakeFetchApprovedRequests != null
          ? await fakeFetchApprovedRequests!()
          : await _db
                .from('ai_ingredient_requests')
                .select()
                .eq('status', 'approved')
                .order('created_at', ascending: false)
                .timeout(_queryTimeout);
      return List<Map<String, dynamic>>.from(res);
    } on Object catch (e, stack) {
      _logQueryError('getApprovedRequests', e, stack);
      return [];
    }
  }

  /// Updates the status of a request (admin action).
  static Future<bool> updateStatus(int id, String status) async {
    if (fakeUpdateStatus != null) return fakeUpdateStatus!(id, status);
    if (!await _ensureReady()) return false;
    final userId = AuthService.currentUser?.id;
    try {
      final result = fakePerformStatusUpdate != null
          ? await fakePerformStatusUpdate!(id, status, userId)
          : await _db
                .from('ai_ingredient_requests')
                .update({
                  'status': status,
                  'reviewed_at': DateTime.now().toUtc().toIso8601String(),
                  'reviewed_by': userId,
                })
                .eq('id', id)
                .select()
                .timeout(_queryTimeout);
      if (result.isEmpty) {
        debugPrint(
          '[AiIngredientRequestService] updateStatus: no rows updated for id=$id — RLS may be blocking the write',
        );
        return false;
      }
      return true;
    } on Object catch (e, stack) {
      _logQueryError('updateStatus', e, stack);
      return false;
    }
  }

  static void _logQueryError(String operation, Object e, StackTrace stack) {
    if (e is PostgrestException && e.code == 'PGRST205') {
      debugPrint(
        '[AiIngredientRequestService] $operation: table public.ai_ingredient_requests '
        'does not exist on this Supabase project. Apply migrations '
        '(supabase db push) or run supabase/migrations/20260522000001_create_ai_ingredient_requests.sql '
        'in the SQL editor.',
      );
      return;
    }
    debugPrint('[AiIngredientRequestService] $operation error: $e');
    debugPrint('$stack');
  }
}
