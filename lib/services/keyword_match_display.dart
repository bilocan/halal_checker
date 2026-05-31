import '../localization/app_localizations.dart';

/// Localized labels for keyword match source keys (primary, off_en, off_taxonomy, …).
abstract final class KeywordMatchDisplay {
  static String sourceLabel(AppLocalizations loc, String sourceKey) {
    if (sourceKey == 'primary') {
      return loc.transparentMatchSourcePrimary;
    }
    if (sourceKey == 'off_taxonomy') {
      return loc.transparentMatchSourceOffTaxonomy;
    }
    if (sourceKey == 'unanalyzable') {
      return loc.transparentMatchSourceUnanalyzable;
    }
    if (sourceKey == 'none') {
      return loc.transparentMatchSourceNone;
    }

    if (sourceKey.startsWith('off_') && sourceKey.length > 4) {
      final lang = sourceKey.substring(4).toUpperCase();
      return loc.transparentMatchSourceOffLang(lang);
    }
    return sourceKey;
  }

  static String combinedSourcesLabel(AppLocalizations loc, String? combined) {
    if (combined == null || combined.isEmpty) {
      return loc.transparentMatchSourceNone;
    }
    final parts = combined
        .split('+')
        .map((p) => sourceLabel(loc, p.trim()))
        .toList();
    return parts.join(' + ');
  }

  static String originSummary(
    AppLocalizations loc,
    Map<String, String> origins,
  ) {
    if (origins.isEmpty) {
      return loc.transparentNoMatches;
    }
    return origins.entries
        .map((e) => '${e.key} → ${sourceLabel(loc, e.value)}')
        .join('\n');
  }
}
