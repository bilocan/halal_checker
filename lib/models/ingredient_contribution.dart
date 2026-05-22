class IngredientContribution {
  final int id;
  final String barcode;
  final String productName;
  final String ingredientText;
  final DateTime? createdAt;

  const IngredientContribution({
    required this.id,
    required this.barcode,
    required this.productName,
    required this.ingredientText,
    this.createdAt,
  });

  factory IngredientContribution.fromJson(Map<String, dynamic> j) {
    final barcode = j['barcode'] as String? ?? '';
    return IngredientContribution(
      id: (j['id'] as num).toInt(),
      barcode: barcode,
      productName: (j['products'] as Map?)?['name'] as String? ?? barcode,
      ingredientText: j['ingredient_text'] as String? ?? '',
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? ''),
    );
  }
}
