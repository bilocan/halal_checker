import '../models/product.dart';
import '../services/halal_rules_engine.dart';
import 'site_urls.dart';

/// Localized title + description for a blog guide card.
class IngredientGuideCopy {
  const IngredientGuideCopy({
    required this.titleEn,
    required this.descriptionEn,
    this.titleDe,
    this.descriptionDe,
    this.titleTr,
    this.descriptionTr,
  });

  final String titleEn;
  final String descriptionEn;
  final String? titleDe;
  final String? descriptionDe;
  final String? titleTr;
  final String? descriptionTr;

  String titleFor(String locale) => switch (locale) {
    'de' => titleDe ?? titleEn,
    'tr' => titleTr ?? titleEn,
    _ => titleEn,
  };

  String descriptionFor(String locale) => switch (locale) {
    'de' => descriptionDe ?? descriptionEn,
    'tr' => descriptionTr ?? descriptionEn,
    _ => descriptionEn,
  };
}

/// Resolved guide ready for UI.
class IngredientGuideLink {
  const IngredientGuideLink({
    required this.slug,
    required this.title,
    required this.description,
    required this.url,
  });

  final String slug;
  final String title;
  final String description;
  final String url;
}

/// Maps rule-engine canonical keys to blog slugs.
///
/// Keep in sync with `halal-checker-web/lib/ingredient-guides.ts`.
/// Exported via `tool/export_rules.dart` → `keyword-rules.json` → Supabase.
class IngredientGuides {
  IngredientGuides._();

  static const Map<String, List<String>> byCanonical = {
    'natural flavour': ['gida-aromalarinda-alkol'],
    'flavouring': [
      'gida-aromalarinda-alkol',
      'mono-propylene-glycol-halal-alternative',
    ],
    'e120': ['carmine-e120'],
    'carmine': ['carmine-e120'],
    'cochineal': ['carmine-e120'],
    'gelatin': ['what-is-gelatin'],
    'e441': ['what-is-gelatin'],
    'e920': ['e-numbers-guide'],
    'l-cysteine': ['e-numbers-guide'],
    'e322': ['e-numbers-guide'],
    'e471': ['e-numbers-guide'],
    'e472': ['e-numbers-guide'],
    'e473': ['e-numbers-guide'],
    'e927': ['e-numbers-guide'],
    'glycerol': ['e-numbers-guide'],
  };

  static const Map<String, IngredientGuideCopy> copyBySlug = {
    'gida-aromalarinda-alkol': IngredientGuideCopy(
      titleEn: 'Alcohol in food flavorings',
      descriptionEn:
          'Most flavorings used in the food industry are essences dissolved in alcohol. The majority of Islamic scholars hold that foods containing aroma extracted in alcohol are not halal.',
      titleDe: 'Alkohol in Lebensmittelaromen',
      descriptionDe:
          'Die meisten in der Lebensmittelindustrie verwendeten Aromen sind in Alkohol gelöste Essenzen. Die Mehrheit islamischer Gelehrter ist der Ansicht, dass Lebensmittel mit in Alkohol extrahiertem Aroma nicht halal sind.',
      titleTr: 'Gıda aromalarında alkol',
      descriptionTr:
          'Gıda sanayinde kullanılan aromaların çoğu alkolde eritilmiş esanslardan oluşur. İslam düşünürlerinin çoğu, alkol içinde eritilmiş aroma ihtiva eden gıdanın helal olmadığı görüşündedir.',
    ),
    'mono-propylene-glycol-halal-alternative': IngredientGuideCopy(
      titleEn:
          'Is mono propylene glycol a halal alternative in food flavorings?',
      descriptionEn:
          'A short Q&A on why alcohol-based aromas are problematic, what E1520 is, and why mono propylene glycol is widely used as a halal solvent carrier instead.',
      titleDe:
          'Ist Monopropylenglykol eine halal-Alternative in Lebensmittelaromen?',
      descriptionDe:
          'Kurzes Q&A: Warum alkoholbasierte Aromen problematisch sind, was E1520 ist und warum Monopropylenglykol oft als halal-freundlicher Trägerstoff statt Ethanol verwendet wird.',
      titleTr: 'Mono propilen glikol gıda aromalarında helal alternatif midir?',
      descriptionTr:
          'Alkollü aromalar neden sorunlu, E1520 nedir ve mono propilen glikol neden çoğu zaman etanol yerine helal taşıyıcı olarak kullanılır — kısa soru-cevap.',
    ),
    'carmine-e120': IngredientGuideCopy(
      titleEn: 'Is carmine (E120) halal?',
      descriptionEn:
          'Carmine is a red food coloring made from crushed insects. It appears in yogurt, juice, candy, and cosmetics.',
      titleDe: 'Ist Karmin (E120) halal?',
      descriptionDe:
          'Karmin ist ein roter Lebensmittelfarbstoff aus zerkleinerten Insekten. Er kommt in Joghurt, Säften, Süßigkeiten und Kosmetik vor.',
      titleTr: 'Karmin (E120) helal midir?',
      descriptionTr:
          'Karmin, ezilmiş böceklerden elde edilen kırmızı bir gıda boyasıdır. Yoğurt, meyve suyu, şekerleme ve kozmetikte görülür.',
    ),
    'what-is-gelatin': IngredientGuideCopy(
      titleEn: 'What is gelatin and why is it haram?',
      descriptionEn:
          'Gelatin is one of the most common hidden animal-derived ingredients in processed foods.',
      titleDe: 'Was ist Gelatine und warum ist sie haram?',
      descriptionDe:
          'Gelatine ist einer der häufigsten versteckten tierischen Inhaltsstoffe in verarbeiteten Lebensmitteln.',
      titleTr: 'Jelatin nedir ve neden haramdır?',
      descriptionTr:
          'Jelatin, işlenmiş gıdalarda en yaygın gizli hayvansal içeriklerden biridir.',
    ),
    'e-numbers-guide': IngredientGuideCopy(
      titleEn: "The Muslim's guide to E-numbers",
      descriptionEn:
          'E-numbers are EU codes for food additives. Some are derived from haram sources.',
      titleDe: 'Der muslimische Leitfaden zu E-Nummern',
      descriptionDe:
          'E-Nummern sind EU-Codes für Lebensmittelzusatzstoffe. Einige stammen aus haramen Quellen.',
      titleTr: 'Müslümanlar için E-numaraları rehberi',
      descriptionTr:
          'E-numaraları, gıda katkı maddeleri için AB kodlarıdır. Bazıları haram kaynaklardan elde edilir.',
    ),
  };

