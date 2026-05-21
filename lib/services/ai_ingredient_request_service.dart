import 'package:supabase_flutter/supabase_flutter.dart';

class AiIngredientRequestService {
  static final _client = Supabase.instance.client;

  /// Returns the most recent request for [barcode] regardless of status,
  /// or null if no request has ever been made.
  static Future<Map<String, dynamic>?> getRequestForBarcode(
    String barcode,
  ) async {
    final res = await _client
        .from('ai_ingredient_requests')
        .select('id, status, created_at')
        .eq('barcode', barcode)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res;
  }

  /// Submits a new AI ingredient request. Returns false if a pending request
  /// for this barcode already exists (to avoid duplicates).
  static Future<bool> submitRequest(
    String barcode, {
    String? productName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    // Check for an existing pending request for this barcode.
    final existing = await _client
        .from('ai_ingredient_requests')
        .select('id')
        .eq('barcode', barcode)
        .eq('status', 'pending')
        .maybeSingle();
    if (existing != null) return false;

    await _client.from('ai_ingredient_requests').insert({
      'barcode': barcode,
      'product_name': productName,
      'requested_by': userId,
    });
    return true;
  }

  /// Returns all pending AI ingredient requests. Admin-only in practice
  /// (RLS only allows admins to write; reads are open to authenticated users).
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final res = await _client
        .from('ai_ingredient_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Updates the status of a request (admin action).
  static Future<bool> updateStatus(int id, String status) async {
    final userId = _client.auth.currentUser?.id;
    await _client
        .from('ai_ingredient_requests')
        .update({
          'status': status,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'reviewed_by': userId,
        })
        .eq('id', id);
    return true;
  }
}
