import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OcrService {
  OcrService._();

  static http.Client _httpClient = http.Client();

  @visibleForTesting
  static void setHttpClientForTesting(http.Client client) =>
      _httpClient = client;

  @visibleForTesting
  static void resetForTesting() => _httpClient = http.Client();

  /// Extract text from a local image file using on-device ML Kit OCR.
  static Future<String?> extractIngredientsFromFile(File imageFile) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFile(imageFile),
      );
      final text = result.text.trim();
      debugPrint('OCR: ${text.length} chars extracted');
      return text.isEmpty ? null : text;
    } catch (e) {
      debugPrint('OCR file error: $e');
      return null;
    } finally {
      recognizer.close();
    }
  }

  /// Extract text from an image URL by downloading it to a temp file first.
  static Future<String?> extractIngredientsFromImage(String imageUrl) async {
    final file = await _downloadToTemp(imageUrl);
    if (file == null) return null;
    try {
      return await extractIngredientsFromFile(file);
    } finally {
      file.delete().catchError((e) => file);
    }
  }

  /// Try multiple image URLs in order; return the first non-empty result.
  static Future<String?> extractIngredientsFromImages(
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      final text = await extractIngredientsFromImage(url);
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static Future<File?> _downloadToTemp(String imageUrl) async {
    try {
      final response = await _httpClient.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      debugPrint('OCR download error: $e');
      return null;
    }
  }
}
