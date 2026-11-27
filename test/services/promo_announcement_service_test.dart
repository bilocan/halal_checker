import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/promo_announcement_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _baseUrl = 'https://example.supabase.co';

/// Routes the service's Supabase calls through [handler]. Responses get the
/// originating request attached (postgrest reads `response.request`).
void _useMockSupabase(Future<http.Response> Function(http.Request) handler) {
  PromoAnnouncementService.fakeHasSupabase = true;
  PromoAnnouncementService.fakeClient = SupabaseClient(
    _baseUrl,
    'test-anon-key',
    httpClient: MockClient((req) async {
      final res = await handler(req);
      return http.Response.bytes(
        res.bodyBytes,
        res.statusCode,
        headers: res.headers,
        request: req,
      );
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    storageOptions: const StorageClientOptions(retryAttempts: 0),
  );
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

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

  group('fetch via Supabase', () {
    test('null when Supabase not configured', () async {
      PromoAnnouncementService.fakeHasSupabase = false;
      expect(await PromoAnnouncementService.fetch(), isNull);
    });

    test('parses the promo row', () async {
      _useMockSupabase((req) async {
        expect(req.method, 'GET');
        expect(req.url.path, '/rest/v1/promo_announcement');
        expect(req.url.query, contains('id=eq.1'));
        return _json({
          'campaign_id': 'camp',
          'image_url': 'https://x.org/a.jpg',
          'link_url': 'https://x.org',
          'show_in_app': true,
        });
      });
      final promo = await PromoAnnouncementService.fetch();
      expect(promo?.campaignId, 'camp');
      expect(promo?.showInApp, isTrue);
    });

    test('null when no row exists', () async {
      _useMockSupabase((_) async => _json([], 406));
      expect(await PromoAnnouncementService.fetch(), isNull);
    });

    test('null on server error', () async {
      _useMockSupabase((_) async => _json({'message': 'boom'}, 500));
      expect(await PromoAnnouncementService.fetch(), isNull);
    });
  });

  group('update', () {
    Future<bool> doUpdate() => PromoAnnouncementService.update(
      imageUrl: 'https://x.org/a.jpg',
      linkUrl: 'https://x.org',
      showInApp: true,
      showOnWeb: false,
      endsAt: DateTime.utc(2026, 12, 19),
    );

    test('false when Supabase not configured', () async {
      PromoAnnouncementService.fakeHasSupabase = false;
      expect(await doUpdate(), isFalse);
    });

    test('true when a row is updated', () async {
      _useMockSupabase((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/rest/v1/promo_announcement');
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['show_in_app'], isTrue);
        expect(body['ends_at'], '2026-12-19T00:00:00.000Z');
        return _json([
          {'id': 1},
        ]);
      });
      expect(await doUpdate(), isTrue);
    });

    test('false when RLS returns zero rows', () async {
      _useMockSupabase((_) async => _json([]));
      expect(await doUpdate(), isFalse);
    });

    test('false on server error', () async {
      _useMockSupabase((_) async => _json({'message': 'boom'}, 500));
      expect(await doUpdate(), isFalse);
    });
  });

  group('uploadImage', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    test('null when Supabase not configured or bytes empty', () async {
      PromoAnnouncementService.fakeHasSupabase = false;
      expect(
        await PromoAnnouncementService.uploadImage(
          bytes: bytes,
          fileName: 'a.png',
        ),
        isNull,
      );
      _useMockSupabase((_) async => fail('should not call network'));
      expect(
        await PromoAnnouncementService.uploadImage(
          bytes: Uint8List(0),
          fileName: 'a.png',
        ),
        isNull,
      );
    });

    test('uploads and returns public URL', () async {
      _useMockSupabase((req) async {
        expect(req.method, 'POST');
        expect(
          req.url.path,
          matches(RegExp(r'^/storage/v1/object/promo-images/promo_\d+\.png$')),
        );
        return _json({'Key': 'promo-images/x.png'});
      });
      final url = await PromoAnnouncementService.uploadImage(
        bytes: bytes,
        fileName: 'poster.PNG',
      );
      expect(
        url,
        matches(
          RegExp(
            r'^https://example\.supabase\.co/storage/v1/object/public/promo-images/promo_\d+\.png$',
          ),
        ),
      );
    });

    test('null on upload error', () async {
      _useMockSupabase((_) async => _json({'message': 'denied'}, 403));
      expect(
        await PromoAnnouncementService.uploadImage(
          bytes: bytes,
          fileName: 'a.jpg',
        ),
        isNull,
      );
    });
  });
}
