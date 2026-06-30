import '../constants/ingredient_display_names.dart';
import '../constants/ingredient_keywords.dart';

enum HalalRuleVerdict { halal, haram, suspicious, unknown }

enum HalalRuleCategory { ingredient, category, certification, dataQuality }

class HalalRuleMatch {
  final String value;
  final String canonical;
  final String reason;
  final HalalRuleVerdict verdict;
  final HalalRuleCategory category;

  const HalalRuleMatch({
    required this.value,
    required this.canonical,
    required this.reason,
    required this.verdict,
    required this.category,
  });
}

class HalalRulesResult {
  final HalalRuleVerdict verdict;
  final List<String> checkedValues;
  final int checkedRuleCount;
  final List<HalalRuleMatch> matches;
  final Map<String, String> warnings;
  final Map<String, String> translations;

  /// Maps ingredient text → canonical keyword (e.g. "poudre de lactosérum" → "whey").
  /// Used by the UI to look up localized reason strings.
  final Map<String, String> canonicals;
  final String explanation;

  const HalalRulesResult({
    required this.verdict,
    required this.checkedValues,
    required this.checkedRuleCount,
    required this.matches,
    required this.warnings,
    required this.translations,
    this.canonicals = const {},
    required this.explanation,
  });

  bool get isHalal => verdict == HalalRuleVerdict.halal;

  List<String> get haram => matches
      .where((m) => m.verdict == HalalRuleVerdict.haram)
      .map((m) => m.value)
      .toList();

  List<String> get suspicious => matches
      .where((m) => m.verdict == HalalRuleVerdict.suspicious)
      .map((m) => m.value)
      .toList();
}

class HalalKeywordRuleSet {
  final Map<String, String> haram;
  final Map<String, String> suspicious;
  final Map<String, List<String>> haramVariants;
  final Map<String, List<String>> suspiciousVariants;

  const HalalKeywordRuleSet({
    this.haram = IngredientKeywords.haram,
    this.suspicious = IngredientKeywords.suspicious,
    this.haramVariants = IngredientKeywords.haramVariants,
    this.suspiciousVariants = IngredientKeywords.suspiciousVariants,
  });

  int get ruleCount => haram.length + suspicious.length;
}

class HalalRulesEngine {
  final HalalKeywordRuleSet rules;

  const HalalRulesEngine({this.rules = const HalalKeywordRuleSet()});

  static String canonicalDisplay(String canonical, String locale) =>
      IngredientDisplayNames.of(canonical, locale);

  static bool isFattyAlcohol(String ingredient) =>
      IngredientKeywords.fattyAlcoholPrefix.hasMatch(ingredient);

  // Pre-negation words in DE/FR/NL/EN/IT/ES/TR/CS/SR — word-boundary aware.
  // Used to suppress false positives like "enthält keine Zutaten vom Schwein".
  static final RegExp _negationWord = RegExp(
    r'\b(?:keine?|nicht|ohne|frei\s+von|sans|pas|geen|zonder|vrij\s+van|'
    r'no|not|without|free\s+from|free\s+of|senza|sin|'
    r'içermez|içermemektedir|icermez|icermemektedir|'
    r'neobsahuje|bez|nema|nem|mentes)\b',
    caseSensitive: false,
  );

  // Post-negation: absence markers after the keyword (EN/DE/TR trailing forms).
  // e.g. "domuz yağı ve katkıları yoktur", "gelatin-free", "schweinefrei".
  static final RegExp _postNegationWord = RegExp(
    r'(?:'
    r'[-](?:free|frei)\b'
    r'|\b(?:free|frei|yoktur|yok|bulunmamaktadır|bulunmamaktadir|bulunmaz|'
    r'içermez|içermemektedir|icermez|icermemektedir)\b'
    r'|e?frei\b'
    r')',
    caseSensitive: false,
  );

