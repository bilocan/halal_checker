class IngredientSanitizer {
  IngredientSanitizer._();

  // Ingredient section labels in the languages found on European packaging.
  static final _sectionLabelRe = RegExp(
    r'(?:Zutaten|Ingredients?|Ingredienti|Ingredientes|Ingrédients?)\s*:',
    caseSensitive: false,
  );

  // Lines that are only a section description, e.g. "Assortment of pretzel snacks:"
  // Signature: no commas (not an ingredient list) and ends with a colon.
  static final _sectionHeaderLineRe = RegExp(r'^[^,\n]+:\s*$', multiLine: true);

  // Parenthesised country/language codes: (GB), (A), (D), (CH), (F), (I) …
  static final _countryCodeRe = RegExp(r'\([A-Z]{1,3}\)');

  // After stripping parens, bare language codes may remain as lone tokens.
  static final _bareCodeRe = RegExp(r'^[A-Z]{1,3}\.?$');

  /// Sanitizes raw OCR text from an ingredient label into a clean ingredient list.
  ///
  /// Handles:
  /// - Section labels: "Ingredients:", "Zutaten:", "Ingredienti:", etc.
  /// - Parenthesised country codes: "(GB)", "(A)(D)(CH)"
  /// - Section description lines: "Assortment of pretzel snacks:"
  /// - Hyphenated line-breaks from OCR word-wrap: "hy-\nphen" → "hyphen"
  /// - Visual line-wraps: treats newlines as spaces, NOT as ingredient separators
  /// - Sub-ingredient lists in parentheses: does NOT split on commas inside (…)
  static List<String> sanitize(String rawText) {
    var text = rawText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        // Repair OCR word-wrap hyphenation: "hy-\nphen" → "hyphen"
        .replaceAll(RegExp(r'-\n'), '')
        // Remove parenthesised country codes
        .replaceAll(_countryCodeRe, ' ')
        // Remove ingredient section labels
        .replaceAll(_sectionLabelRe, ' ')
        // Remove section description lines (no commas, ends with colon)
        .replaceAll(_sectionHeaderLineRe, '')
        // Fold all remaining newlines into spaces (they're just visual wraps)
        .replaceAll('\n', ' ')
        // Collapse runs of whitespace
        .replaceAll(RegExp(r'\s+'), ' ');

    return _smartSplit(text)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.length >= 2)
        .where((e) => !_bareCodeRe.hasMatch(e.trim()))
        .toList();
  }

  /// Splits [text] on commas and semicolons that are outside parentheses/brackets.
  /// Content inside (…) or […] is kept intact as part of its parent token.
  static List<String> _smartSplit(String text) {
    final result = <String>[];
    final buffer = StringBuffer();
    var depth = 0;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '(' || ch == '[') {
        depth++;
        buffer.write(ch);
      } else if (ch == ')' || ch == ']') {
        if (depth > 0) depth--;
        buffer.write(ch);
      } else if ((ch == ',' || ch == ';') && depth == 0) {
        final token = buffer.toString().trim();
        if (token.isNotEmpty) result.add(token);
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }

    final last = buffer.toString().trim();
    if (last.isNotEmpty) result.add(last);

    return result;
  }
}
