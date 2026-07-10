/// Public web URLs for HalalScan (blog guides, product pages, etc.).
class SiteUrls {
  SiteUrls._();

  static const String webBase = 'https://halalscan.at';
  static const String githubAppRepo =
      'https://github.com/bilocan/halal_checker';
  static const String githubContributing =
      'https://github.com/bilocan/halal_checker/blob/main/CONTRIBUTING.md';
  static const String privacyPolicy =
      'https://gist.github.com/bilocan/b61ebb96d2b847aa6964262d506d6143';
  static const String contactEmail = 'bilalgunay@gmail.com';

  static const _webLocales = {'en', 'de', 'tr'};

  static String webLocale(String languageCode) =>
      _webLocales.contains(languageCode) ? languageCode : 'en';

  static String webHome(String languageCode) =>
      '$webBase/${webLocale(languageCode)}';

  static String webSuggest(String languageCode) =>
      '${webHome(languageCode)}/suggest';

  static String webReport(String languageCode) =>
      '${webHome(languageCode)}/report';

  /// Locale-prefixed blog guide, e.g. `https://halalscan.at/en/blog/gida-aromalarinda-alkol`.
  static String blogGuide(String locale, String slug) =>
      '$webBase/${webLocale(locale)}/blog/$slug';

  static Uri contactMailto({String subject = 'HalalScan'}) => Uri(
    scheme: 'mailto',
    path: contactEmail,
    query: 'subject=${Uri.encodeComponent(subject)}',
  );
}
