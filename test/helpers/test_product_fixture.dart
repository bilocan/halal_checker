import 'package:halal_checker/models/product.dart';

Product testProduct(
  String barcode, {
  List<String> ingredients = const ['water', 'salt'],
  bool isUnknown = true,
  String? ingredientSource,
}) {
  return Product(
    barcode: barcode,
    name: 'Product $barcode',
    ingredients: ingredients,
    isHalal: true,
    isUnknown: isUnknown,
    haramIngredients: [],
    suspiciousIngredients: [],
    ingredientWarnings: {},
    labels: [],
    explanation: 'Test fixture.',
    ingredientSource: ingredientSource,
  );
}
