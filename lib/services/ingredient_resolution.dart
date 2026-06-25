/// Resolves which OFF ingredient text to display vs analyze for keyword matching.
library;

/// Locales covered by built-in keyword variant lists.
const keywordLocales = [
  'en',
  'de',
  'fr',
  'tr',
  'es',
  'it',
  'nl',
  'sr',
  'hu',
  'cs',
];

class IngredientAnalysisSource {
  const IngredientAnalysisSource({
    required this.key,
    required this.ingredients,
  });

  final String key;
  final List<String> ingredients;
}

class ResolvedOffIngredients {
  const ResolvedOffIngredients({
    required this.display,
    required this.sources,
    required this.displayLang,
    required this.analyzeLang,
  });

  final List<String> display;
  final List<IngredientAnalysisSource> sources;
  final String displayLang;
  final String? analyzeLang;
}

final _latinLetter = RegExp(r'[a-zA-Z\dÀ-ɏß]', unicode: true);
final _cyrillicLetter = RegExp(r'[\u0400-\u04FF]', unicode: true);
final _arabicLetter = RegExp(r'[\u0600-\u06FF]', unicode: true);
final _cjkLetter = RegExp(
  r'[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]',
  unicode: true,
);
final _eNumber = RegExp(r'\be-?\s?\d{3,4}\b', caseSensitive: false);

/// Placeholder tokens that are not real ingredients (e.g. "UNKNOWN.").
final _placeholderIngredient = RegExp(
  r'^unknown[.!?,;:]*$',
  caseSensitive: false,
);

List<String> splitIngredientText(String text) {
  return text
      .split(RegExp(r'[,;]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && !_placeholderIngredient.hasMatch(s))
      .toList();
}

List<String> parseDisplayIngredientList(Map<String, dynamic> pd) {
  var text = (pd['ingredients_text'] ?? '').toString().trim();
  if (text.isEmpty) {
    final structured = pd['ingredients'];
    if (structured is List && structured.isNotEmpty) {
      text = structured
          .whereType<Map>()
          .map((i) => i['text']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .join(', ');
    }
  }
  return splitIngredientText(text.toLowerCase());
}

bool isAnalyzableScript(String text) {
  if (text.trim().isEmpty) return false;
  if (_eNumber.hasMatch(text)) return true;

  var latin = 0;
  var nonLatin = 0;
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (RegExp(r'\s|[\d.,()%\-_]', unicode: true).hasMatch(ch)) continue;
    if (_latinLetter.hasMatch(ch)) {
      latin++;
    } else if (_cyrillicLetter.hasMatch(ch) ||
        _arabicLetter.hasMatch(ch) ||
        _cjkLetter.hasMatch(ch)) {
      nonLatin++;
    }
  }
  if (latin == 0 && nonLatin == 0) return true;
  if (latin == 0 && nonLatin > 0) return false;
  return latin >= nonLatin;
}

bool _isSupportedLocale(String lang) => keywordLocales.contains(lang);

List<String> extractOffTaxonomyIds(Map<String, dynamic> pd) {
  final ids = <String>[];
  final structured = pd['ingredients'];
  if (structured is! List) return ids;

  void addId(Map<dynamic, dynamic> item) {
    final raw = (item['id'] ?? '').toString();
    final colon = raw.indexOf(':');
    if (colon > 0) {
      final canonical = raw.substring(colon + 1).replaceAll('-', ' ').trim();
      if (canonical.isNotEmpty) ids.add(canonical);
    }
    final sub = item['ingredients'];
    if (sub is List) {
      for (final s in sub.whereType<Map<dynamic, dynamic>>()) {
        addId(s);
      }
    }
  }

  for (final item in structured.whereType<Map<dynamic, dynamic>>()) {
    addId(item);
  }
  return ids;
}

ResolvedOffIngredients resolveOffIngredientAnalysis(Map<String, dynamic> pd) {
  final display = parseDisplayIngredientList(pd);
  final displayLang = (pd['ingredients_lc'] ?? pd['lc'] ?? '')
      .toString()
      .toLowerCase();
  final primaryText = display.join(', ');

  final sources = <IngredientAnalysisSource>[];
  if (display.isNotEmpty) {
    sources.add(IngredientAnalysisSource(key: 'primary', ingredients: display));
  }

  final localeSupported =
      displayLang.isEmpty || _isSupportedLocale(displayLang);
  final scriptAnalyzable = isAnalyzableScript(primaryText);
  String? analyzeLang;

  if (display.isNotEmpty && (!localeSupported || !scriptAnalyzable)) {
    for (final lang in keywordLocales) {
      final alt = (pd['ingredients_text_$lang'] ?? '').toString().trim();
      if (alt.isEmpty) continue;
      final altList = splitIngredientText(alt.toLowerCase());
      if (altList.isEmpty) continue;
      sources.add(
        IngredientAnalysisSource(key: 'off_$lang', ingredients: altList),
      );
      analyzeLang ??= lang;
    }
  }

  final taxonomyIds = extractOffTaxonomyIds(pd);
  if (taxonomyIds.isNotEmpty) {
    sources.add(
      IngredientAnalysisSource(key: 'off_taxonomy', ingredients: taxonomyIds),
    );
  }

  return ResolvedOffIngredients(
    display: display,
    sources: sources,
    displayLang: displayLang,
    analyzeLang: analyzeLang,
  );
}

String combineMatchSourceKeys(List<String> keys) {
  final unique = keys.where((k) => k.isNotEmpty).toSet().toList()..sort();
  if (unique.isEmpty) return 'none';
  if (unique.length == 1) return unique.first;
  return unique.join('+');
}
