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

  // OFF categories that indicate non-food items (cosmetics, cleaning, etc.).
  // Products in these categories should be marked isNonFood rather than isUnknown.
  static const Set<String> nonFood = {
    'en:non-food-products',
    'en:cosmetics',
    'en:beauty-products',
    'en:body-care',
    'en:make-up',
    'en:fragrances',
    'en:oral-care',
    'en:oral-hygiene',
    'en:personal-care',
    'en:hygiene-products',
    'en:cleaning',
    'en:cleaning-products',
    'en:cleaning-agents',
    'en:household-products',
    'en:household-chemicals',
    'en:laundry',
    'en:laundry-products',
    'en:dishwashing',
    'en:pet-food',
    'en:pet-foods',
    'en:cat-food',
    'en:cat-foods',
    'en:dog-food',
    'en:dog-foods',
    'en:pet-care',
    'en:plant-care',
    'en:baby-care',
    'en:diapers',
    'en:baby-wipes',
    'en:baby-lotions',
    'en:office-products',
    'en:stationery',
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
