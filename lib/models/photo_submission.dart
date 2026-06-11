import 'review_status.dart';

class PhotoSubmission {
  final int id;
  final String barcode;
  final String productName;
  final String imageType;
  final String submittedUrl;
  final String? currentUrl;
  final DateTime? createdAt;
  final ReviewStatus status;

  const PhotoSubmission({
    required this.id,
    required this.barcode,
    required this.productName,
    required this.imageType,
    required this.submittedUrl,
    required this.status,
    this.currentUrl,
    this.createdAt,
  });

  bool get hasReplacement => currentUrl != null && currentUrl!.isNotEmpty;

  factory PhotoSubmission.fromJson(Map<String, dynamic> j) {
    final barcode = j['barcode'] as String? ?? '';
    return PhotoSubmission(
      id: (j['id'] as num).toInt(),
      barcode: barcode,
      productName: j['product_name'] as String? ?? barcode,
      imageType: j['image_type'] as String? ?? 'front',
      submittedUrl: j['public_url'] as String? ?? '',
      status:
          ReviewStatus.fromString(j['status'] as String?) ??
          ReviewStatus.pending,
      currentUrl: j['current_image_url'] as String?,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
    );
  }
}
