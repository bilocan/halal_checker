import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class OcrService {
  OcrService._();

  /// Call the Supabase Edge Function to extract ingredient text from an image
  /// URL using AI vision. Returns the extracted text or null on failure.
  static Future<String?> extractIngredientsFromImage(String imageUrl) async {
    if (!AppConfig.hasSupabase) return null;
    try {
      final response = await http
          .post(
            Uri.parse(
              '${AppConfig.supabaseUrl}/functions/v1/extract-ingredients',
            ),
            headers: {
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'image_url': imageUrl}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['ingredients_text'] as String?;
    } catch (_) {
      return null;
    }
  }
}
