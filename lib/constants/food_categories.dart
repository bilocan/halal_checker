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

  // OFf category tags that indicate animal/meat products requiring halal slaughter
  // certification. If a product is in one of these categories but has no halal
  // label, it is flagged as not halal regardless of ingredient analysis.
  // Includes English canonical tags plus German (de:) and Turkish (tr:) variants
  // because OFf categories_tags can contain regional-language tags for local products.
  static const Set<String> animalProduct = {
    // ── English canonical ────────────────────────────────────────────────────
    'en:meats',
    'en:meat',
    'en:fresh-meats',
    'en:processed-meats',
    'en:meat-products',
    'en:meat-based-products',
    'en:beef',
    'en:beef-products',
    'en:veal',
    'en:lamb',
    'en:mutton',
    'en:lamb-and-mutton',
    'en:sheep-meat',
    'en:poultry',
    'en:chicken',
    'en:turkey',
    'en:duck',
    'en:goose',
    'en:poultry-products',
    'en:chicken-products',
    'en:sausages',
    'en:deli-meats',
    'en:cold-cuts',
    'en:charcuterie',
    'en:burgers',
    'en:meatballs',
    // ── German (de:) ────────────────────────────────────────────────────────
    'de:fleisch',
    'de:fleischwaren',
    'de:fleischerzeugnisse',
    'de:frisches-fleisch',
    'de:rindfleisch',
    'de:kalbfleisch',
    'de:lammfleisch',
    'de:hammelfleisch',
    'de:geflügel',
    'de:geflügelfleisch',
    'de:hähnchenfleisch',
    'de:putenfleisch',
    'de:entenfleisch',
    'de:hackfleisch',
    'de:faschiertes',
    'de:wurstwaren',
    'de:wurst',
    'de:aufschnitt',
    'de:frikadellen',
    'de:burger',
    // ── Turkish (tr:) ────────────────────────────────────────────────────────
    'tr:et',
    'tr:et-urunleri',
    'tr:et-ürünleri',
    'tr:sigir-eti',
    'tr:sığır-eti',
    'tr:dana-eti',
    'tr:kuzu-eti',
    'tr:tavuk',
    'tr:tavuk-eti',
    'tr:hindi-eti',
    'tr:kiyma',
    'tr:kıyma',
    'tr:sucuk',
    'tr:sosis',
    'tr:köfte',
    'tr:kofte',
  };

  // Label strings (matched case-insensitively against product label tags) that
  // indicate a recognised halal certification. A product in an animal-product
  // category that carries one of these labels is accepted as halal.
  static const Set<String> halalCertificationLabels = {
    'halal',
    'halal certified',
    'halal certificate',
    'certified halal',
    'hfa halal',
    'halal hfa',
    'ifanca',
    'isna halal',
    'muis halal',
    'muslim consumer group',
  };

  static const Set<String> veganOrVegetarianLabels = {
    'vegan',
    'vegetarian',
    'vegan certified',
    'vegetarian friendly',
    'en:vegan',
    'en:vegetarian',
  };

  /// Vegan-only labels — used when animal-derived suspicion should be waived
  /// (vegetarian still allows dairy/egg and does not qualify).
  static const Set<String> veganOnlyLabels = {
    'vegan',
    'vegan certified',
    'en:vegan',
  };

  static const Set<String> veganOrVegetarianNameTerms = {'vegan', 'vegetarian'};

  // Terms used to detect animal/meat products from the product name alone,
  // as a fallback when OFf category data is absent or marked unknown.
  // Only distinctive multi-character terms — avoids single ambiguous words.
  static const Set<String> animalProductNameTerms = {
    // German / Austrian compound terms
    'fleisch', 'faschiertes', 'hackfleisch', 'geschnetzeltes',
    'schnitzel', 'gulasch', 'braten', 'würstchen', 'geflügel',
    'rindfleisch', 'kalbfleisch', 'lammfleisch', 'hähnchenfleisch',
    'putenfleisch', 'frikadelle', 'frikadellen',
    // German standalone animal terms
    'hähnchen',
    'hühnchen',
    'pute',
    'ente',
    'rind',
    'kalb',
    'lamm',
    'hammel',
    // English compound terms
    'minced meat', 'ground beef', 'ground chicken', 'ground turkey',
    'chicken breast', 'chicken thigh', 'beef steak', 'lamb chop',
    // English standalone animal terms
    'chicken',
    'broiler',
    'fryer',
    'turkey',
    'beef',
    'lamb',
    'veal',
    'duck',
    'goose',
    'mutton',
    // French
    'viande', 'poulet haché', 'bœuf haché', 'poulet', 'dinde', 'bœuf', 'agneau',
    // Turkish compound terms
    'kıyma', 'tavuk göğsü', 'kuzu eti', 'dana eti', 'sığır eti',
    'tavuk but', 'tavuk kanat', 'köfte', 'sucuk', 'kavurma',
    // Turkish standalone animal terms
    'tavuk', 'piliç', 'hindi', 'sığır', 'dana', 'kuzu',
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

  // Product name terms that indicate an inherently halal product. Used as a
  // fallback when OFF categories_tags lack English canonical water/salt entries
  // (e.g. a product whose only category tag is the German-language de:mineralwässer).
  // Matched case-insensitively with word-boundary guards; only applies when no
  // ingredients are present (see off_fetcher.dart isHalalByCategory logic).
  static const Set<String> halalCategoryNameTerms = {
    // Water — German
    'mineralwasser', 'mineralwässer', 'quellwasser', 'tafelwasser',
    'trinkwasser', 'leitungswasser',
    // Water — English
    'mineral water', 'spring water', 'table water', 'drinking water',
    // Water — Turkish
    'maden suyu', 'içme suyu',
    // Water — French
    'eau minérale', 'eau de source',
  };
}
