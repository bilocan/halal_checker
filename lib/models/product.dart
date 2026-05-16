class Product {
  final String barcode;
  final String name;
  final List<String> ingredients;
  final bool isHalal;
  final bool isUnknown;
  final bool isNonFood;
  final List<String> haramIngredients;
  final List<String> suspiciousIngredients;
  final Map<String, String> ingredientWarnings;
  final Map<String, String> ingredientTranslations;
  final List<String> labels;
  final String? imageUrl;
  final String? imageFrontUrl;
  final String? imageIngredientsUrl;
  final String? imageNutritionUrl;
  final String explanation;
  final bool analyzedByAI;

  /// 'ai' when Claude/Gemini analyzed this product; 'keyword' when keyword
  /// matching was used as the sole analysis method. Null for legacy records
  /// that predate this field.
  final String? analysisMethod;

  /// True when the product was identified as an animal-derived food but has
  /// no halal certification label. The UI uses this flag to show a localized
  /// "requires halal cert" explanation instead of a hardcoded English string.
  final bool requiresHalalCert;

  /// True when an admin has manually curated this product. Managed products
  /// are never overwritten by Open Food Facts data on refresh.
  final bool isManaged;

  Product({
    required this.barcode,
    required this.name,
    required this.ingredients,
    required this.isHalal,
    this.isUnknown = false,
    this.isNonFood = false,
    required this.haramIngredients,
    required this.suspiciousIngredients,
    required this.ingredientWarnings,
    this.ingredientTranslations = const {},
    required this.labels,
    this.imageUrl,
    this.imageFrontUrl,
    this.imageIngredientsUrl,
    this.imageNutritionUrl,
    this.explanation = '',
    this.analyzedByAI = false,
    this.analysisMethod,
    this.requiresHalalCert = false,
    this.isManaged = false,
  });

  Product copyWith({
    String? barcode,
    String? name,
    List<String>? ingredients,
    bool? isHalal,
    bool? isUnknown,
    bool? isNonFood,
    List<String>? haramIngredients,
    List<String>? suspiciousIngredients,
    Map<String, String>? ingredientWarnings,
    Map<String, String>? ingredientTranslations,
    List<String>? labels,
    String? imageUrl,
    String? imageFrontUrl,
    String? imageIngredientsUrl,
    String? imageNutritionUrl,
    String? explanation,
    bool? analyzedByAI,
    String? analysisMethod,
    bool? requiresHalalCert,
    bool? isManaged,
  }) => Product(
    barcode: barcode ?? this.barcode,
    name: name ?? this.name,
    ingredients: ingredients ?? this.ingredients,
    isHalal: isHalal ?? this.isHalal,
    isUnknown: isUnknown ?? this.isUnknown,
    isNonFood: isNonFood ?? this.isNonFood,
    haramIngredients: haramIngredients ?? this.haramIngredients,
    suspiciousIngredients: suspiciousIngredients ?? this.suspiciousIngredients,
    ingredientWarnings: ingredientWarnings ?? this.ingredientWarnings,
    ingredientTranslations:
        ingredientTranslations ?? this.ingredientTranslations,
    labels: labels ?? this.labels,
    imageUrl: imageUrl ?? this.imageUrl,
    imageFrontUrl: imageFrontUrl ?? this.imageFrontUrl,
    imageIngredientsUrl: imageIngredientsUrl ?? this.imageIngredientsUrl,
    imageNutritionUrl: imageNutritionUrl ?? this.imageNutritionUrl,
    explanation: explanation ?? this.explanation,
    analyzedByAI: analyzedByAI ?? this.analyzedByAI,
    analysisMethod: analysisMethod ?? this.analysisMethod,
    requiresHalalCert: requiresHalalCert ?? this.requiresHalalCert,
    isManaged: isManaged ?? this.isManaged,
  );

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'ingredients': ingredients,
    'isHalal': isHalal,
    'isUnknown': isUnknown,
    'isNonFood': isNonFood,
    'haramIngredients': haramIngredients,
    'suspiciousIngredients': suspiciousIngredients,
    'ingredientWarnings': ingredientWarnings,
    'ingredientTranslations': ingredientTranslations,
    'labels': labels,
    'imageUrl': imageUrl,
    'imageFrontUrl': imageFrontUrl,
    'imageIngredientsUrl': imageIngredientsUrl,
    'imageNutritionUrl': imageNutritionUrl,
    'explanation': explanation,
    'analyzedByAI': analyzedByAI,
    if (analysisMethod != null) 'analysisMethod': analysisMethod,
    if (requiresHalalCert) 'requiresHalalCert': requiresHalalCert,
    if (isManaged) 'isManaged': isManaged,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    barcode: json['barcode'] as String,
    name: json['name'] as String,
    ingredients: List<String>.from(json['ingredients'] as List),
    isHalal: json['isHalal'] as bool,
    isUnknown: json['isUnknown'] as bool? ?? false,
    isNonFood: json['isNonFood'] as bool? ?? false,
    haramIngredients: List<String>.from(json['haramIngredients'] as List),
    suspiciousIngredients: List<String>.from(
      json['suspiciousIngredients'] as List,
    ),
    ingredientWarnings: Map<String, String>.from(
      json['ingredientWarnings'] as Map,
    ),
    ingredientTranslations: json['ingredientTranslations'] != null
        ? Map<String, String>.from(json['ingredientTranslations'] as Map)
        : const {},
    labels: List<String>.from(json['labels'] as List),
    imageUrl: json['imageUrl'] as String?,
    imageFrontUrl: json['imageFrontUrl'] as String?,
    imageIngredientsUrl: json['imageIngredientsUrl'] as String?,
    imageNutritionUrl: json['imageNutritionUrl'] as String?,
    explanation: json['explanation'] as String? ?? '',
    analyzedByAI: json['analyzedByAI'] as bool? ?? false,
    analysisMethod: json['analysisMethod'] as String?,
    requiresHalalCert: json['requiresHalalCert'] as bool? ?? false,
    isManaged: json['isManaged'] as bool? ?? false,
  );
}
