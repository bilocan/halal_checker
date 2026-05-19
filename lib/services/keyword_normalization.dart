/// Normalizes community keyword variants and locale-specific translations.
class KeywordNormalization {
  KeywordNormalization._();

  /// Supported locale keys for [translations] (same set as built-in display names).
  static const supportedLocales = {
    'en',
    'de',
    'tr',
    'fr',
    'es',
    'it',
    'nl',
    'sr',
    'hu',
    'cs',
  };

  /// Builds the deduplicated variant list used for ingredient matching.
  static List<String> mergeVariants({
    required String canonical,
    List<String>? variants,
    Map<String, String>? translations,
  }) {
    final set = <String>{};
    void add(String raw) {
      final t = raw.trim().toLowerCase();
      if (t.isNotEmpty) set.add(t);
    }

    add(canonical);
    for (final v in variants ?? const []) {
      add(v);
    }
    for (final v in translations?.values ?? const []) {
      add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Parses `translations` from Supabase (jsonb object).
  static Map<String, String> parseTranslations(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, String>{};
    for (final entry in raw.entries) {
      final locale = entry.key.toString().trim().toLowerCase();
      final value = entry.value?.toString().trim() ?? '';
      if (locale.isEmpty || value.isEmpty) continue;
      if (!supportedLocales.contains(locale)) continue;
      out[locale] = value.toLowerCase();
    }
    return out;
  }

  /// Parses admin/UI text: one per line `de: schwein` or `de=schwein`.
  static Map<String, String> parseTranslationsText(String raw) {
    if (raw.trim().isEmpty) return {};
    final out = <String, String>{};
    for (final line in raw.split(RegExp(r'[\n\r]+'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final sep = trimmed.contains('=')
          ? trimmed.indexOf('=')
          : trimmed.contains(':')
          ? trimmed.indexOf(':')
          : -1;
      if (sep <= 0) continue;
      final locale = trimmed.substring(0, sep).trim().toLowerCase();
      final value = trimmed.substring(sep + 1).trim();
      if (locale.isEmpty || value.isEmpty) continue;
      if (!supportedLocales.contains(locale)) continue;
      out[locale] = value.toLowerCase();
    }
    return out;
  }

  static String formatTranslations(Map<String, String> translations) {
    final entries = translations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  /// Returns true if [alias] matches canonical, any variant, or translation value.
  static bool ruleContainsAlias(
    Map<String, dynamic> rule,
    String alias,
  ) {
    final a = alias.trim().toLowerCase();
    if (a.isEmpty) return false;
    if ((rule['canonical'] as String? ?? '').toLowerCase() == a) return true;
    final variants = rule['variants'];
    if (variants is List &&
        variants.any((v) => v.toString().toLowerCase() == a)) {
      return true;
    }
    final tr = parseTranslations(rule['translations']);
    return tr.values.any((v) => v == a);
  }
}
