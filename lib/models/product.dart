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
  final List<String> haramLabels;
  final List<String> suspiciousLabels;
  final Map<String, String> labelWarnings;
  final Map<String, String> ingredientTranslations;

  /// Maps ingredient text → canonical keyword (e.g. "poudre de lactosérum" → "whey").
  /// Used by the UI to look up localized reason strings per device locale.
  /// Empty for products fetched from cache before this field was introduced.
  final Map<String, String> ingredientCanonicals;
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

  /// Where the ingredient list came from: 'off' (OpenFoodFacts), 'ai' (Gemini
  /// lookup when OFF had no data), or 'community' (approved contribution).
  /// Null for legacy records that predate this field.
  final String? ingredientSource;

  /// True when the product was identified as an animal-derived food but has
  /// no halal certification label. The UI uses this flag to show a localized
  /// "requires halal cert" explanation instead of a hardcoded English string.
  final bool requiresHalalCert;

  /// True when an admin has manually curated this product. Managed products
  /// are never overwritten by Open Food Facts data on refresh.
  final bool isManaged;

  /// When product source data (ingredients, name, labels, is_non_food) last
  /// changed. A DB trigger bumps this on every admin edit to those fields.
  /// Null for legacy rows that predate this column.
  /// A product is stale when:
  ///   updatedAt != null && (lastAnalysedAt == null || lastAnalysedAt < updatedAt)
  final DateTime? updatedAt;

  /// When the rules engine (or AI) last analysed this product.
  /// Null for legacy records that predate this field.
  /// Distinct from fetched_at, which tracks the Open Food Facts fetch time.
  final DateTime? lastAnalysedAt;

  /// Which ingredient source produced keyword matches (primary, off_en, off_taxonomy, …).
  final String? keywordMatchSource;

  /// Flagged ingredient → source key that matched it.
  final Map<String, String> keywordMatchOrigins;

  /// OFF language used for analysis when the displayed label was not keyword-analyzable.
  final String? analyzeLang;

  /// Language of the ingredient label shown in the app (from OFF ingredients_lc).
  final String? displayLang;

  /// Whether Gemini **web ingredient lookup** already ran server-side for this
  /// barcode with the same normalized [name] as now. Controls the AI lookup CTA.
  final bool geminiWebIngredientLookupAttemptedForName;

  /// Brand name from OFF `brands` / `brand_owner` (first entry when comma-separated).
  final String brand;

  /// Pack size / quantity string from OFF (e.g. "37g", "1 l").
  final String quantity;

  /// OFF `categories_tags` canonical tag array (e.g. ["en:snacks", "en:bars"]).
  final List<String> categoriesTags;

  /// OFF `additives_tags` canonical additive IDs (e.g. ["en:e422-glycerol"]).
  final List<String> additivesTags;

  /// OFF `allergens_tags` declared allergens (e.g. ["en:milk", "en:gluten"]).
  final List<String> allergensTags;

  /// OFF `traces_tags` may-contain allergen/cross-contamination tags.
  final List<String> tracesTags;

  /// True when the tag columns (categoriesTags, additivesTags, etc.) have been
  /// populated from a fresh OFF fetch. False for rows cached before this feature
  /// was introduced (tags_version=0). The app uses this to decide whether to
  /// re-fetch via the edge function instead of serving stale tag-less data.
  final bool tagsPopulated;

  /// Normalizes a product title the same way the edge function does for dedupe.
  static String normalizeProductNameForGeminiKey(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool computeGeminiWebLookupAttemptedForName({
    required String productName,
    Object? lookupAt,
    Object? lookupNameKey,
    bool? explicitFromApi,
  }) {
    if (explicitFromApi != null) return explicitFromApi;
    if (lookupAt == null || lookupNameKey is! String) return false;
    return normalizeProductNameForGeminiKey(productName) == lookupNameKey;
  }

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
    this.haramLabels = const [],
    this.suspiciousLabels = const [],
    this.labelWarnings = const {},
    this.ingredientTranslations = const {},
    this.ingredientCanonicals = const {},
    required this.labels,
    this.imageUrl,
    this.imageFrontUrl,
    this.imageIngredientsUrl,
    this.imageNutritionUrl,
    this.explanation = '',
    this.analyzedByAI = false,
    this.analysisMethod,
    this.ingredientSource,
    this.requiresHalalCert = false,
    this.isManaged = false,
    this.updatedAt,
    this.lastAnalysedAt,
    this.keywordMatchSource,
    this.keywordMatchOrigins = const {},
    this.analyzeLang,
    this.displayLang,
    this.geminiWebIngredientLookupAttemptedForName = false,
    this.brand = '',
    this.quantity = '',
    this.categoriesTags = const [],
    this.additivesTags = const [],
    this.allergensTags = const [],
    this.tracesTags = const [],
    this.tagsPopulated = false,
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
    List<String>? haramLabels,
    List<String>? suspiciousLabels,
    Map<String, String>? labelWarnings,
    Map<String, String>? ingredientTranslations,
    Map<String, String>? ingredientCanonicals,
    List<String>? labels,
    String? imageUrl,
    String? imageFrontUrl,
    String? imageIngredientsUrl,
    String? imageNutritionUrl,
    String? explanation,
    bool? analyzedByAI,
    String? analysisMethod,
    String? ingredientSource,
    bool? requiresHalalCert,
    bool? isManaged,
    DateTime? updatedAt,
    DateTime? lastAnalysedAt,
    String? keywordMatchSource,
    Map<String, String>? keywordMatchOrigins,
    String? analyzeLang,
    String? displayLang,
    bool? geminiWebIngredientLookupAttemptedForName,
    String? brand,
    String? quantity,
    List<String>? categoriesTags,
    List<String>? additivesTags,
    List<String>? allergensTags,
    List<String>? tracesTags,
    bool? tagsPopulated,
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
    haramLabels: haramLabels ?? this.haramLabels,
    suspiciousLabels: suspiciousLabels ?? this.suspiciousLabels,
    labelWarnings: labelWarnings ?? this.labelWarnings,
    ingredientTranslations:
        ingredientTranslations ?? this.ingredientTranslations,
    ingredientCanonicals: ingredientCanonicals ?? this.ingredientCanonicals,
    labels: labels ?? this.labels,
    imageUrl: imageUrl ?? this.imageUrl,
    imageFrontUrl: imageFrontUrl ?? this.imageFrontUrl,
    imageIngredientsUrl: imageIngredientsUrl ?? this.imageIngredientsUrl,
    imageNutritionUrl: imageNutritionUrl ?? this.imageNutritionUrl,
    explanation: explanation ?? this.explanation,
    analyzedByAI: analyzedByAI ?? this.analyzedByAI,
    analysisMethod: analysisMethod ?? this.analysisMethod,
    ingredientSource: ingredientSource ?? this.ingredientSource,
    requiresHalalCert: requiresHalalCert ?? this.requiresHalalCert,
    isManaged: isManaged ?? this.isManaged,
    updatedAt: updatedAt ?? this.updatedAt,
    lastAnalysedAt: lastAnalysedAt ?? this.lastAnalysedAt,
    keywordMatchSource: keywordMatchSource ?? this.keywordMatchSource,
    keywordMatchOrigins: keywordMatchOrigins ?? this.keywordMatchOrigins,
    analyzeLang: analyzeLang ?? this.analyzeLang,
    displayLang: displayLang ?? this.displayLang,
    geminiWebIngredientLookupAttemptedForName:
        geminiWebIngredientLookupAttemptedForName ??
        this.geminiWebIngredientLookupAttemptedForName,
    brand: brand ?? this.brand,
    quantity: quantity ?? this.quantity,
    categoriesTags: categoriesTags ?? this.categoriesTags,
    additivesTags: additivesTags ?? this.additivesTags,
    allergensTags: allergensTags ?? this.allergensTags,
    tracesTags: tracesTags ?? this.tracesTags,
    tagsPopulated: tagsPopulated ?? this.tagsPopulated,
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
    if (haramLabels.isNotEmpty) 'haramLabels': haramLabels,
    if (suspiciousLabels.isNotEmpty) 'suspiciousLabels': suspiciousLabels,
    if (labelWarnings.isNotEmpty) 'labelWarnings': labelWarnings,
    'ingredientTranslations': ingredientTranslations,
    if (ingredientCanonicals.isNotEmpty)
      'ingredientCanonicals': ingredientCanonicals,
    'labels': labels,
    'imageUrl': imageUrl,
    'imageFrontUrl': imageFrontUrl,
    'imageIngredientsUrl': imageIngredientsUrl,
    'imageNutritionUrl': imageNutritionUrl,
    'explanation': explanation,
    'analyzedByAI': analyzedByAI,
    if (analysisMethod != null) 'analysisMethod': analysisMethod,
    if (ingredientSource != null) 'ingredientSource': ingredientSource,
    if (requiresHalalCert) 'requiresHalalCert': requiresHalalCert,
    if (isManaged) 'isManaged': isManaged,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (lastAnalysedAt != null)
      'lastAnalysedAt': lastAnalysedAt!.toIso8601String(),
    if (keywordMatchSource != null) 'keywordMatchSource': keywordMatchSource,
    if (keywordMatchOrigins.isNotEmpty)
      'keywordMatchOrigins': keywordMatchOrigins,
    if (analyzeLang != null) 'analyzeLang': analyzeLang,
    if (displayLang != null) 'displayLang': displayLang,
    'geminiWebIngredientLookupAttemptedForName':
        geminiWebIngredientLookupAttemptedForName,
    if (brand.isNotEmpty) 'brand': brand,
    if (quantity.isNotEmpty) 'quantity': quantity,
    if (categoriesTags.isNotEmpty) 'categoriesTags': categoriesTags,
    if (additivesTags.isNotEmpty) 'additivesTags': additivesTags,
    if (allergensTags.isNotEmpty) 'allergensTags': allergensTags,
    if (tracesTags.isNotEmpty) 'tracesTags': tracesTags,
    if (tagsPopulated) 'tagsPopulated': tagsPopulated,
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
    haramLabels: json['haramLabels'] != null
        ? List<String>.from(json['haramLabels'] as List)
        : const [],
    suspiciousLabels: json['suspiciousLabels'] != null
        ? List<String>.from(json['suspiciousLabels'] as List)
        : const [],
    labelWarnings: json['labelWarnings'] != null
        ? Map<String, String>.from(json['labelWarnings'] as Map)
        : const {},
    ingredientTranslations: json['ingredientTranslations'] != null
        ? Map<String, String>.from(json['ingredientTranslations'] as Map)
        : const {},
    ingredientCanonicals: json['ingredientCanonicals'] != null
        ? Map<String, String>.from(json['ingredientCanonicals'] as Map)
        : const {},
    labels: List<String>.from(json['labels'] as List),
    imageUrl: json['imageUrl'] as String?,
    imageFrontUrl: json['imageFrontUrl'] as String?,
    imageIngredientsUrl: json['imageIngredientsUrl'] as String?,
    imageNutritionUrl: json['imageNutritionUrl'] as String?,
    explanation: json['explanation'] as String? ?? '',
    analyzedByAI: json['analyzedByAI'] as bool? ?? false,
    analysisMethod: json['analysisMethod'] as String?,
    ingredientSource: json['ingredientSource'] as String?,
    requiresHalalCert: json['requiresHalalCert'] as bool? ?? false,
    isManaged: json['isManaged'] as bool? ?? false,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
    lastAnalysedAt: json['lastAnalysedAt'] != null
        ? DateTime.tryParse(json['lastAnalysedAt'] as String)
        : null,
    keywordMatchSource: json['keywordMatchSource'] as String?,
    keywordMatchOrigins: json['keywordMatchOrigins'] != null
        ? Map<String, String>.from(json['keywordMatchOrigins'] as Map)
        : const {},
    analyzeLang: json['analyzeLang'] as String?,
    displayLang: json['displayLang'] as String?,
    geminiWebIngredientLookupAttemptedForName:
        computeGeminiWebLookupAttemptedForName(
          productName: json['name'] as String,
          lookupAt: json['geminiWebIngredientLookupAt'],
          lookupNameKey: json['geminiWebIngredientLookupNameKey'],
          explicitFromApi:
              json['geminiWebIngredientLookupAttemptedForName'] as bool?,
        ),
    brand: json['brand'] as String? ?? '',
    quantity: json['quantity'] as String? ?? '',
    categoriesTags: json['categoriesTags'] != null
        ? List<String>.from(json['categoriesTags'] as List)
        : const [],
    additivesTags: json['additivesTags'] != null
        ? List<String>.from(json['additivesTags'] as List)
        : const [],
    allergensTags: json['allergensTags'] != null
        ? List<String>.from(json['allergensTags'] as List)
        : const [],
    tracesTags: json['tracesTags'] != null
        ? List<String>.from(json['tracesTags'] as List)
        : const [],
    tagsPopulated: json['tagsPopulated'] as bool? ?? false,
  );
}