  // Returns the first variant of [canonical] that matches [valueLower], or null.
  String? _matchingVariant(String valueLower, String canonical) {
    final variants =
        rules.haramVariants[canonical] ??
        rules.suspiciousVariants[canonical] ??
        [canonical];
    for (final v in variants) {
      if (_matchesVariant(valueLower, v)) return v;
    }
    return null;
  }

  // True when the [variant] match in [chunkLower] is preceded or followed by a
  // negation marker, meaning the sentence explicitly states the ingredient is absent.
  static bool _isNegated(
    String chunkLower,
    String variant, {
    required String canonical,
  }) {
    final int start;
    final int end;
    if (variant.contains(' ')) {
      final lower = variant.toLowerCase();
      start = chunkLower.indexOf(lower);
      if (start < 0) return false;
      end = start + lower.length;
    } else {
      final escaped = RegExp.escape(variant);
      final m = RegExp(
        '${IngredientKeywords.wPre}$escaped${IngredientKeywords.wPost}',
        caseSensitive: false,
      ).firstMatch(chunkLower);
      if (m == null) return false;
      start = m.start;
      end = m.end;
    }
    if (_negationWord.hasMatch(chunkLower.substring(0, start))) return true;
    // EU "alcohol-free" / alkoholfrei labels are not reliable absence claims.
    if (canonical == 'alcohol' ||
        canonical == 'ethanol' ||
        IngredientKeywords.alcoholFamily.contains(variant.toLowerCase())) {
      return false;
    }
    return _postNegationWord.hasMatch(chunkLower.substring(end));
  }

  /// Ignores hyphens so label spellings like "mono- und" and "mono und" match.
  static String _stripHyphens(String s) => s.toLowerCase().replaceAll('-', '');

  static bool _containsPhrase(String haystack, String needle) =>
      _stripHyphens(haystack).contains(_stripHyphens(needle));

  static bool _matchesVariant(String value, String variant) {
    if (variant.contains(' ')) {
      return _containsPhrase(value, variant);
    }
    final escaped = RegExp.escape(variant);
    if (IngredientKeywords.alcoholFamily.contains(variant.toLowerCase())) {
      if (IngredientKeywords.fattyAlcoholPrefix.hasMatch(value)) return false;
      if (IngredientKeywords.isZeroPercentAlcoholDeclaration(value, variant)) {
        return false;
      }
      if (IngredientKeywords.isEuAlcoholFreeLabel(value)) return true;
      if (IngredientKeywords.hasDeclaredNonZeroAlcohol(value)) return true;
      return RegExp(
        '${IngredientKeywords.wPre}$escaped${IngredientKeywords.wPost}',
        caseSensitive: false,
      ).hasMatch(value);
    }
    if (variant == 'manteca' &&
        IngredientKeywords.isSafeMantecaContext(value)) {
      return false;
    }
    if (IngredientKeywords.compoundTailVariants.contains(variant)) {
      return RegExp(
        '${IngredientKeywords.wPreNoHyphen}$escaped${IngredientKeywords.wPost}',
        caseSensitive: false,
      ).hasMatch(value);
    }
    return RegExp(
      '${IngredientKeywords.wPre}$escaped${IngredientKeywords.wPost}',
      caseSensitive: false,
    ).hasMatch(value);
  }

  bool matchesKeyword(String value, String keyword) {
    if (keyword == 'rennet' && IngredientKeywords.isHalalRennetSource(value)) {
      return false;
    }
    final variants =
        rules.haramVariants[keyword] ??
        rules.suspiciousVariants[keyword] ??
        [keyword];
    return variants.any((v) => _matchesVariant(value, v));
  }