  static const _engine = HalalRulesEngine();

  static Map<String, List<String>> _runtimeByCanonical = {};
  static Map<String, IngredientGuideCopy> _runtimeCopyBySlug = {};

  /// Clears DB-provided slugs and slug copy (tests and [ProductService.resetForTesting]).
  static void resetRuntimeGuides() {
    _runtimeByCanonical = {};
    _runtimeCopyBySlug = {};
  }

  static void registerRuntimeGuides(Map<String, List<String>> fromDb) {
    _runtimeByCanonical = {
      for (final entry in fromDb.entries)
        entry.key: List.unmodifiable(entry.value),
    };
  }

  static void registerRuntimeSlugCopy(Map<String, IngredientGuideCopy> fromDb) {
    _runtimeCopyBySlug = Map.unmodifiable(fromDb);
  }

  /// Built-in [copyBySlug] first, then DB [ingredient_guide_slug_metadata].
  static IngredientGuideCopy? copyForSlug(String slug) =>
      copyBySlug[slug] ?? _runtimeCopyBySlug[slug];

  static String normalizeFlaggedTerm(String term) {
    var s = term.trim();
    final colon = s.indexOf(':');
    if (colon > 0 && colon <= 3) {
      s = s.substring(colon + 1);
    }
    return s.replaceAll('-', ' ').trim();
  }

  /// Built-in slugs first, then DB slugs; deduped (union, not override).
  static List<String> slugsForCanonical(String canonical) => unionSlugLists(
    byCanonical[canonical] ?? const [],
    _runtimeByCanonical[canonical] ?? const [],
  );

  /// Union helper for admin UI before runtime registration is refreshed.
  static List<String> unionSlugsForCanonical(
    String canonical,
    Map<String, List<String>> dbByCanonical,
  ) => unionSlugLists(
    byCanonical[canonical] ?? const [],
    dbByCanonical[canonical] ?? const [],
  );

  static List<String> unionSlugLists(
    List<String> builtIn,
    List<String> dbSlugs,
  ) {
    if (builtIn.isEmpty && dbSlugs.isEmpty) return const [];
    final seen = <String>{};
    final merged = <String>[];
    for (final slug in [...builtIn, ...dbSlugs]) {
      if (seen.add(slug)) merged.add(slug);
    }
    return List.unmodifiable(merged);
  }

  static String fallbackTitleForSlug(String slug) {
    return slug
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String? canonicalForTerm(
    String term, {
    Map<String, String> storedCanonicals = const {},
  }) {
    final stored = storedCanonicals[term];
    if (stored != null) return stored;

    final normalized = normalizeFlaggedTerm(term);
    if (normalized.isEmpty) return null;

    final result = _engine.analyzeIngredients([normalized]);
    if (result.matches.isEmpty) return null;
    return result.matches.first.canonical;
  }

  /// Deduped guide slugs for all flagged ingredients and additives on [product].
  static List<String> slugsForProduct(Product product) {
    final flagged = <String>[
      ...product.haramIngredients,
      ...product.suspiciousIngredients,
      ...product.haramAdditives,
      ...product.suspiciousAdditives,
    ];

    final seen = <String>{};
    final slugs = <String>[];

    for (final term in flagged) {
      final canonical = canonicalForTerm(
        term,
        storedCanonicals: product.ingredientCanonicals,
      );
      if (canonical == null) continue;
      for (final slug in slugsForCanonical(canonical)) {
        if (seen.add(slug)) slugs.add(slug);
      }
    }

    return slugs;
  }

  /// Guide links for a single flagged term (ingredient, additive tag, or label).
  static List<IngredientGuideLink> linksForTerm(
    String term,
    String locale, {
    Map<String, String> storedCanonicals = const {},
  }) {
    final canonical = canonicalForTerm(
      term,
      storedCanonicals: storedCanonicals,
    );
    if (canonical == null) return const [];

    return slugsForCanonical(
      canonical,
    ).map((slug) => linkForSlug(slug, locale)).toList(growable: false);
  }

  static List<IngredientGuideLink> linksForProduct(
    Product product,
    String locale,
  ) {
    return slugsForProduct(
      product,
    ).map((slug) => linkForSlug(slug, locale)).toList(growable: false);
  }

  static IngredientGuideLink linkForSlug(String slug, String locale) {
    final copy = copyForSlug(slug);
    return IngredientGuideLink(
      slug: slug,
      title: copy?.titleFor(locale) ?? fallbackTitleForSlug(slug),
      description: copy?.descriptionFor(locale) ?? '',
      url: SiteUrls.blogGuide(locale, slug),
    );
  }
}
