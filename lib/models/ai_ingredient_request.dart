/// Outcome of [AiIngredientRequestService.submitRequest].
enum AiIngredientSubmitResult { failed, alreadyPending, pending, approved }

class AiIngredientRequest {
  final int id;
  final String barcode;
  final String productName;
  final DateTime? createdAt;

  const AiIngredientRequest({
    required this.id,
    required this.barcode,
    required this.productName,
    this.createdAt,
  });

  factory AiIngredientRequest.fromJson(Map<String, dynamic> j) {
    final barcode = j['barcode'] as String? ?? '';
    return AiIngredientRequest(
      id: _parseId(j['id']),
      barcode: barcode,
      productName: j['product_name'] as String? ?? barcode,
      createdAt: _parseDateTime(j['created_at']),
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.parse(value);
    throw FormatException('Invalid ai_ingredient_requests.id: $value');
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
