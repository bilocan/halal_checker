class Product {
  final String barcode;
  final String name;
  final List<String> ingredients;
  final bool isHalal;
  final List<String> haramIngredients;
  final List<String> suspiciousIngredients;
  final Map<String, String> ingredientWarnings;
  final List<String> labels;
  final String? imageUrl;
  final String? imageFrontUrl;
  final String? imageIngredientsUrl;
  final String? imageNutritionUrl;
  final String explanation;
  final bool analyzedByAI;

  Product({
    required this.barcode,
    required this.name,
    required this.ingredients,
    required this.isHalal,
    required this.haramIngredients,
    required this.suspiciousIngredients,
    required this.ingredientWarnings,
    required this.labels,
    this.imageUrl,
    this.imageFrontUrl,
    this.imageIngredientsUrl,
    this.imageNutritionUrl,
    this.explanation = '',
    this.analyzedByAI = false,
  });

  Product copyWith({
    String? barcode,
    String? name,
    List<String>? ingredients,
    bool? isHalal,
    List<String>? haramIngredients,
    List<String>? suspiciousIngredients,
    Map<String, String>? ingredientWarnings,
    List<String>? labels,
    String? imageUrl,
    String? imageFrontUrl,
    String? imageIngredientsUrl,
    String? imageNutritionUrl,
    String? explanation,
    bool? analyzedByAI,
  }) => Product(
    barcode: barcode ?? this.barcode,
    name: name ?? this.name,
    ingredients: ingredients ?? this.ingredients,
    isHalal: isHalal ?? this.isHalal,
    haramIngredients: haramIngredients ?? this.haramIngredients,
    suspiciousIngredients: suspiciousIngredients ?? this.suspiciousIngredients,
    ingredientWarnings: ingredientWarnings ?? this.ingredientWarnings,
    labels: labels ?? this.labels,
    imageUrl: imageUrl ?? this.imageUrl,
    imageFrontUrl: imageFrontUrl ?? this.imageFrontUrl,
    imageIngredientsUrl: imageIngredientsUrl ?? this.imageIngredientsUrl,
    imageNutritionUrl: imageNutritionUrl ?? this.imageNutritionUrl,
    explanation: explanation ?? this.explanation,
    analyzedByAI: analyzedByAI ?? this.analyzedByAI,
  );

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'ingredients': ingredients,
    'isHalal': isHalal,
    'haramIngredients': haramIngredients,
    'suspiciousIngredients': suspiciousIngredients,
    'ingredientWarnings': ingredientWarnings,
    'labels': labels,
    'imageUrl': imageUrl,
    'imageFrontUrl': imageFrontUrl,
    'imageIngredientsUrl': imageIngredientsUrl,
    'imageNutritionUrl': imageNutritionUrl,
    'explanation': explanation,
    'analyzedByAI': analyzedByAI,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    barcode: json['barcode'] as String,
    name: json['name'] as String,
    ingredients: List<String>.from(json['ingredients'] as List),
    isHalal: json['isHalal'] as bool,
    haramIngredients: List<String>.from(json['haramIngredients'] as List),
    suspiciousIngredients: List<String>.from(
      json['suspiciousIngredients'] as List,
    ),
    ingredientWarnings: Map<String, String>.from(
      json['ingredientWarnings'] as Map,
    ),
    labels: List<String>.from(json['labels'] as List),
    imageUrl: json['imageUrl'] as String?,
    imageFrontUrl: json['imageFrontUrl'] as String?,
    imageIngredientsUrl: json['imageIngredientsUrl'] as String?,
    imageNutritionUrl: json['imageNutritionUrl'] as String?,
    explanation: json['explanation'] as String? ?? '',
    analyzedByAI: json['analyzedByAI'] as bool? ?? false,
  );
}
