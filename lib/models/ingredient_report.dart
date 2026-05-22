class IngredientReport {
  final int id;
  final String barcode;
  final String productName;
  final List<String> reportedIngredients;
  final String? explanation;
  final DateTime? createdAt;

  const IngredientReport({
    required this.id,
    required this.barcode,
    required this.productName,
    required this.reportedIngredients,
    this.explanation,
    this.createdAt,
  });

  factory IngredientReport.fromJson(Map<String, dynamic> j) {
    final barcode = j['barcode'] as String? ?? '';
    return IngredientReport(
      id: (j['id'] as num).toInt(),
      barcode: barcode,
      productName: j['product_name'] as String? ?? barcode,
      reportedIngredients: List<String>.from(
        j['reported_ingredients'] as List? ?? [],
      ),
      explanation: j['explanation'] as String?,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
    );
  }
}