  HalalRulesResult analyzeIngredients(List<String> ingredients) {
    final warnings = <String, String>{};
    final translations = <String, String>{};
    final canonicals = <String, String>{};
    final matches = <HalalRuleMatch>[];

    for (final ingredient in ingredients) {
      final lower = ingredient.toLowerCase();

      var matchedHaram = false;
      for (final entry in rules.haram.entries) {
        final variant = _matchingVariant(lower, entry.key);
        if (variant != null &&
            !_isNegated(lower, variant, canonical: entry.key)) {
          warnings[ingredient] = entry.value;
          canonicals[ingredient] = entry.key;
          if (_needsTranslation(ingredient, entry.key)) {
            translations[ingredient] = entry.key;
          }
          matches.add(
            HalalRuleMatch(
              value: ingredient,
              canonical: entry.key,
              reason: entry.value,
              verdict: HalalRuleVerdict.haram,
              category: HalalRuleCategory.ingredient,
            ),
          );
          matchedHaram = true;
          break;
        }
      }
      if (matchedHaram) continue;

      for (final entry in rules.suspicious.entries) {
        final variant = _matchingVariant(lower, entry.key);
        if (variant != null &&
            entry.key == 'rennet' &&
            IngredientKeywords.isHalalRennetSource(lower)) {
          continue;
        }
        if (variant != null &&
            !_isNegated(lower, variant, canonical: entry.key)) {
          warnings[ingredient] = entry.value;
          canonicals[ingredient] = entry.key;
          if (_needsTranslation(ingredient, entry.key)) {
            translations[ingredient] = entry.key;
          }
          matches.add(
            HalalRuleMatch(
              value: ingredient,
              canonical: entry.key,
              reason: entry.value,
              verdict: HalalRuleVerdict.suspicious,
              category: HalalRuleCategory.ingredient,
            ),
          );
          break;
        }
      }
    }

    final verdict = matches.any((m) => m.verdict == HalalRuleVerdict.haram)
        ? HalalRuleVerdict.haram
        : matches.any((m) => m.verdict == HalalRuleVerdict.suspicious)
        ? HalalRuleVerdict.suspicious
        : HalalRuleVerdict.halal;

    return HalalRulesResult(
      verdict: verdict,
      checkedValues: List.unmodifiable(ingredients),
      checkedRuleCount: rules.ruleCount,
      matches: matches,
      warnings: warnings,
      translations: translations,
      canonicals: canonicals,
      explanation: _ingredientExplanation(ingredients, matches),
    );
  }

  HalalRulesEngine merge(HalalKeywordRuleSet customRules) => HalalRulesEngine(
    rules: HalalKeywordRuleSet(
      haram: {...rules.haram, ...customRules.haram},
      suspicious: {...rules.suspicious, ...customRules.suspicious},
      haramVariants: {...rules.haramVariants, ...customRules.haramVariants},
      suspiciousVariants: {
        ...rules.suspiciousVariants,
        ...customRules.suspiciousVariants,
      },
    ),
  );

  static bool _needsTranslation(String ingredient, String canonical) {
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[-\s]'), '');
    return !norm(ingredient).contains(norm(canonical));
  }

  static String _ingredientExplanation(
    List<String> ingredients,
    List<HalalRuleMatch> matches,
  ) {
    final haram = matches
        .where((m) => m.verdict == HalalRuleVerdict.haram)
        .map((m) => m.value)
        .toList();
    if (haram.isNotEmpty) {
      return 'This product contains ingredient(s) that are not permissible: '
          '${haram.join(', ')}. '
          'Assessed by keyword matching against known haram ingredients.';
    }

    final suspicious = matches
        .where((m) => m.verdict == HalalRuleVerdict.suspicious)
        .map((m) => m.value)
        .toList();
    if (suspicious.isNotEmpty) {
      final canonicals = {
        for (final m in matches.where(
          (m) => m.verdict == HalalRuleVerdict.suspicious,
        ))
          m.value: m.canonical,
      };
      return IngredientKeywords.buildSuspiciousExplanation(
        suspicious: suspicious,
        canonicals: canonicals,
        labels: const [],
        productName: '',
      );
    }

    if (ingredients.isEmpty) {
      return 'No ingredient data available to analyze.';
    }
    return 'No haram or suspicious ingredients were detected in the ingredient '
        'list. Assessed by keyword matching against known haram ingredients.';
  }
}
