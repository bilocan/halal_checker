/// Public web URLs for HalalScan (blog guides, product pages, etc.).
class SiteUrls {
  SiteUrls._();

  static const String webBase = 'https://halalscan.at';

  /// Locale-prefixed blog guide, e.g. `https://halalscan.at/en/blog/gida-aromalarinda-alkol`.
  static String blogGuide(String locale, String slug) =>
      '$webBase/$locale/blog/$slug';
}
