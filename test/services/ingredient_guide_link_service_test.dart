import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:halal_checker/services/auth_service.dart';
import 'package:halal_checker/services/ingredient_guide_link_service.dart';

const _fakeUrl = 'https://test.supabase.co';
const _fakeKey = 'test_anon_key';

IngredientGuideLinkService _svc(MockClient client) =>
    IngredientGuideLinkService(
      client: client,
      hasSupabase: true,
      supabaseUrl: _fakeUrl,
      anonKey: _fakeKey,
    );

const _fakeUser = User(
  id: 'admin-uid',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2024-01-01T00:00:00',
  isAnonymous: false,
);

void main() {
  group('IngredientGuideLinkService.fetchAllByCanonical', () {
    test('returns map keyed by canonical on HTTP 200', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'canonical': 'e471',
              'guide_slugs': ['e-numbers-guide'],
            },
            {
              'canonical': 'pork',
              'guide_slugs': ['what-is-gelatin'],
            },
          ]),
          200,
        ),
      );

      final result = await _svc(client).fetchAllByCanonical();
      expect(result['e471'], ['e-numbers-guide']);
      expect(result['pork'], ['what-is-gelatin']);
    });

    test('returns empty map when hasSupabase is false', () async {
      expect(
        await IngredientGuideLinkService(
          hasSupabase: false,
        ).fetchAllByCanonical(),
        isEmpty,
      );
    });
  });

  group('IngredientGuideLinkService.upsertGuideLinks', () {
    setUp(() => AuthService.setCurrentUserForTesting(_fakeUser));
    tearDown(AuthService.resetForTesting);

    test('POSTs normalized slugs on upsert', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(req.method, 'POST');
        expect(req.url.path, '/rest/v1/ingredient_guide_links');
        return http.Response('', 201);
      });

      expect(
        await _svc(client).upsertGuideLinks(
          canonical: ' E471 ',
          guideSlugs: ['E-Numbers-Guide', 'e-numbers-guide'],
        ),
        isTrue,
      );
      expect(body!['canonical'], 'e471');
      expect(body!['guide_slugs'], ['e-numbers-guide']);
    });

    test('DELETEs row when slugs are empty', () async {
      late Uri capturedUri;
      late String capturedMethod;
      final client = MockClient((req) async {
        capturedUri = req.url;
        capturedMethod = req.method;
        return http.Response('', 204);
      });

      expect(
        await _svc(
          client,
        ).upsertGuideLinks(canonical: 'natural flavour', guideSlugs: const []),
        isTrue,
      );
      expect(capturedMethod, 'DELETE');
      expect(capturedUri.query, contains('canonical=eq.natural%20flavour'));
    });

    test('returns false when user is not signed in', () async {
      AuthService.resetForTesting();
      final client = MockClient((_) async => http.Response('', 201));
      expect(
        await _svc(client).upsertGuideLinks(
          canonical: 'e471',
          guideSlugs: const ['e-numbers-guide'],
        ),
        isFalse,
      );
    });
  });
}
