import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:halal_checker/services/keyword_service.dart';

const _fakeUrl = 'https://test.supabase.co';
const _fakeKey = 'test_anon_key';

KeywordService _serviceWithClient(MockClient client) => KeywordService(
  client: client,
  hasSupabase: true,
  supabaseUrl: _fakeUrl,
  anonKey: _fakeKey,
);

void main() {
  group('KeywordService — hasSupabase: false (no Supabase config)', () {
    late KeywordService service;

    setUp(() => service = KeywordService(hasSupabase: false));

    test('fetchCustomKeywords returns empty list', () async {
      expect(await service.fetchCustomKeywords(), isEmpty);
    });

    test('suggestKeyword returns false', () async {
      final result = await service.suggestKeyword(
        keyword: 'lard',
        category: 'haram',
        reason: 'pig fat',
      );
      expect(result, isFalse);
    });
  });

  group('KeywordService.fetchCustomKeywords — HTTP paths', () {
    test('returns parsed keyword list on HTTP 200', () async {
      final client = MockClient((_) async {
        return http.Response(
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
        );
      });

      final result = await _serviceWithClient(client).fetchCustomKeywords();
      expect(result.length, equals(2));
      expect(result.first['canonical'], equals('lard'));
      expect(result.last['canonical'], equals('gelatin'));
    });

    test('sends correct URL and auth headers', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;

      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        return http.Response(jsonEncode([]), 200);
      });

      await _serviceWithClient(client).fetchCustomKeywords();

      expect(capturedUri.host, equals('test.supabase.co'));
      expect(capturedUri.path, equals('/rest/v1/keywords'));
      expect(capturedHeaders['apikey'], equals(_fakeKey));
      expect(capturedHeaders['Authorization'], equals('Bearer $_fakeKey'));
    });

    test('returns empty list on HTTP 401', () async {
      final client = MockClient(
        (_) async => http.Response('Unauthorized', 401),
      );
      expect(await _serviceWithClient(client).fetchCustomKeywords(), isEmpty);
    });

    test('returns empty list on HTTP 500', () async {
      final client = MockClient((_) async => http.Response('Error', 500));
      expect(await _serviceWithClient(client).fetchCustomKeywords(), isEmpty);
    });

    test('returns empty list on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Network error'),
      );
      expect(await _serviceWithClient(client).fetchCustomKeywords(), isEmpty);
    });
  });

  group('KeywordService.suggestKeyword — HTTP paths', () {
    test('returns true on HTTP 201', () async {
      final client = MockClient((_) async => http.Response('', 201));
      final result = await _serviceWithClient(
        client,
      ).suggestKeyword(keyword: 'lard', category: 'haram', reason: 'pig fat');
      expect(result, isTrue);
    });

    test(
      'normalizes keyword to lowercase and trimmed before sending',
      () async {
        String? sentKeyword;
        final client = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          sentKeyword = body['keyword'] as String;
          return http.Response('', 201);
        });

        await _serviceWithClient(client).suggestKeyword(
          keyword: '  PORK FAT  ',
          category: 'haram',
          reason: 'pig-derived',
        );
        expect(sentKeyword, equals('pork fat'));
      },
    );

    test('sends correct request body fields', () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });

      await _serviceWithClient(client).suggestKeyword(
        keyword: 'gelatin',
        category: 'haram',
        reason: '  animal bones  ',
      );

      expect(sentBody!['keyword'], equals('gelatin'));
      expect(sentBody!['category'], equals('haram'));
      expect(sentBody!['reason'], equals('animal bones'));
    });

    test('sends correct URL and auth headers', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;

      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        return http.Response('', 201);
      });

      await _serviceWithClient(
        client,
      ).suggestKeyword(keyword: 'lard', category: 'haram', reason: 'reason');

      expect(capturedUri.path, equals('/rest/v1/keyword_suggestions'));
      expect(capturedHeaders['apikey'], equals(_fakeKey));
      expect(capturedHeaders['Content-Type'], contains('application/json'));
    });

    test('returns false on HTTP 400', () async {
      final client = MockClient((_) async => http.Response('Bad Request', 400));
      final result = await _serviceWithClient(
        client,
      ).suggestKeyword(keyword: 'lard', category: 'haram', reason: 'reason');
      expect(result, isFalse);
    });

    test('returns false on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Timeout'),
      );
      final result = await _serviceWithClient(
        client,
      ).suggestKeyword(keyword: 'lard', category: 'haram', reason: 'reason');
      expect(result, isFalse);
    });
  });
}
