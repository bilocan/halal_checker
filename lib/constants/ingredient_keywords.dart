class IngredientKeywords {
  IngredientKeywords._();

  static const Map<String, String> haram = {
    'alcohol': 'Contains alcohol or alcohol-derived ingredient',
    'ethanol': 'Contains alcohol or alcohol-derived ingredient',
    'wine': 'Contains alcohol or alcohol-derived ingredient',
    'beer': 'Contains alcohol or alcohol-derived ingredient',
    'cognac': 'Contains cognac (alcoholic spirit)',
    'brandy': 'Contains brandy (alcoholic spirit)',
    'whisky': 'Contains whisky (alcoholic spirit)',
    'vodka': 'Contains vodka (alcoholic spirit)',
    'rum': 'Contains rum (alcoholic spirit)',
    'gin': 'Contains gin (alcoholic spirit)',
    'liqueur': 'Contains liqueur (alcoholic)',
    'schnapps': 'Contains schnapps (alcoholic spirit)',
    'champagne': 'Contains champagne (alcoholic)',
    'prosecco': 'Contains prosecco (alcoholic)',
    'bourbon': 'Contains bourbon (alcoholic spirit)',
    'sake': 'Contains sake (alcoholic)',
    'pork': 'Contains pork or pork-derived ingredient',
    'lard': 'Contains pork fat',
    'gelatin': 'Gelatin is typically animal-derived',
    'bacon': 'Contains pork product',
    'ham': 'Contains pork product',
    'pepperoni': 'Contains pork product',
    'salami': 'Contains pork product',
    'chorizo': 'Contains pork product',
    'prosciutto': 'Contains pork product',
    'carmine': 'Carmine/cochineal is insect-derived',
    'cochineal': 'Carmine/cochineal is insect-derived',
    'e120': 'Carmine/cochineal color, animal-derived',
    'e441': 'Gelatin, animal-derived',
    'e542': 'Bone phosphate, animal-derived',
    'e904': 'Shellac, animal-derived',
  };

  static const Map<String, String> suspicious = {
    'e920': 'L-cysteine may be animal-derived',
    'e322': 'Lecithin may be animal-derived',
    'e471': 'Mono- and diglycerides may be animal-derived',
    'e472': 'Emulsifiers may be animal-derived',
    'e473': 'Sucrose esters may be animal-derived',
    'e927': 'Glycine may be animal-derived',
    'rennet': 'Rennet may be animal-derived',
    'whey': 'Whey is a dairy ingredient — source verification recommended.',
    'l-cysteine': 'L-cysteine may be animal-derived',
    'natural flavour': 'Natural flavor may include animal-derived extracts',
    'flavouring': 'Aroma / Flavouring — source often unknown.',
    'enzymes': 'Enzymes may be extracted from animal sources',
    'glycerol': 'Glycerol may be animal-derived',
  };

  // Multilingual variants per canonical keyword (EN / DE / TR / FR / IT / ES / NL / SR / HU / CS)
  static const Map<String, List<String>> haramVariants = {
    'alcohol': ['alcohol', 'alkohol', 'alcool', 'alcol', 'alkol', 'álcool'],
    'ethanol': ['ethanol', 'äthanol', 'éthanol', 'etanolo', 'etanol'],
    'wine': [
      'wine',
      'wein',
      'vin',
      'vino',
      'şarap',
      'wijn',
      'vinho',
      'víno',
      'bor',
    ],
    'beer': [
      'beer', 'bier', 'bière', 'birra', 'cerveza', 'bira', 'cerveja',
      'pivo', // SR / CS
      'sör', // HU
    ],
    'cognac': ['cognac', 'kognak', 'konjak', 'konyak', 'koňak'],
    'brandy': ['brandy', 'branntwein', 'brandewijn'],
    'whisky': ['whisky', 'whiskey', 'whiskie', 'viski'],
    'vodka': ['vodka', 'wodka', 'votka'], // SR
    'rum': ['rum', 'rhum', 'ron'],
    'gin': ['gin', 'džin'], // SR
    'liqueur': [
      'liqueur', 'likör', 'licor', 'likeur', 'liquore', 'liker',
      'likőr', // HU
      'likér', // CS
    ],
    'schnapps': ['schnapps', 'schnaps', 'šnaps'], // SR
    'champagne': [
      'champagne', 'sekt', 'cava', 'spumante',
      'šampanjac', // SR
      'pezsgő', // HU
      'šampaňské', // CS
    ],
    'prosecco': ['prosecco'],
    'bourbon': ['bourbon'],
    'sake': ['sake', 'saké'],
    'pork': [
      'pork', 'schwein', 'schweinefleisch', 'porc', 'maiale', 'cerdo', 'domuz',
      'varkens', 'varkensvlees', 'porco',
      'svinjetina', 'svinjsko', // SR
      'sertéshús', 'sertés', // HU
      'vepřové', 'vepřová', // CS
    ],
    'lard': [
      'lard', 'schmalz', 'schweineschmalz', 'saindoux', 'strutto', 'manteca',
      'domuz yağı', 'banha',
      'svinjska mast', // SR
      'sertészsír', // HU
      'sádlo', // CS
    ],
    'gelatin': [
      'gelatin', 'gelatine', 'gelatina', 'jelatin', 'gélatine',
      'želatina', // SR / CS
      'zselatin', // HU
    ],
    'bacon': [
      'bacon', 'speck', 'lardons', 'pancetta', 'domuz pastırması',
      'slanina', // SR / CS
      'szalonna', // HU
    ],
    'ham': [
      'ham', 'schinken', 'jambon', 'prosciutto', 'jamón', 'presunto',
      'šunka', // SR / CS
      'sonka', // HU
    ],
    'pepperoni': ['pepperoni'],
    'salami': ['salami', 'salame', 'szalámi', 'salám'], // HU / CS
    'chorizo': ['chorizo'],
    'prosciutto': ['prosciutto'],
    'carmine': ['carmine', 'karmin', 'carmín', 'karmín', 'carmin'],
    'cochineal': [
      'cochineal', 'cochenille', 'cocciniglia', 'cochinilla', 'koşnil',
      'košenil', // SR
      'košenila', // CS
    ],
    'e120': ['e120', 'e-120'],
    'e441': ['e441', 'e-441'],
    'e542': ['e542', 'e-542'],
    'e904': ['e904', 'e-904'],
  };

  static const Map<String, List<String>> suspiciousVariants = {
    'e920': ['e920', 'e-920'],
    'e322': ['e322', 'e-322'],
    'e471': ['e471', 'e-471'],
    'e472': ['e472', 'e-472'],
    'e473': ['e473', 'e-473'],
    'e927': ['e927', 'e-927'],
    'rennet': [
      'rennet', 'lab', 'labferment', 'présure', 'caglio', 'cuajo',
      'peynir mayası', 'stremsel',
      'sirilo', // SR
      'oltóanyag', // HU
      'syřidlo', // CS
    ],
    'whey': [
      'whey', 'molke', 'lactosérum', 'siero di latte', 'suero de leche',
      'peynir suyu', 'wei',
      'surutka', // SR
      'tejsavó', // HU
      'syrovátka', // CS
    ],
    'l-cysteine': [
      'l-cysteine', 'l-cystein', 'l-cystéine', 'l-cisteina', 'l-sistein',
      'l-cistein', // SR
      'l-cisztein', // HU
    ],
    'natural flavour': [
      'natural flavour', 'natural flavor', 'natürliches aroma',
      'natürliche aromen', 'arôme naturel', 'aroma naturale', 'aroma natural',
      'doğal aroma', 'natuurlijk aroma',
      'prirodna aroma', // SR
      'természetes aroma', // HU
      'přírodní aroma', // CS
    ],
    'flavouring': [
      'flavouring', 'flavoring', "aroma's", 'arôme', 'aroma naturale',
      'doğal aroma', 'natürliches aroma', 'smaakstof',
      'ízesítő', // HU
    ],
    'enzymes': [
      'enzymes', 'enzyme', 'enzimi', 'enzimas', 'enzim', 'enzymen',
      'enzymy', // CS
    ],
    'glycerol': [
      'glycerol', 'glycerin', 'glycérol', 'glicerina', 'gliserin',
      'glycerine',
      'glicerol', // SR
    ],
  };

  // All alcohol-family terms — these get the "alcohol-free" exclusion applied.
  static const Set<String> alcoholFamily = {
    'alcohol',
    'alkohol',
    'alcool',
    'alcol',
    'alkol',
    'álcool',
    'ethanol',
    'äthanol',
    'éthanol',
    'etanolo',
    'etanol',
  };

  // Fatty alcohol prefixes — NOT haram (cosmetic/food emulsifiers).
  static final RegExp fattyAlcoholPrefix = RegExp(
    r'\b(cetyl|stearyl|behenyl|lauryl|myristyl|arachidyl|oleyl|cetostearyl|'
    r'lanolin|isostearyl|octyldodecyl|decyl)\s+',
    caseSensitive: false,
  );

  // Unicode-aware word boundaries: covers Latin + extended Latin (U+00C0–U+024F)
  // so words like "šunka", "vepřové", "şarap", "pezsgő" match correctly.
  // ß (U+00DF) is added explicitly because Dart's regex engine, under
  // caseSensitive: false, case-folds ß → SS and may exclude it from the
  // À-ɏ range expansion, causing false positives in German compound words
  // like "weißweinessig" (white wine vinegar).
  static const String wPre = '(?<![a-zA-Z\\dÀ-ɏß])';
  static const String wPost = '(?![a-zA-Z\\dÀ-ɏß])';

  // Localized versions of selected ingredient reasons, keyed by
  // canonical keyword → BCP-47 language tag → translated reason.
  // Falls back to the English reason in [suspicious] / [haram] when the
  // locale is not listed here.
  static const Map<String, Map<String, String>> localizedReasons = {
    'whey': {
      'en':
          'The concern with whey is not whey itself, but the rennet used during cheese-making. If animal rennet from a non-halal source (e.g. pork-derived or improperly slaughtered cattle) was used, some scholars consider this problematic — though many hold that the transformation of the substance renders it permissible regardless. Microbial, vegetable, or halal-certified animal rennet poses no issue. In practice, whey in packaged foods is widely considered halal by the majority of scholars and certification bodies. Look for a halal logo if you want certainty; strict followers may wish to verify the rennet source with the manufacturer.',
      'de':
          'Die Bedenken bei Molke liegen nicht in der Molke selbst, sondern im Lab, das bei der Käseherstellung eingesetzt wird. Wenn tierisches Lab aus einer nicht-halal-konformen Quelle verwendet wurde – z. B. vom Schwein oder von nicht ordnungsgemäß geschlachtetem Rind –, gilt dies für manche Gelehrten als problematisch. Viele sind jedoch der Ansicht, dass die Stoffumwandlung das Produkt in jedem Fall zulässig macht. Mikrobielles, pflanzliches oder aus halal-zertifizierten Tieren stammendes Lab ist unbedenklich. In der Praxis gilt Molke in abgepackten Lebensmitteln bei der Mehrheit der islamischen Gelehrten und Zertifizierungsstellen als halal. Für Sicherheit empfiehlt sich ein Blick auf das Halal-Zertifizierungszeichen; besonders strenge Verbraucher können die Labquelle beim Hersteller erfragen.',
      'tr':
          'Peynir altı suyuyla ilgili endişe, peynir altı suyunun kendisinden değil, peynir yapımında kullanılan peynir mayasından kaynaklanır. Helal olmayan bir kaynaktan elde edilen hayvansal peynir mayası kullanıldıysa – örneğin domuz kökenli veya usulüne uygun kesilmemiş hayvandan – bazı âlimler bunu sorunlu bulmaktadır; bununla birlikte pek çok âlim, maddenin dönüşümünün onu her durumda helal kıldığı görüşündedir. Mikrobiyal, bitkisel ya da helal sertifikalı hayvanlardan elde edilen peynir mayası hiçbir sorun oluşturmaz. Pratikte, ambalajlı ürünlerdeki peynir altı suyu İslam âlimlerinin ve helal sertifikasyon kuruluşlarının büyük çoğunluğu tarafından helal kabul edilmektedir. Kesinlik için üründe helal sertifika logosunu arayın; daha titiz tüketiciler peynir mayasının kaynağını üreticiden teyit etmek isteyebilir.',
    },
    'flavouring': {
      'en':
          'Vague term — source is often unknown. May contain animal-derived extracts or alcohol-based solvents. Look for halal certification or contact the manufacturer to confirm the source.',
      'de':
          'Unklarer Begriff – die Herkunft ist oft nicht bekannt. Kann tierische Extrakte oder alkoholbasierte Lösungsmittel enthalten. Achten Sie auf ein Halal-Zertifizierungszeichen oder kontaktieren Sie den Hersteller, um die Herkunft zu bestätigen.',
      'tr':
          'Belirsiz bir terim — kaynak çoğunlukla bilinmemektedir. Hayvansal özler veya alkol bazlı çözücüler içerebilir. Kaynağı teyit etmek için helal sertifika logosunu arayın veya üreticiyle iletişime geçin.',
    },
  };

  /// Returns the localized reason for [canonical] in [languageCode], falling
  /// back to the English entry in [localizedReasons], then to the raw English
  /// string in [suspicious] / [haram].
  static String? localizedReason(String canonical, String languageCode) {
    final byLocale = localizedReasons[canonical];
    if (byLocale == null) return null;
    return byLocale[languageCode] ?? byLocale['en'];
  }
}
