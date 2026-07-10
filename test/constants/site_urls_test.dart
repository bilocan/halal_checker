import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/constants/site_urls.dart';

void main() {
  group('SiteUrls', () {
    test('webHome uses supported locale or falls back to en', () {
      expect(SiteUrls.webHome('de'), 'https://halalscan.at/de');
      expect(SiteUrls.webHome('ar'), 'https://halalscan.at/en');
    });

    test('community paths are locale-prefixed', () {
      expect(SiteUrls.webSuggest('tr'), 'https://halalscan.at/tr/suggest');
      expect(SiteUrls.webReport('en'), 'https://halalscan.at/en/report');
    });

    test('contactMailto encodes subject', () {
      final uri = SiteUrls.contactMailto(subject: 'HalalScan Support');
      expect(uri.scheme, 'mailto');
      expect(uri.path, SiteUrls.contactEmail);
      expect(uri.query, contains('subject=HalalScan'));
    });
  });
}
