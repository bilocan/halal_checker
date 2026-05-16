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
}
