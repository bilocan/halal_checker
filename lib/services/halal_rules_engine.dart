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

  bool get isHalal => verdict != HalalRuleVerdict.haram;

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

  // Negation words in DE/FR/NL/EN/IT/ES/TR/CS/SR — word-boundary aware.
  // Used to suppress false positives like "enthält keine Zutaten vom Schwein".
  static final RegExp _negationWord = RegExp(
    r'\b(?:keine?|nicht|ohne|frei\s+von|sans|pas|geen|zonder|vrij\s+van|'
    r'no|not|without|free\s+from|free\s+of|senza|sin|içermez|içermemektedir|'
    r'neobsahuje|bez|nema|nem|mentes)\b',
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

  // True when the [variant] match in [chunkLower] is preceded by a negation word,
  // meaning the sentence explicitly states the ingredient is absent.
  static bool _isNegated(String chunkLower, String variant) {
    final int idx;
    if (variant.contains(' ')) {
      idx = chunkLower.indexOf(variant.toLowerCase());
    } else {
      final escaped = RegExp.escape(variant);
      final m = RegExp(
        '${IngredientKeywords.wPre}$escaped${IngredientKeywords.wPost}',
        caseSensitive: false,
      ).firstMatch(chunkLower);
      idx = m?.start ?? -1;
    }
    if (idx < 0) return false;
    return _negationWord.hasMatch(chunkLower.substring(0, idx));
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
      return RegExp(
        '${IngredientKeywords.wPre}$escaped${IngredientKeywords.wPost}(?![-\\s]*free)',
        caseSensitive: false,
      ).hasMatch(value);
    }
    return RegExp(
      '${IngredientKeywords.wPre}$escaped${IngredientKeywords.wPost}',
      caseSensitive: false,
    ).hasMatch(value);
  }

  bool matchesKeyword(String value, String keyword) {
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
        if (variant != null && !_isNegated(lower, variant)) {
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
        if (variant != null && !_isNegated(lower, variant)) {
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
      return 'No definitively haram ingredients were found, but the following '
          'may be animal-derived and require verification: '
          '${suspicious.join(', ')}. '
          'Assessed by keyword matching.';
    }

    if (ingredients.isEmpty) {
      return 'No ingredient data available to analyze.';
    }
    return 'No haram or suspicious ingredients were detected in the ingredient '
        'list. Assessed by keyword matching against known haram ingredients.';
  }
}
