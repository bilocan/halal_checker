import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'auth_service.dart';

enum ProductImageType { front, ingredients, nutrition }

extension _ProductImageTypeExt on ProductImageType {
  String get value => switch (this) {
    ProductImageType.front => 'front',
    ProductImageType.ingredients => 'ingredients',
    ProductImageType.nutrition => 'nutrition',
  };
}

class ProductImageService {
  ProductImageService._();

  static SupabaseClient get _db => Supabase.instance.client;

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(String)?
  fakeGetSubmissions;

  @visibleForTesting
  static Future<bool> Function(int id, String status)?
  fakeUpdateSubmissionStatus;

  @visibleForTesting
  static void resetForTesting() {
    fakeGetSubmissions = null;
    fakeUpdateSubmissionStatus = null;
  }

  /// Uploads [imageFile] to the `product-images` storage bucket and records
  /// the submission in `product_image_submissions`. Returns true on success.
  static Future<bool> uploadImage({
    required String barcode,
    required File imageFile,
    ProductImageType type = ProductImageType.front,
    String? productName,
  }) async {
    if (!AppConfig.hasSupabase) return false;
    final uid = AuthService.currentUser?.id;
    if (uid == null) return false;

    try {
      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '$barcode/${type.value}_$ts.$ext';

      await _db.storage
          .from('product-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      final publicUrl = _db.storage.from('product-images').getPublicUrl(path);

      await _db.from('product_image_submissions').insert({
        'barcode': barcode,
        'image_type': type.value,
        'storage_path': path,
        'public_url': publicUrl,
        'submitted_by': uid,
        if (productName != null && productName.isNotEmpty)
          'product_name': productName,
      });

      return true;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return false;
    }
  }

  /// Returns all submissions with [status] (default: 'pending'), newest first.
  /// Each row includes a `current_image_url` key carrying the image URL
  /// currently stored in the `products` table for that barcode + image_type,
  /// so the admin can compare old vs new before approving.
  static Future<List<Map<String, dynamic>>> getSubmissions({
    String status = 'pending',
  }) async {
    if (fakeGetSubmissions != null) return fakeGetSubmissions!(status);
    if (!AppConfig.hasSupabase) return [];
    try {
      final rows = await _db
          .from('product_image_submissions')
          .select()
          .eq('status', status)
          .order('created_at');

      final submissions = List<Map<String, dynamic>>.from(rows);
      if (submissions.isEmpty) return [];

      // Fetch current image URLs from the products table for comparison.
      final barcodes = submissions
          .map((r) => r['barcode'] as String)
          .toSet()
          .toList();
      final products = await _db
          .from('products')
          .select(
            'barcode, image_front_url, image_ingredients_url, image_nutrition_url',
          )
          .inFilter('barcode', barcodes);

      final productMap = {
        for (final p in List<Map<String, dynamic>>.from(products))
          p['barcode'] as String: p,
      };

      return submissions.map((row) {
        final product = productMap[row['barcode'] as String?];
        final imageType = row['image_type'] as String? ?? '';
        final currentUrl = switch (imageType) {
          'front' => product?['image_front_url'] as String?,
          'ingredients' => product?['image_ingredients_url'] as String?,
          'nutrition' => product?['image_nutrition_url'] as String?,
          _ => null,
        };
        return {...row, 'current_image_url': currentUrl};
      }).toList();
    } catch (e) {
      debugPrint('getSubmissions error: $e');
      return [];
    }
  }

  /// Sets a submission's status to 'approved' or 'rejected'.
  static Future<bool> updateSubmissionStatus(int id, String status) async {
    if (fakeUpdateSubmissionStatus != null) {
      return fakeUpdateSubmissionStatus!(id, status);
    }
    if (!AppConfig.hasSupabase) return false;
    try {
      await _db
          .from('product_image_submissions')
          .update({'status': status})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('updateSubmissionStatus error: $e');
      return false;
    }
  }
}
