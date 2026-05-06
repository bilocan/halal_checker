class FoodCategories {
  FoodCategories._();

  // OFf categories that unambiguously indicate an alcoholic product.
  static const Set<String> haram = {
    'en:alcoholic-beverages',
    'en:beers',
    'en:wines',
    'en:spirits',
    'en:champagnes',
    'en:ciders',
    'en:sake',
  };

  // Categories where the product is inherently halal even with no ingredient list.
  static const Set<String> halal = {
    'en:waters',
    'en:bottled-waters',
    'en:mineral-waters',
    'en:spring-waters',
    'en:carbonated-waters',
    'en:sparkling-waters',
    'en:natural-mineral-waters',
    'en:still-natural-mineral-waters',
    'en:still-waters',
    'en:sparkling-mineral-waters',
    'en:flavoured-waters',
    'en:table-waters',
    'en:drinking-water',
    'en:salts',
    'en:table-salt',
    'en:sea-salt',
    'en:sugars',
    'en:white-sugar',
    'en:cane-sugar',
    'en:granulated-sugar',
    'en:vinegars',
  };
}
