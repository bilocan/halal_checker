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
  final String explanation;

  const HalalRulesResult({
    required this.verdict,
    required this.checkedValues,
    required this.checkedRuleCount,
    required this.matches,
    required this.warnings,
    required this.translations,
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

  static bool _matchesVariant(String value, String variant) {
    if (variant.contains(' ')) {
      return value.toLowerCase().contains(variant.toLowerCase());
    }
    final escaped = RegExp.escape(variant);
    if (IngredientKeywords.alcoholFamily.contains(variant.toLowerCase())) {
      if (IngredientKeywords.fattyAlcoholPrefix.hasMatch(value)) return false;
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
    final matches = <HalalRuleMatch>[];

    for (final ingredient in ingredients) {
      final lower = ingredient.toLowerCase();

      var matchedHaram = false;
      for (final entry in rules.haram.entries) {
        if (matchesKeyword(lower, entry.key)) {
          warnings[ingredient] = entry.value;
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
        if (matchesKeyword(lower, entry.key)) {
          warnings[ingredient] = entry.value;
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
