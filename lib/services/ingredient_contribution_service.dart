import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class IngredientContributionService {
  IngredientContributionService._();

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
}
