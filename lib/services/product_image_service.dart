import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'auth_service.dart';
import 'photo_submission_config_service.dart';

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
  static bool _supabaseAvailable = AppConfig.hasSupabase;

  /// Last upload failure message (debug / support). Cleared on success.
  static String? debugLastUploadError;

  /// True when the last successful [uploadImage] was auto-approved (global flag).
  static bool lastUploadAutoApproved = false;

  /// Shown in debug UI when [uploadImage] fails.
  static String? get uploadFailureDetail =>
      kDebugMode ? debugLastUploadError : null;

  static Future<bool> _isAutoApproveEnabled() async {
    if (fakeIsAutoApproveEnabled != null) {
      return fakeIsAutoApproveEnabled!();
    }
    return PhotoSubmissionConfigService().isAutoApproveEnabled();
  }

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(String)?
  fakeGetSubmissions;

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(String status)?
  fakeFetchSubmissionsForStatus;

  @visibleForTesting
  static Future<bool> Function(int id, String status)?
  fakeUpdateSubmissionStatus;

  @visibleForTesting
  static Future<bool> Function({
    required String barcode,
    required File imageFile,
    ProductImageType type,
    String? productName,
  })?
  fakeUploadImage;

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(List<String> barcodes)?
  fakeFetchProductsForBarcodes;

  @visibleForTesting
  static Future<Uint8List> Function(File file)? fakeReadImageBytes;

  @visibleForTesting
  static Future<void> Function(String path, Uint8List bytes, String mimeType)?
  fakeUploadBinary;

  @visibleForTesting
  static String Function(String path)? fakeGetPublicUrl;

  @visibleForTesting
  static Future<void> Function(Map<String, dynamic> payload)?
  fakeInsertSubmission;

  @visibleForTesting
  static Future<bool> Function()? fakeIsAutoApproveEnabled;

  @visibleForTesting
  static Future<void> Function(int id, String status)?
  fakePerformSubmissionStatusUpdate;

  @visibleForTesting
  static void enableForTesting() => _supabaseAvailable = true;

  @visibleForTesting
  static void resetForTesting() {
    _supabaseAvailable = AppConfig.hasSupabase;
    debugLastUploadError = null;
    fakeGetSubmissions = null;
    fakeFetchSubmissionsForStatus = null;
    fakeUpdateSubmissionStatus = null;
    fakeUploadImage = null;
    fakeFetchProductsForBarcodes = null;
    fakeReadImageBytes = null;
    fakeUploadBinary = null;
    fakeGetPublicUrl = null;
    fakeInsertSubmission = null;
    fakePerformSubmissionStatusUpdate = null;
    fakeIsAutoApproveEnabled = null;
    lastUploadAutoApproved = false;
  }

  /// Uploads [imageFile] to the `product-images` storage bucket and records
  /// the submission in `product_image_submissions`. Returns true on success.
  static Future<bool> uploadImage({
    required String barcode,
    required File imageFile,
    ProductImageType type = ProductImageType.front,
    String? productName,
  }) async {
    if (fakeUploadImage != null) {
      return fakeUploadImage!(
        barcode: barcode,
        imageFile: imageFile,
        type: type,
        productName: productName,
      );
    }
    if (!_supabaseAvailable) {
      debugLastUploadError = 'Supabase not configured';
      return false;
    }
    await AuthService.ensureInitialized();
    final uid = AuthService.currentUser?.id;
    if (uid == null) {
      debugLastUploadError = 'Not signed in';
      return false;
    }

    try {
      debugLastUploadError = null;
      lastUploadAutoApproved = false;
      final bytes = fakeReadImageBytes != null
          ? await fakeReadImageBytes!(imageFile)
          : await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        debugLastUploadError = 'Image file is empty';
        return false;
      }
      final ext = _imageExtension(imageFile.path);
      final mimeType = _mimeTypeForExtension(ext);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeBarcode = barcode.replaceAll(RegExp(r'[^\w\-.]'), '_');
      final path = '$safeBarcode/${type.value}_$ts.$ext';

      if (fakeUploadBinary != null) {
        await fakeUploadBinary!(path, bytes, mimeType);
      } else {
        await _db.storage
            .from('product-images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
      }

      final publicUrl = fakeGetPublicUrl != null
          ? fakeGetPublicUrl!(path)
          : _db.storage.from('product-images').getPublicUrl(path);

      final autoApprove = await _isAutoApproveEnabled();
      final payload = {
        'barcode': barcode,
        'image_type': type.value,
        'storage_path': path,
        'public_url': publicUrl,
        'submitted_by': uid,
        if (productName != null && productName.isNotEmpty)
          'product_name': productName,
        if (autoApprove) 'status': 'approved',
      };
      lastUploadAutoApproved = autoApprove;

      if (fakeInsertSubmission != null) {
        await fakeInsertSubmission!(payload);
      } else {
        await _db.from('product_image_submissions').insert(payload);
      }

      return true;
    } catch (e, st) {
      debugLastUploadError = e.toString();
      debugPrint('Image upload error: $e\n$st');
      return false;
    }
  }

  static String _imageExtension(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    if (ext.isEmpty) return 'jpg';
    final bare = ext.substring(1);
    const allowed = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
    if (!allowed.contains(bare)) return 'jpg';
    return bare == 'jpeg' ? 'jpg' : bare;
  }

  static String _mimeTypeForExtension(String ext) => switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    _ => 'image/jpeg',
  };

  /// Returns all submissions with [status] (default: 'pending'), newest first.
  /// Each row includes a `current_image_url` key carrying the image URL
  /// currently stored in the `products` table for that barcode + image_type,
  /// so the admin can compare old vs new before approving.
  static Future<List<Map<String, dynamic>>> getSubmissions({
    String status = 'pending',
  }) async {
    if (fakeGetSubmissions != null) return fakeGetSubmissions!(status);
    if (!_supabaseAvailable) return [];
    try {
      final rows = fakeFetchSubmissionsForStatus != null
          ? await fakeFetchSubmissionsForStatus!(status)
          : await _db
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
      final products = fakeFetchProductsForBarcodes != null
          ? await fakeFetchProductsForBarcodes!(barcodes)
          : await _db
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
    if (!_supabaseAvailable) return false;
    try {
      if (fakePerformSubmissionStatusUpdate != null) {
        await fakePerformSubmissionStatusUpdate!(id, status);
      } else {
        await _db
            .from('product_image_submissions')
            .update({'status': status})
            .eq('id', id);
      }
      return true;
    } catch (e) {
      debugPrint('updateSubmissionStatus error: $e');
      return false;
    }
  }
}
