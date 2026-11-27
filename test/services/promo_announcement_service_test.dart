import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/promo_announcement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

PromoAnnouncement _promo({
  String campaignId = 'c1',
  String? imageUrl = 'https://example.com/poster.jpg',
  String? linkUrl = 'https://example.com',
  bool showInApp = true,
  DateTime? endsAt,
}) => PromoAnnouncement(
  campaignId: campaignId,
  imageUrl: imageUrl,
  linkUrl: linkUrl,
  showInApp: showInApp,
  endsAt: endsAt,
);

void main() {
  final now = DateTime.utc(2026, 12, 1, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PromoAnnouncementService.resetTestOverrides();
    PromoAnnouncementService.fakeNow = () => now;
  });

  tearDown(PromoAnnouncementService.resetTestOverrides);

  group('PromoAnnouncement.fromJson', () {
    test('parses row and trims empty strings to null', () {
      final p = PromoAnnouncement.fromJson({
        'campaign_id': 'abc',
        'image_url': '  ',
        'link_url': 'https://x.org',
        'show_in_app': true,
        'show_on_web': false,
        'ends_at': '2026-12-19T22:59:59+00:00',
      });
      expect(p.campaignId, 'abc');
      expect(p.imageUrl, isNull);
      expect(p.linkUrl, 'https://x.org');
      expect(p.showInApp, isTrue);
      expect(p.showOnWeb, isFalse);
      expect(p.endsAt, DateTime.utc(2026, 12, 19, 22, 59, 59));
    });
  });

  group('isActiveInAppAt', () {
    test('active when enabled, has content, no end date', () {
      expect(_promo().isActiveInAppAt(now), isTrue);
    });

    test('inactive when disabled', () {
      expect(_promo(showInApp: false).isActiveInAppAt(now), isFalse);
    });

    test('inactive when image or link missing', () {
      expect(_promo(imageUrl: null).isActiveInAppAt(now), isFalse);
      expect(_promo(linkUrl: null).isActiveInAppAt(now), isFalse);
    });

    test('inactive after ends_at, active before', () {
      expect(
        _promo(
          endsAt: now.subtract(const Duration(minutes: 1)),
        ).isActiveInAppAt(now),
        isFalse,
      );
      expect(
        _promo(endsAt: now.add(const Duration(days: 1))).isActiveInAppAt(now),
        isTrue,
      );
    });
  });

  group('promoToShow', () {
    test('returns promo once per launch', () async {
      PromoAnnouncementService.fakeFetch = () async => _promo();
      expect(await PromoAnnouncementService.promoToShow(), isNotNull);
      expect(await PromoAnnouncementService.promoToShow(), isNull);
    });

    test('hidden after dismiss for same campaign', () async {
      PromoAnnouncementService.fakeFetch = () async => _promo();
      await PromoAnnouncementService.dismiss('c1');
      expect(await PromoAnnouncementService.promoToShow(), isNull);
    });

    test('shows again for a new campaign id', () async {
      await PromoAnnouncementService.dismiss('c1');
      PromoAnnouncementService.fakeFetch = () async => _promo(campaignId: 'c2');
      expect((await PromoAnnouncementService.promoToShow())?.campaignId, 'c2');
    });

    test('null when fetch fails or promo inactive', () async {
      PromoAnnouncementService.fakeFetch = () async => null;
      expect(await PromoAnnouncementService.promoToShow(), isNull);
      PromoAnnouncementService.fakeFetch = () async => _promo(showInApp: false);
      expect(await PromoAnnouncementService.promoToShow(), isNull);
    });
  });

  group('helpers', () {
    test('isValidHttpUrl', () {
      expect(
        PromoAnnouncementService.isValidHttpUrl(
          'http://helalhayat2026.agdavrupa.org/',
        ),
        isTrue,
      );
      expect(PromoAnnouncementService.isValidHttpUrl('ftp://x.org'), isFalse);
      expect(PromoAnnouncementService.isValidHttpUrl('not a url'), isFalse);
      expect(PromoAnnouncementService.isValidHttpUrl(null), isFalse);
    });

    test('imageExtension / mimeTypeForExtension', () {
      expect(PromoAnnouncementService.imageExtension('a.JPEG'), 'jpg');
      expect(PromoAnnouncementService.imageExtension('a.png'), 'png');
      expect(PromoAnnouncementService.imageExtension('a.heic'), 'jpg');
      expect(PromoAnnouncementService.mimeTypeForExtension('png'), 'image/png');
      expect(
        PromoAnnouncementService.mimeTypeForExtension('jpg'),
        'image/jpeg',
      );
    });
  });
}
