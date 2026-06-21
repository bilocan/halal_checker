import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:halal_checker/services/auth_service.dart';
import 'package:halal_checker/services/keyword_service.dart';

const _fakeUrl = 'https://test.supabase.co';
const _fakeKey = 'test_anon_key';

KeywordService _svc(MockClient client) => KeywordService(
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
  // ── guard paths ───────────────────────────────────────────────────────────

  group('KeywordService — hasSupabase: false (no Supabase config)', () {
    late KeywordService service;

    setUp(() => service = KeywordService(hasSupabase: false));

    test('fetchCustomKeywords returns empty list', () async {
      expect(await service.fetchCustomKeywords(), isEmpty);
    });

    test('suggestKeyword returns false', () async {
      expect(
        await service.suggestKeyword(
          keyword: 'lard',
          category: 'haram',
          reason: 'pig fat',
        ),
        isFalse,
      );
    });

    test('fetchAllRules returns empty list', () async {
      expect(await service.fetchAllRules(), isEmpty);
    });

    test('createRule returns false', () async {
      expect(
        await service.createRule(
          canonical: 'lard',
          category: 'haram',
          reason: 'pig fat',
        ),
        isFalse,
      );
    });

    test('updateRule returns false', () async {
      expect(
        await service.updateRule(
          id: 'abc',
          canonical: 'lard',
          category: 'haram',
          reason: 'pig fat',
        ),
        isFalse,
      );
    });

    test('deleteRule returns false', () async {
      expect(await service.deleteRule('abc'), isFalse);
    });

    test('fetchSuggestions returns empty list', () async {
      expect(await service.fetchSuggestions(), isEmpty);
    });

    test('deleteSuggestion returns false', () async {
      expect(await service.deleteSuggestion('abc'), isFalse);
    });
  });

  // ── admin auth guard (hasSupabase true but no logged-in user) ─────────────

  group('KeywordService — admin methods require authenticated user', () {
    late KeywordService service;

    setUp(() {
      service = KeywordService(
        client: MockClient((_) async => http.Response('', 201)),
        hasSupabase: true,
        supabaseUrl: _fakeUrl,
        anonKey: _fakeKey,
      );
      // AuthService.currentUser is null by default in tests
    });

    tearDown(AuthService.resetForTesting);

    test('createRule returns false when user is null', () async {
      expect(
        await service.createRule(
          canonical: 'lard',
          category: 'haram',
          reason: 'pig fat',
        ),
        isFalse,
      );
    });

    test('updateRule returns false when user is null', () async {
      expect(
        await service.updateRule(
          id: 'id',
          canonical: 'lard',
          category: 'haram',
          reason: 'pig fat',
        ),
        isFalse,
      );
    });

    test('deleteRule returns false when user is null', () async {
      expect(await service.deleteRule('id'), isFalse);
    });

    test('deleteSuggestion returns false when user is null', () async {
      expect(await service.deleteSuggestion('id'), isFalse);
    });

    test('approveSuggestion returns false when user is null', () async {
      expect(
        await service.approveSuggestion({
          'id': 'sg-1',
          'keyword': 'lard',
          'category': 'haram',
          'reason': 'pig fat',
        }),
        isFalse,
      );
    });
  });

  // ── fetchCustomKeywords ───────────────────────────────────────────────────

  group('KeywordService.fetchCustomKeywords — HTTP paths', () {
    test('returns parsed keyword list on HTTP 200', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'canonical': 'lard',
              'reason': 'pig fat',
              'category': 'haram',
              'variants': ['schmalz', 'saindoux'],
            },
            {
              'canonical': 'gelatin',
              'reason': 'animal bones',
              'category': 'haram',
              'variants': ['gelatine'],
            },
          ]),
          200,
        ),
      );

      final result = await _svc(client).fetchCustomKeywords();
      expect(result.length, equals(2));
      expect(result.first['canonical'], equals('lard'));
      expect(result.last['canonical'], equals('gelatin'));
    });

    test('returns empty list on HTTP 200 with empty array', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode([]), 200),
      );
      expect(await _svc(client).fetchCustomKeywords(), isEmpty);
    });

    test('sends correct URL and auth headers', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      final client = MockClient((req) async {
        capturedUri = req.url;
        capturedHeaders = req.headers;
        return http.Response(jsonEncode([]), 200);
      });

      await _svc(client).fetchCustomKeywords();

      expect(capturedUri.host, equals('test.supabase.co'));
      expect(capturedUri.path, equals('/rest/v1/keywords'));
      expect(capturedUri.query, contains('select='));
      expect(capturedHeaders['apikey'], equals(_fakeKey));
      expect(capturedHeaders['Authorization'], equals('Bearer $_fakeKey'));
    });

    test('returns empty list on HTTP 401', () async {
      final client = MockClient(
        (_) async => http.Response('Unauthorized', 401),
      );
      expect(await _svc(client).fetchCustomKeywords(), isEmpty);
    });

    test('returns empty list on HTTP 500', () async {
      final client = MockClient((_) async => http.Response('Error', 500));
      expect(await _svc(client).fetchCustomKeywords(), isEmpty);
    });

    test('returns empty list on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Network error'),
      );
      expect(await _svc(client).fetchCustomKeywords(), isEmpty);
    });
  });

  // ── suggestKeyword ────────────────────────────────────────────────────────

  group('KeywordService.suggestKeyword — HTTP paths', () {
    test('returns true on HTTP 201', () async {
      final client = MockClient((_) async => http.Response('', 201));
      expect(
        await _svc(
          client,
        ).suggestKeyword(keyword: 'lard', category: 'haram', reason: 'pig fat'),
        isTrue,
      );
    });

    test('returns false on HTTP 200 (only 201 is success)', () async {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        await _svc(
          client,
        ).suggestKeyword(keyword: 'lard', category: 'haram', reason: 'reason'),
        isFalse,
      );
    });

    test(
      'normalizes keyword to lowercase and trimmed before sending',
      () async {
        String? sentKeyword;
        final client = MockClient((req) async {
          sentKeyword =
              (jsonDecode(req.body) as Map<String, dynamic>)['keyword']
                  as String;
          return http.Response('', 201);
        });
        await _svc(client).suggestKeyword(
          keyword: '  PORK FAT  ',
          category: 'haram',
          reason: 'pig-derived',
        );
        expect(sentKeyword, equals('pork fat'));
      },
    );

    test('trims reason before sending', () async {
      String? sentReason;
      final client = MockClient((req) async {
        sentReason =
            (jsonDecode(req.body) as Map<String, dynamic>)['reason'] as String;
        return http.Response('', 201);
      });
      await _svc(client).suggestKeyword(
        keyword: 'gelatin',
        category: 'haram',
        reason: '  animal bones  ',
      );
      expect(sentReason, equals('animal bones'));
    });

    test('sends correct request body fields', () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((req) async {
        sentBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });
      await _svc(client).suggestKeyword(
        keyword: 'gelatin',
        category: 'haram',
        reason: 'animal bones',
      );
      expect(sentBody!['keyword'], equals('gelatin'));
      expect(sentBody!['category'], equals('haram'));
      expect(sentBody!['reason'], equals('animal bones'));
    });

    test('sends correct URL and auth headers', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      final client = MockClient((req) async {
        capturedUri = req.url;
        capturedHeaders = req.headers;
        return http.Response('', 201);
      });
      await _svc(
        client,
      ).suggestKeyword(keyword: 'lard', category: 'haram', reason: 'reason');
      expect(capturedUri.path, equals('/rest/v1/keyword_suggestions'));
      expect(capturedHeaders['apikey'], equals(_fakeKey));
      expect(capturedHeaders['Content-Type'], contains('application/json'));
    });

    test('returns false on HTTP 400', () async {
      final client = MockClient((_) async => http.Response('Bad Request', 400));
      expect(
        await _svc(
          client,
        ).suggestKeyword(keyword: 'lard', category: 'haram', reason: 'r'),
        isFalse,
      );
    });

    test('returns false on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Timeout'),
      );
      expect(
        await _svc(
          client,
        ).suggestKeyword(keyword: 'lard', category: 'haram', reason: 'r'),
        isFalse,
      );
    });
  });

  // ── fetchAllRules ─────────────────────────────────────────────────────────

  group('KeywordService.fetchAllRules', () {
    test('returns parsed list on HTTP 200', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': '1',
              'canonical': 'lard',
              'reason': 'pig fat',
              'category': 'haram',
              'variants': [],
              'created_at': '2024-01-01',
            },
          ]),
          200,
        ),
      );
      final result = await _svc(client).fetchAllRules();
      expect(result, hasLength(1));
      expect(result.first['canonical'], 'lard');
      expect(result.first['id'], '1');
    });

    test('sends URL with select and order params', () async {
      late Uri capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(jsonEncode([]), 200);
      });
      await _svc(client).fetchAllRules();
      expect(capturedUri.path, equals('/rest/v1/keywords'));
      expect(capturedUri.query, contains('select='));
      expect(capturedUri.query, contains('order='));
    });

    test('returns empty list on HTTP 401', () async {
      final client = MockClient((_) async => http.Response('', 401));
      expect(await _svc(client).fetchAllRules(), isEmpty);
    });

    test('returns empty list on network exception', () async {
      final client = MockClient((_) async => throw http.ClientException('err'));
      expect(await _svc(client).fetchAllRules(), isEmpty);
    });
  });

  // ── createRule ────────────────────────────────────────────────────────────

  group('KeywordService.createRule', () {
    setUp(() => AuthService.setCurrentUserForTesting(_fakeUser));
    tearDown(AuthService.resetForTesting);

    test('HTTP 201 → true', () async {
      final client = MockClient((_) async => http.Response('', 201));
      expect(
        await _svc(
          client,
        ).createRule(canonical: 'lard', category: 'haram', reason: 'pig fat'),
        isTrue,
      );
    });

    test('HTTP 200 → false (only 201 is created)', () async {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        await _svc(
          client,
        ).createRule(canonical: 'lard', category: 'haram', reason: 'pig fat'),
        isFalse,
      );
    });

    test('normalizes canonical to lowercase and trimmed', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });
      await _svc(
        client,
      ).createRule(canonical: '  PORK  ', category: 'haram', reason: 'r');
      expect(body!['canonical'], 'pork');
    });

    test('includes variants when non-empty', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });
      await _svc(client).createRule(
        canonical: 'lard',
        category: 'haram',
        reason: 'r',
        variants: ['schmalz', 'saindoux'],
      );
      expect(body!['variants'], ['lard', 'saindoux', 'schmalz']);
    });

    test('always includes merged variants and translations', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });
      await _svc(
        client,
      ).createRule(canonical: 'lard', category: 'haram', reason: 'r');
      expect(body!['variants'], ['lard']);
      expect(body!['translations'], isEmpty);
      expect(body!.containsKey('guide_slugs'), isFalse);
    });

    test('merges canonical when variants list is empty', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });
      await _svc(client).createRule(
        canonical: 'lard',
        category: 'haram',
        reason: 'r',
        variants: [],
      );
      expect(body!['variants'], ['lard']);
    });

    test('POSTs to /rest/v1/keywords', () async {
      late Uri capturedUri;
      late String capturedMethod;
      final client = MockClient((req) async {
        capturedUri = req.url;
        capturedMethod = req.method;
        return http.Response('', 201);
      });
      await _svc(
        client,
      ).createRule(canonical: 'lard', category: 'haram', reason: 'r');
      expect(capturedUri.path, '/rest/v1/keywords');
      expect(capturedMethod, 'POST');
    });

    test('returns false on network exception', () async {
      final client = MockClient((_) async => throw http.ClientException('err'));
      expect(
        await _svc(
          client,
        ).createRule(canonical: 'lard', category: 'haram', reason: 'r'),
        isFalse,
      );
    });
  });

  // ── updateRule ────────────────────────────────────────────────────────────

  group('KeywordService.updateRule', () {
    setUp(() => AuthService.setCurrentUserForTesting(_fakeUser));
    tearDown(AuthService.resetForTesting);

    test('HTTP 204 → true', () async {
      final client = MockClient((_) async => http.Response('', 204));
      expect(
        await _svc(client).updateRule(
          id: 'rule-1',
          canonical: 'lard',
          category: 'haram',
          reason: 'r',
        ),
        isTrue,
      );
    });

    test('HTTP 200 → false (only 204 is success for PATCH)', () async {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        await _svc(client).updateRule(
          id: 'rule-1',
          canonical: 'lard',
          category: 'haram',
          reason: 'r',
        ),
        isFalse,
      );
    });

    test('normalizes canonical to lowercase and trimmed', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 204);
      });
      await _svc(client).updateRule(
        id: 'r',
        canonical: '  GELATIN  ',
        category: 'haram',
        reason: 'r',
      );
      expect(body!['canonical'], 'gelatin');
    });

    test('includes merged variants when provided as empty list', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 204);
      });
      await _svc(client).updateRule(
        id: 'r',
        canonical: 'lard',
        category: 'haram',
        reason: 'r',
        variants: [],
      );
      expect(body!['variants'], ['lard']);
    });

    test('always sends variants and translations on update', () async {
      Map<String, dynamic>? body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 204);
      });
      await _svc(
        client,
      ).updateRule(id: 'r', canonical: 'lard', category: 'haram', reason: 'r');
      expect(body!['variants'], ['lard']);
      expect(body!['translations'], isEmpty);
      expect(body!.containsKey('guide_slugs'), isFalse);
    });

    test('PATCHes to URL with id filter', () async {
      late Uri capturedUri;
      late String capturedMethod;
      final client = MockClient((req) async {
        capturedUri = req.url;
        capturedMethod = req.method;
        return http.Response('', 204);
      });
      await _svc(client).updateRule(
        id: 'rule-42',
        canonical: 'lard',
        category: 'haram',
        reason: 'r',
      );
      expect(capturedUri.path, '/rest/v1/keywords');
      expect(capturedUri.query, contains('id=eq.rule-42'));
      expect(capturedMethod, 'PATCH');
    });

    test('returns false on network exception', () async {
      final client = MockClient((_) async => throw http.ClientException('err'));
      expect(
        await _svc(client).updateRule(
          id: 'r',
          canonical: 'lard',
          category: 'haram',
          reason: 'r',
        ),
        isFalse,
      );
    });
  });

  // ── deleteRule ────────────────────────────────────────────────────────────

  group('KeywordService.deleteRule', () {
    setUp(() => AuthService.setCurrentUserForTesting(_fakeUser));
    tearDown(AuthService.resetForTesting);

    test('HTTP 200 → true', () async {
      final client = MockClient((_) async => http.Response('', 200));
      expect(await _svc(client).deleteRule('rule-1'), isTrue);
    });

    test('HTTP 204 → true', () async {
      final client = MockClient((_) async => http.Response('', 204));
      expect(await _svc(client).deleteRule('rule-1'), isTrue);
    });

    test('HTTP 400 → false', () async {
      final client = MockClient((_) async => http.Response('', 400));
      expect(await _svc(client).deleteRule('rule-1'), isFalse);
    });

    test('DELETEs to URL with id filter', () async {
      late Uri capturedUri;
      late String capturedMethod;
      final client = MockClient((req) async {
        capturedUri = req.url;
        capturedMethod = req.method;
        return http.Response('', 204);
      });
      await _svc(client).deleteRule('rule-99');
      expect(capturedUri.path, '/rest/v1/keywords');
      expect(capturedUri.query, contains('id=eq.rule-99'));
      expect(capturedMethod, 'DELETE');
    });

    test('returns false on network exception', () async {
      final client = MockClient((_) async => throw http.ClientException('err'));
      expect(await _svc(client).deleteRule('r'), isFalse);
    });
  });

  // ── fetchSuggestions ──────────────────────────────────────────────────────

  group('KeywordService.fetchSuggestions', () {
    test('returns parsed list on HTTP 200', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            {
              'id': 'sg-1',
              'keyword': 'lard',
              'category': 'haram',
              'reason': 'pig fat',
              'created_at': '2024-01-01',
            },
            {
              'id': 'sg-2',
              'keyword': 'gelatin',
              'category': 'haram',
              'reason': 'animal',
              'created_at': '2024-01-02',
            },
          ]),
          200,
        ),
      );
      final result = await _svc(client).fetchSuggestions();
      expect(result, hasLength(2));
      expect(result.first['keyword'], 'lard');
    });

    test('sends URL with select and order params', () async {
      late Uri capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response(jsonEncode([]), 200);
      });
      await _svc(client).fetchSuggestions();
      expect(capturedUri.path, '/rest/v1/keyword_suggestions');
      expect(capturedUri.query, contains('select='));
      expect(capturedUri.query, contains('order='));
    });

    test('returns empty list on HTTP 401', () async {
      final client = MockClient((_) async => http.Response('', 401));
      expect(await _svc(client).fetchSuggestions(), isEmpty);
    });

    test('returns empty list on HTTP 500', () async {
      final client = MockClient((_) async => http.Response('', 500));
      expect(await _svc(client).fetchSuggestions(), isEmpty);
    });

    test('returns empty list on network exception', () async {
      final client = MockClient((_) async => throw http.ClientException('err'));
      expect(await _svc(client).fetchSuggestions(), isEmpty);
    });
  });

  // ── deleteSuggestion ──────────────────────────────────────────────────────

  group('KeywordService.deleteSuggestion', () {
    setUp(() => AuthService.setCurrentUserForTesting(_fakeUser));
    tearDown(AuthService.resetForTesting);

    test('HTTP 200 → true', () async {
      final client = MockClient((_) async => http.Response('', 200));
      expect(await _svc(client).deleteSuggestion('sg-1'), isTrue);
    });

    test('HTTP 204 → true', () async {
      final client = MockClient((_) async => http.Response('', 204));
      expect(await _svc(client).deleteSuggestion('sg-1'), isTrue);
    });

    test('HTTP 400 → false', () async {
      final client = MockClient((_) async => http.Response('', 400));
      expect(await _svc(client).deleteSuggestion('sg-1'), isFalse);
    });

    test('DELETEs to URL with id filter', () async {
      late Uri capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response('', 204);
      });
      await _svc(client).deleteSuggestion('sg-99');
      expect(capturedUri.path, '/rest/v1/keyword_suggestions');
      expect(capturedUri.query, contains('id=eq.sg-99'));
    });

    test('returns false on network exception', () async {
      final client = MockClient((_) async => throw http.ClientException('err'));
      expect(await _svc(client).deleteSuggestion('sg-1'), isFalse);
    });
  });

  // ── approveSuggestion ─────────────────────────────────────────────────────

  group('KeywordService.approveSuggestion', () {
    setUp(() => AuthService.setCurrentUserForTesting(_fakeUser));
    tearDown(AuthService.resetForTesting);

    const suggestion = {
      'id': 'sg-1',
      'keyword': 'lard',
      'category': 'haram',
      'reason': 'pig fat',
    };

    test(
      'returns true when createRule and deleteSuggestion both succeed',
      () async {
        final client = MockClient(
          (req) async => req.method == 'POST'
              ? http.Response('', 201)
              : http.Response('', 204),
        );
        expect(await _svc(client).approveSuggestion(suggestion), isTrue);
      },
    );

    test(
      'returns false and skips deleteSuggestion when createRule fails',
      () async {
        var deleteWasCalled = false;
        final client = MockClient((req) async {
          if (req.method == 'POST') return http.Response('', 400);
          deleteWasCalled = true;
          return http.Response('', 204);
        });
        final result = await _svc(client).approveSuggestion(suggestion);
        expect(result, isFalse);
        expect(deleteWasCalled, isFalse);
      },
    );

    test(
      'returns false when deleteSuggestion fails after createRule succeeds',
      () async {
        final client = MockClient(
          (req) async => req.method == 'POST'
              ? http.Response('', 201)
              : http.Response('', 500),
        );
        expect(await _svc(client).approveSuggestion(suggestion), isFalse);
      },
    );

    test('passes keyword as canonical to createRule', () async {
      Map<String, dynamic>? createBody;
      final client = MockClient((req) async {
        if (req.method == 'POST') {
          createBody = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('', 201);
        }
        return http.Response('', 204);
      });
      await _svc(client).approveSuggestion(suggestion);
      expect(createBody!['canonical'], 'lard');
      expect(createBody!['category'], 'haram');
      expect(createBody!['reason'], 'pig fat');
    });

    test('deletes the suggestion id after successful createRule', () async {
      late Uri deleteUri;
      final client = MockClient((req) async {
        if (req.method == 'DELETE') deleteUri = req.url;
        return req.method == 'POST'
            ? http.Response('', 201)
            : http.Response('', 204);
      });
      await _svc(client).approveSuggestion(suggestion);
      expect(deleteUri.query, contains('id=eq.sg-1'));
    });
  });
}
