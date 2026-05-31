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
    'bacon': 'Contains pork product',
    'ham': 'Contains pork product',
    'pepperoni': 'Contains pork product',
    'salami': 'Contains pork product',
    'chorizo': 'Contains pork product',
    'prosciutto': 'Contains pork product',
    'carmine': 'Carmine/cochineal is insect-derived',
    'cochineal': 'Carmine/cochineal is insect-derived',
    'e120': 'Carmine/cochineal color, animal-derived',
    'e542': 'Bone phosphate, animal-derived',
    'e904': 'Shellac, animal-derived',
  };

  static const Map<String, String> suspicious = {
    'gelatin':
        'Gelatin source often unspecified — predominantly pork-derived in Western products',
    'e441':
        'Gelatin (E441), source often unspecified — predominantly pork-derived',
    'e920': 'L-cysteine may be animal-derived',
    'e322': 'Lecithin may be animal-derived',
    'e471': 'Mono- and diglycerides may be animal-derived',
    'e472': 'Emulsifiers may be animal-derived',
    'e473': 'Sucrose esters may be animal-derived',
    'e927': 'Glycine may be animal-derived',
    'e422': 'Glycerol may be animal-derived',
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
      'budweiser', 'heineken', 'corona', 'stella artois', 'carlsberg',
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
      'свинско', 'свински', 'свинска', 'свинско месо', 'свинска месо', // BG
    ],
    'lard': [
      'lard', 'schmalz', 'schweineschmalz', 'saindoux', 'strutto', 'manteca',
      'domuz yağı', 'banha',
      'svinjska mast', // SR
      'sertészsír', // HU
      'sádlo', // CS
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
    'e542': ['e542', 'e-542'],
    'e904': ['e904', 'e-904'],
  };

  static const Map<String, List<String>> suspiciousVariants = {
    'gelatin': [
      'gelatin', 'gelatine', 'gelatina', 'jelatin', 'gélatine',
      'želatina', // SR / CS
      'zselatin', // HU
    ],
    'e441': ['e441', 'e-441'],
    'e920': ['e920', 'e-920'],
    'e322': ['e322', 'e-322'],
    'e471': ['e471', 'e-471', 'mono- und diglyceride von speisefettsäuren'],
    'e472': ['e472', 'e-472'],
    'e473': ['e473', 'e-473'],
    'e927': ['e927', 'e-927'],
    'e422': ['e422', 'e-422'],
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

  // Per-language display labels, keyed by canonical → BCP-47 lang → list of display terms.
  // Used by the web rule tester for per-language highlighting; not used for matching.
  static const Map<String, Map<String, List<String>>> haramByLang = {
    'alcohol': {
      'en': ['alcohol'],
      'de': ['alkohol'],
      'fr': ['alcool'],
      'it': ['alcol'],
      'tr': ['alkol'],
    },
    'ethanol': {
      'en': ['ethanol'],
      'de': ['äthanol'],
      'fr': ['éthanol'],
      'it': ['etanolo'],
      'tr': ['etanol'],
      'es': ['etanol'],
    },
    'wine': {
      'en': ['wine'],
      'de': ['wein'],
      'fr': ['vin'],
      'it': ['vino'],
      'tr': ['şarap'],
      'es': ['vino'],
      'nl': ['wijn'],
      'hu': ['bor'],
      'cs': ['víno'],
    },
    'beer': {
      'en': ['beer'],
      'de': ['bier'],
      'fr': ['bière'],
      'it': ['birra'],
      'tr': ['bira'],
      'es': ['cerveza'],
      'sr': ['pivo'],
      'hu': ['sör'],
      'cs': ['pivo'],
    },
    'cognac': {
      'en': ['cognac'],
      'de': ['kognak'],
      'tr': ['konyak'],
      'sr': ['konjak'],
      'hu': ['konyak'],
      'cs': ['koňak'],
    },
    'brandy': {
      'en': ['brandy'],
      'de': ['branntwein'],
      'nl': ['brandewijn'],
    },
    'whisky': {
      'en': ['whisky', 'whiskey'],
      'de': ['whisky'],
      'tr': ['viski'],
    },
    'vodka': {
      'en': ['vodka'],
      'de': ['wodka'],
      'tr': ['votka'],
      'sr': ['votka'],
    },
    'rum': {
      'en': ['rum'],
      'fr': ['rhum'],
      'es': ['ron'],
    },
    'gin': {
      'en': ['gin'],
      'sr': ['džin'],
    },
    'liqueur': {
      'en': ['liqueur'],
      'de': ['likör'],
      'fr': ['liqueur'],
      'it': ['liquore'],
      'es': ['licor'],
      'nl': ['likeur'],
      'sr': ['liker'],
      'hu': ['likőr'],
      'cs': ['likér'],
    },
    'schnapps': {
      'en': ['schnapps'],
      'de': ['schnaps'],
      'sr': ['šnaps'],
    },
    'champagne': {
      'en': ['champagne'],
      'de': ['sekt'],
      'it': ['spumante'],
      'es': ['cava'],
      'sr': ['šampanjac'],
      'hu': ['pezsgő'],
      'cs': ['šampaňské'],
    },
    'prosecco': {
      'en': ['prosecco'],
    },
    'bourbon': {
      'en': ['bourbon'],
    },
    'sake': {
      'en': ['sake', 'saké'],
    },
    'pork': {
      'en': ['pork'],
      'de': ['schwein', 'schweinefleisch'],
      'fr': ['porc'],
      'it': ['maiale'],
      'tr': ['domuz'],
      'es': ['cerdo'],
      'nl': ['varkens', 'varkensvlees'],
      'sr': ['svinjetina', 'svinjsko'],
      'hu': ['sertéshús', 'sertés'],
      'cs': ['vepřové', 'vepřová'],
    },
    'lard': {
      'en': ['lard'],
      'de': ['schmalz', 'schweineschmalz'],
      'fr': ['saindoux'],
      'it': ['strutto'],
      'tr': ['domuz yağı'],
      'es': ['manteca'],
      'sr': ['svinjska mast'],
      'hu': ['sertészsír'],
      'cs': ['sádlo'],
    },
    'bacon': {
      'en': ['bacon'],
      'de': ['speck'],
      'fr': ['lardons'],
      'it': ['pancetta'],
      'tr': ['domuz pastırması'],
      'sr': ['slanina'],
      'hu': ['szalonna'],
      'cs': ['slanina'],
    },
    'ham': {
      'en': ['ham'],
      'de': ['schinken'],
      'fr': ['jambon'],
      'it': ['prosciutto'],
      'tr': ['jambon'],
      'es': ['jamón'],
      'sr': ['šunka'],
      'hu': ['sonka'],
      'cs': ['šunka'],
    },
    'pepperoni': {
      'en': ['pepperoni'],
    },
    'salami': {
      'en': ['salami'],
      'it': ['salame'],
      'hu': ['szalámi'],
      'cs': ['salám'],
    },
    'chorizo': {
      'en': ['chorizo'],
    },
    'prosciutto': {
      'en': ['prosciutto'],
    },
    'carmine': {
      'en': ['carmine'],
      'de': ['karmin'],
      'fr': ['carmin'],
      'es': ['carmín'],
      'cs': ['karmín'],
    },
    'cochineal': {
      'en': ['cochineal'],
      'de': ['cochenille'],
      'fr': ['cochenille'],
      'it': ['cocciniglia'],
      'es': ['cochinilla'],
      'tr': ['koşnil'],
      'sr': ['košenil'],
      'cs': ['košenila'],
    },
    'e120': {
      'en': ['e120', 'e-120'],
    },
    'e542': {
      'en': ['e542', 'e-542'],
    },
    'e904': {
      'en': ['e904', 'e-904'],
    },
  };

  static const Map<String, Map<String, List<String>>> suspiciousByLang = {
    'gelatin': {
      'en': ['gelatin', 'gelatine'],
      'de': ['gelatine'],
      'fr': ['gélatine'],
      'it': ['gelatina'],
      'tr': ['jelatin'],
      'es': ['gelatina'],
      'sr': ['želatina'],
      'hu': ['zselatin'],
      'cs': ['želatina'],
    },
    'e441': {
      'en': ['e441', 'e-441'],
    },
    'e920': {
      'en': ['e920', 'e-920'],
    },
    'e322': {
      'en': ['e322', 'e-322'],
    },
    'e471': {
      'en': ['e471', 'e-471'],
      'de': ['mono- und diglyceride von speisefettsäuren'],
    },
    'e472': {
      'en': ['e472', 'e-472'],
    },
    'e473': {
      'en': ['e473', 'e-473'],
    },
    'e927': {
      'en': ['e927', 'e-927'],
    },
    'e422': {
      'en': ['e422', 'e-422'],
    },
    'rennet': {
      'en': ['rennet'],
      'de': ['lab', 'labferment'],
      'fr': ['présure'],
      'it': ['caglio'],
      'tr': ['peynir mayası'],
      'es': ['cuajo'],
      'nl': ['stremsel'],
      'sr': ['sirilo'],
      'hu': ['oltóanyag'],
      'cs': ['syřidlo'],
    },
    'whey': {
      'en': ['whey'],
      'de': ['molke'],
      'fr': ['lactosérum'],
      'it': ['siero di latte'],
      'tr': ['peynir suyu'],
      'es': ['suero de leche'],
      'nl': ['wei'],
      'sr': ['surutka'],
      'hu': ['tejsavó'],
      'cs': ['syrovátka'],
    },
    'l-cysteine': {
      'en': ['l-cysteine'],
      'de': ['l-cystein'],
      'fr': ['l-cystéine'],
      'it': ['l-cisteina'],
      'tr': ['l-sistein'],
      'sr': ['l-cistein'],
      'hu': ['l-cisztein'],
    },
    'natural flavour': {
      'en': ['natural flavour', 'natural flavor'],
      'de': ['natürliches aroma', 'natürliche aromen'],
      'fr': ['arôme naturel'],
      'it': ['aroma naturale'],
      'tr': ['doğal aroma'],
      'es': ['aroma natural'],
      'nl': ['natuurlijk aroma'],
      'sr': ['prirodna aroma'],
      'hu': ['természetes aroma'],
      'cs': ['přírodní aroma'],
    },
    'flavouring': {
      'en': ['flavouring', 'flavoring'],
      'de': ['natürliches aroma'],
      'fr': ['arôme'],
      'it': ['aroma naturale'],
      'tr': ['doğal aroma'],
      'nl': ["aroma's", 'smaakstof'],
      'hu': ['ízesítő'],
    },
    'enzymes': {
      'en': ['enzymes', 'enzyme'],
      'it': ['enzimi'],
      'es': ['enzimas'],
      'tr': ['enzim'],
      'nl': ['enzymen'],
      'cs': ['enzymy'],
    },
    'glycerol': {
      'en': ['glycerol', 'glycerin', 'glycerine'],
      'fr': ['glycérol'],
      'it': ['glicerina'],
      'tr': ['gliserin'],
      'es': ['glicerina'],
      'sr': ['glicerol'],
    },
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

  /// True when [text] declares zero alcohol for [variant] (e.g. "0% alcohol").
  static bool isZeroPercentAlcoholDeclaration(String text, String variant) {
    final v = RegExp.escape(variant);
    return RegExp(
      r'\b0(?:[.,]0+)?\s*%\s*' +
          v +
          r'(?:\b|(?![a-zA-Z\dÀ-ɏß]))' +
          r'|\b' +
          v +
          r'(?:\b|(?![a-zA-Z\dÀ-ɏß]))\s*(?:\(?\s*)?0(?:[.,]0+)?\s*%',
      caseSensitive: false,
    ).hasMatch(text);
  }

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
    'gelatin': {
      'en':
          'Gelatin source is often unspecified on packaging. In Western markets it is predominantly pork-derived, making it not halal unless explicitly labelled as fish gelatin, beef gelatin from a halal-slaughtered animal, or a plant-based alternative. Look for a halal logo or the words "beef gelatin" / "fish gelatin"; strict followers should contact the manufacturer to confirm the source.',
      'de':
          'Die Herkunft von Gelatine ist auf der Verpackung häufig nicht angegeben. In westlichen Märkten stammt sie überwiegend vom Schwein und ist daher nicht halal, sofern sie nicht ausdrücklich als Fischgelatine, Rindergelatine aus halal-geschlachtetem Tier oder pflanzliche Alternative deklariert ist. Achten Sie auf ein Halal-Zertifizierungszeichen oder die Angabe „Rindergelatine" / „Fischgelatine"; besonders strenge Verbraucher können die Herkunft beim Hersteller erfragen.',
      'tr':
          'Jelatin kaynağı ambalajda çoğunlukla belirtilmez. Batı pazarlarında jelatin büyük ölçüde domuzdan elde edilmekte olup açıkça balık jelatini, helal kesimli sığır jelatini veya bitkisel alternatif olarak etiketlenmediği sürece helal değildir. Helal sertifika logosunu veya "sığır jelatini" / "balık jelatini" ibaresini arayın; daha titiz tüketiciler kaynağı üreticiden teyit etmek isteyebilir.',
    },
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
