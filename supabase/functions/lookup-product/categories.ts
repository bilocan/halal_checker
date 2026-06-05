export const HARAM_CATEGORIES = new Set([
  'en:alcoholic-beverages', 'en:beers', 'en:wines',
  'en:spirits', 'en:champagnes', 'en:ciders', 'en:sake',
])

export const HALAL_CATEGORIES = new Set([
  'en:waters', 'en:bottled-waters', 'en:mineral-waters', 'en:spring-waters',
  'en:carbonated-waters', 'en:sparkling-waters', 'en:natural-mineral-waters',
  'en:still-natural-mineral-waters', 'en:still-waters', 'en:sparkling-mineral-waters',
  'en:flavoured-waters', 'en:table-waters', 'en:drinking-water',
  'en:salts', 'en:table-salt', 'en:sea-salt',
  'en:sugars', 'en:white-sugar', 'en:cane-sugar', 'en:granulated-sugar',
  'en:vinegars',
])

export const NON_FOOD_CATEGORIES = new Set([
  'en:non-food-products',
  'en:cosmetics', 'en:beauty-products', 'en:body-care',
  'en:make-up', 'en:fragrances',
  'en:oral-care', 'en:oral-hygiene',
  'en:personal-care', 'en:hygiene-products',
  'en:cleaning', 'en:cleaning-products', 'en:cleaning-agents',
  'en:household-products', 'en:household-chemicals',
  'en:laundry', 'en:laundry-products', 'en:dishwashing',
  'en:pet-food', 'en:pet-foods', 'en:cat-food', 'en:cat-foods',
  'en:dog-food', 'en:dog-foods', 'en:pet-care',
  'en:plant-care',
  'en:baby-care', 'en:diapers', 'en:baby-wipes', 'en:baby-lotions',
  'en:office-products', 'en:stationery',
])

export const ANIMAL_PRODUCT_CATEGORIES = new Set([
  // English canonical
  'en:meats', 'en:meat', 'en:fresh-meats', 'en:processed-meats',
  'en:meat-products', 'en:meat-based-products', 'en:beef', 'en:beef-products',
  'en:veal', 'en:lamb', 'en:mutton', 'en:lamb-and-mutton', 'en:sheep-meat',
  'en:poultry', 'en:chicken', 'en:turkey', 'en:duck', 'en:goose',
  'en:poultry-products', 'en:chicken-products', 'en:sausages', 'en:deli-meats',
  'en:cold-cuts', 'en:charcuterie', 'en:burgers', 'en:meatballs',
  // German
  'de:fleisch', 'de:fleischwaren', 'de:fleischerzeugnisse', 'de:frisches-fleisch',
  'de:rindfleisch', 'de:kalbfleisch', 'de:lammfleisch', 'de:hammelfleisch',
  'de:geflügel', 'de:geflügelfleisch', 'de:hähnchenfleisch', 'de:putenfleisch',
  'de:entenfleisch', 'de:hackfleisch', 'de:faschiertes', 'de:wurstwaren',
  'de:wurst', 'de:aufschnitt', 'de:frikadellen', 'de:burger',
  // Turkish
  'tr:et', 'tr:et-urunleri', 'tr:et-ürünleri', 'tr:sigir-eti', 'tr:sığır-eti',
  'tr:dana-eti', 'tr:kuzu-eti', 'tr:tavuk', 'tr:tavuk-eti', 'tr:hindi-eti',
  'tr:kiyma', 'tr:kıyma', 'tr:sucuk', 'tr:sosis', 'tr:köfte', 'tr:kofte',
])

export const HALAL_CERT_LABELS = new Set([
  'halal', 'halal certified', 'halal certificate', 'certified halal',
  'hfa halal', 'halal hfa', 'ifanca', 'isna halal', 'muis halal',
  'muslim consumer group',
])

/** Vegan-only OFF labels — vegetarian does not waive animal-derived suspicion. */
export const VEGAN_ONLY_LABELS = new Set([
  'vegan', 'vegan certified', 'en:vegan',
])

export const ANIMAL_PRODUCT_NAME_TERMS = new Set([
  // German / Austrian
  'fleisch', 'faschiertes', 'hackfleisch', 'geschnetzeltes', 'schnitzel',
  'gulasch', 'braten', 'würstchen', 'geflügel', 'rindfleisch', 'kalbfleisch',
  'lammfleisch', 'hähnchenfleisch', 'putenfleisch', 'frikadelle', 'frikadellen',
  // English
  'minced meat', 'ground beef', 'ground chicken', 'ground turkey',
  'chicken breast', 'chicken thigh', 'beef steak', 'lamb chop',
  // French
  'viande', 'poulet haché', 'bœuf haché',
  // Turkish
  'kıyma', 'tavuk göğsü', 'kuzu eti', 'dana eti', 'sığır eti',
  'tavuk but', 'tavuk kanat', 'köfte', 'sucuk', 'kavurma',
])
