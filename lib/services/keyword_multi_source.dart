import 'ingredient_resolution.dart';
import 'halal_rules_engine.dart';

class KeywordMultiSourceResult {
  const KeywordMultiSourceResult({
    required this.isHalal,
    required this.isUnknown,
    required this.haram,
    required this.suspicious,
    required this.warnings,
    required this.translations,
    required this.canonicals,
    required this.explanation,
    this.keywordMatchSource,
    this.keywordMatchOrigins = const {},
    this.analyzeLang,
  });

  final bool isHalal;
  final bool isUnknown;
  final List<String> haram;
  final List<String> suspicious;
  final Map<String, String> warnings;
  final Map<String, String> translations;
  final Map<String, String> canonicals;
  final String explanation;
  final String? keywordMatchSource;
  final Map<String, String> keywordMatchOrigins;
  final String? analyzeLang;
}

/// Runs keyword matching across multiple ingredient sources (language fallback, taxonomy).
KeywordMultiSourceResult analyzeIngredientsFromSources({
  required HalalRulesEngine engine,
  required List<IngredientAnalysisSource> sources,
  required List<String> displayIngredients,
  String? analyzeLang,
}) {
  final haram = <String>[];
  final suspicious = <String>[];
  final warnings = <String, String>{};
  final translations = <String, String>{};
  final canonicals = <String, String>{};
  final matchOrigins = <String, String>{};
  final matchedSourceKeys = <String>[];
  final seenHaram = <String>{};
  final seenSuspicious = <String>{};

  for (final source in sources) {
    final result = engine.analyzeIngredients(source.ingredients);
    if (result.haram.isNotEmpty || result.suspicious.isNotEmpty) {
      matchedSourceKeys.add(source.key);
    }
    for (final ing in result.haram) {
      final key = ing.toLowerCase();
      if (seenHaram.add(key)) haram.add(ing);
      matchOrigins[ing] = source.key;
      warnings[ing] = result.warnings[ing] ?? '';
      if (result.translations.containsKey(ing)) {
        translations[ing] = result.translations[ing]!;
      }
      if (result.canonicals.containsKey(ing)) {
        canonicals[ing] = result.canonicals[ing]!;
      }
    }
    for (final ing in result.suspicious) {
      final key = ing.toLowerCase();
      if (seenSuspicious.add(key)) suspicious.add(ing);
      matchOrigins[ing] = source.key;
      warnings[ing] = result.warnings[ing] ?? warnings[ing] ?? '';
      if (result.translations.containsKey(ing)) {
        translations[ing] = result.translations[ing]!;
      }
      if (result.canonicals.containsKey(ing)) {
        canonicals[ing] = result.canonicals[ing]!;
      }
    }
  }

  final primaryText = displayIngredients.join(', ');
  final hasLangFallback = sources.any(
    (s) =>
        s.key.startsWith('off_') &&
        s.key != 'off_taxonomy' &&
        s.ingredients.isNotEmpty,
  );

  // Primary label unreadable and no translated OFF text — unknown even when
  // taxonomy IDs exist but matched nothing (e.g. bg:pork + en:water only).
  final isUnanalyzableLanguage =
      displayIngredients.isNotEmpty &&
      haram.isEmpty &&
      suspicious.isEmpty &&
      !isAnalyzableScript(primaryText) &&
      !hasLangFallback;

  final isUnknown = displayIngredients.isEmpty || isUnanalyzableLanguage;

  final explanation = _buildExplanation(
    haram,
    suspicious,
    displayIngredients.isEmpty,
    isUnanalyzableLanguage,
  );

  final keywordMatchSource = isUnanalyzableLanguage
      ? 'unanalyzable'
      : combineMatchSourceKeys(matchedSourceKeys);

  return KeywordMultiSourceResult(
    isHalal: !isUnknown && haram.isEmpty && suspicious.isEmpty,
    isUnknown: isUnknown,
    haram: haram,
    suspicious: suspicious,
    warnings: warnings,
    translations: translations,
    canonicals: canonicals,
    explanation: explanation,
    keywordMatchSource: keywordMatchSource,
    keywordMatchOrigins: matchOrigins,
    analyzeLang: analyzeLang,
  );
}

String _buildExplanation(
  List<String> haram,
  List<String> suspicious,
  bool noIngredients,
  bool isUnanalyzableLanguage,
) {
  if (haram.isNotEmpty) {
    return 'This product contains ingredient(s) that are not permissible: '
        '${haram.join(', ')}. Assessed by keyword matching.';
  }
  if (suspicious.isNotEmpty) {
    return 'No definitively haram ingredients found, but the following may be '
        'animal-derived: ${suspicious.join(', ')}. Assessed by keyword matching.';
  }
  if (isUnanalyzableLanguage) {
    return 'Ingredients are in a language we cannot analyze. Halal status cannot '
        'be determined — check the packaging directly.';
  }
  if (noIngredients) {
    return 'No ingredient data found. Halal status cannot be determined — '
        'check the packaging directly.';
  }
  return 'No haram or suspicious ingredients detected. Assessed by keyword matching.';
}
