import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';

class OcrService {
  OcrService._();

  /// Extract ingredient text from an image URL (e.g. OpenFoodFacts image).
  static Future<String?> extractIngredientsFromImage(String imageUrl) async {
    return _callEdgeFunction({'image_url': imageUrl});
  }

  /// Try multiple candidate image URLs in priority order.
  /// The Edge Function validates each image and returns the first one that
  /// actually contains ingredient text (not nutrition tables, etc.).
  static Future<String?> extractIngredientsFromImages(
    List<String> imageUrls,
  ) async {
    if (imageUrls.isEmpty) return null;
    if (imageUrls.length == 1) {
      return _callEdgeFunction({'image_url': imageUrls.first});
    }
    return _callEdgeFunction({'image_urls': imageUrls});
  }

  /// Extract ingredient text from a local image file (e.g. camera capture).
  static Future<String?> extractIngredientsFromFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Data = base64Encode(bytes);
    return _callEdgeFunction({'image_base64': base64Data});
  }

  static Future<String?> _callEdgeFunction(Map<String, dynamic> body) async {
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
            body: jsonEncode(body),
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
