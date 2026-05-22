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
      id: (j['id'] as num).toInt(),
      barcode: barcode,
      productName: j['product_name'] as String? ?? barcode,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
    );
  }
}
