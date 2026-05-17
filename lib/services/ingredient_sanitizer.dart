class IngredientSanitizer {
  IngredientSanitizer._();

  // Ingredient section labels in the languages found on European packaging.
  static final _sectionLabelRe = RegExp(
    r'(?:Zutaten|Ingredients?|Ingredienti|Ingredientes|Ingrédients?)\s*:',
    caseSensitive: false,
  );

  // Same pattern but with a capturing group — used by sanitizeByLanguage.
  static final _sectionLabelKeyRe = RegExp(
    r'(Zutaten|Ingrédients?|Ingredienti|Ingredientes|Ingredients?)\s*:',
    caseSensitive: false,
  );

  // Lines that are only a section description, e.g. "Assortment of pretzel snacks:"
  // Signature: no commas (not an ingredient list) and ends with a colon.
  static final _sectionHeaderLineRe = RegExp(r'^[^,\n]+:\s*$', multiLine: true);

  // Parenthesised country/language codes: (GB), (A), (D), (CH), (F), (I) …
  static final _countryCodeRe = RegExp(r'\([A-Z]{1,3}\)');

  // After stripping parens, bare language codes may remain as lone tokens.
  static final _bareCodeRe = RegExp(r'^[A-Z]{1,3}\.?$');

  // Packaging country code → language code.
  static const _countryToLang = <String, String>{
    'A': 'de',
    'D': 'de',
    'CH': 'de',
    'AT': 'de',
    'GB': 'en',
    'IE': 'en',
    'UK': 'en',
    'F': 'fr',
    'BE': 'fr',
    'I': 'it',
    'E': 'es',
    'ES': 'es',
    'NL': 'nl',
    'PT': 'pt',
    'PL': 'pl',
    'SE': 'sv',
    'DK': 'da',
    'FI': 'fi',
    'NO': 'no',
    'CZ': 'cs',
    'SK': 'sk',
    'HU': 'hu',
    'RO': 'ro',
  };

  // Unambiguous ingredient label keywords → language code.
  // "Ingredients" is intentionally absent — it's ambiguous (EN vs FR OCR error).
  static const _labelToLang = <String, String>{
    'zutaten': 'de',
    'ingredienti': 'it',
    'ingredientes': 'es',
    'ingrédients': 'fr',
    'ingrédient': 'fr',
  };

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
        .replaceAll(_sectionHeaderLineRe, '');

    // Remove trailing footer noise: real OCR captures marketing text after the
    // last ingredient section (e.g. brand logos, origin badges). Ingredient
    // lists always have commas; non-ingredient lines don't. Scan backward and
    // drop every line that contains no comma once we've passed all ingredient
    // content.
    if (text.contains(',')) {
      final lines = text.split('\n');
      var cutoff = lines.length;
      for (var i = lines.length - 1; i >= 0; i--) {
        if (lines[i].contains(',')) {
          cutoff = i + 1;
          break;
        }
      }
      if (cutoff < lines.length) {
        text = lines.sublist(0, cutoff).join('\n');
      }
    }

    text = text
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

  /// Splits raw OCR text into per-language ingredient lists.
  ///
  /// Returns a map of language code (e.g. "en", "de", "fr", "it") to the
  /// sanitized ingredient list for that section. On a typical 4-language
  /// European label this produces four entries. Falls back to
  /// `{'en': sanitize(rawText)}` when no section labels are found.
  static Map<String, List<String>> sanitizeByLanguage(String rawText) {
    final normalized = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final matches = _sectionLabelKeyRe.allMatches(normalized).toList();
    if (matches.isEmpty) {
      final all = sanitize(rawText);
      return all.isEmpty ? {} : {'en': all};
    }

    final sections = <String, List<String>>{};

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final keyword = match.group(1) ?? '';
      final endPos = i + 1 < matches.length
          ? matches[i + 1].start
          : normalized.length;

      final sectionText = normalized.substring(match.start, endPos);

      // Look up to 400 chars before this label for country codes / headers.
      final precedingStart = (match.start - 400).clamp(0, match.start);
      final preceding = normalized.substring(precedingStart, match.start);
      final lang = _detectLang(keyword, preceding);

      final ingredients = sanitize(sectionText);
      if (ingredients.isEmpty) continue;

      // Merge into existing entry if the same language appeared twice
      // (e.g. when OCR drops the accent on "Ingrédients" → "Ingredients").
      sections.update(
        lang,
        (old) => old + ingredients,
        ifAbsent: () => ingredients,
      );
    }

    return sections;
  }

  /// Returns a human-readable label for [lang], e.g. "EN 🇬🇧".
  static String langDisplayName(String lang) => switch (lang) {
    'de' => 'DE 🇩🇪',
    'en' => 'EN 🇬🇧',
    'fr' => 'FR 🇫🇷',
    'it' => 'IT 🇮🇹',
    'es' => 'ES 🇪🇸',
    'nl' => 'NL 🇳🇱',
    'pt' => 'PT 🇵🇹',
    'pl' => 'PL 🇵🇱',
    'sv' => 'SV 🇸🇪',
    'da' => 'DA 🇩🇰',
    'fi' => 'FI 🇫🇮',
    'no' => 'NO 🇳🇴',
    'cs' => 'CS 🇨🇿',
    'sk' => 'SK 🇸🇰',
    'hu' => 'HU 🇭🇺',
    'ro' => 'RO 🇷🇴',
    _ => lang.toUpperCase(),
  };

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Infers a language code from the section label [keyword] and the raw text
  /// [preceding] the label (section headers, country codes).
  static String _detectLang(String keyword, String preceding) {
    // 1. Unambiguous label keywords.
    final kw = keyword.toLowerCase();
    for (final e in _labelToLang.entries) {
      if (kw.startsWith(e.key)) return e.value;
    }
    // "Ingredients" is ambiguous → fall through.

    // 2. Parenthesised country codes closest to the label.
    final codeMatches = _countryCodeRe.allMatches(preceding).toList();
    for (final m in codeMatches.reversed) {
      final code = m.group(0)!.replaceAll(RegExp(r'[()]'), '');
      final lang = _countryToLang[code];
      if (lang != null) return lang;
    }

    // 2b. Bare 2–3-letter country codes at the start of a section-header line
    //     (e.g. "GB Assortment of pretzel snacks:"). Single-letter codes are
    //     skipped — they appear fused to the next word in real OCR ("DMélange").
    final bareLineCodeRe = RegExp(r'(?:^|\n)([A-Z]{2,3}) ', multiLine: true);
    for (final m in bareLineCodeRe.allMatches(preceding).toList().reversed) {
      final code = m.group(1)!;
      final lang = _countryToLang[code];
      if (lang != null) return lang;
    }

    // 3. Language-specific words in the preceding section header.
    final lower = preceding.toLowerCase();
    if (lower.contains('mélange') ||
        lower.contains('biscuits salés') ||
        lower.contains('levure') ||
        lower.contains('froment')) {
      return 'fr';
    }
    if (lower.contains('salatini') ||
        lower.contains('assortiti') ||
        lower.contains('lievitanti') ||
        lower.contains('frumento')) {
      return 'it';
    }
    if (lower.contains('gebäck') ||
        lower.contains('salzgebäck') ||
        lower.contains('zutaten')) {
      return 'de';
    }
    if (lower.contains('mezcla') ||
        lower.contains('aperitivo') ||
        lower.contains('harina de trigo')) {
      return 'es';
    }

    return 'en';
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
