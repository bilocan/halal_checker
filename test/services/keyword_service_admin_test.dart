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
  // ── hasSupabase: false guard paths ─────────────────────────────────────

  group('KeywordService — hasSupabase: false guard paths', () {
    late KeywordService service;

    setUp(() => service = KeywordService(hasSupabase: false));

    test('fetchAllRules returns empty list', () async {
      expect(await service.fetchAllRules(), isEmpty);
    });

    test('createRule returns false', () async {
      final result = await service.createRule(
        canonical: 'lard',
        category: 'haram',
        reason: 'pig fat',
      );
      expect(result, isFalse);
    });

    test('updateRule returns false', () async {
      final result = await service.updateRule(
        id: 'rule-1',
        canonical: 'lard',
        category: 'haram',
        reason: 'pig fat',
      );
      expect(result, isFalse);
    });

    test('deleteRule returns false', () async {
      expect(await service.deleteRule('rule-1'), isFalse);
    });

    test('fetchSuggestions returns empty list', () async {
      expect(await service.fetchSuggestions(), isEmpty);
    });

    test('deleteSuggestion returns false', () async {
      expect(await service.deleteSuggestion('sugg-1'), isFalse);
    });
  });

  // ── fetchAllRules — Supabase not initialized ──────────────────────────
  // fetchAllRules accesses Supabase.instance for the JWT token. When
  // Supabase is not initialized, the catch block returns [].

  group('KeywordService.fetchAllRules — without Supabase init', () {
    test('returns empty list when Supabase is not initialized', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode([]), 200),
      );
      final result = await _serviceWithClient(client).fetchAllRules();
      expect(result, isEmpty);
    });
  });

  // ── fetchSuggestions — Supabase not initialized ───────────────────────

  group('KeywordService.fetchSuggestions — without Supabase init', () {
    test('returns empty list when Supabase is not initialized', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode([]), 200),
      );
      final result = await _serviceWithClient(client).fetchSuggestions();
      expect(result, isEmpty);
    });
  });

  // ── createRule — AuthService.currentUser guard ─────────────────────────
  // createRule checks AuthService.currentUser != null. Without Supabase
  // init, currentUser is always null, so createRule returns false.

  group('KeywordService.createRule — no auth', () {
    test('returns false when user is not authenticated', () async {
      final client = MockClient((_) async => http.Response('', 201));
      final result = await _serviceWithClient(
        client,
      ).createRule(canonical: 'lard', category: 'haram', reason: 'pig fat');
      expect(result, isFalse);
    });

    test(
      'returns false with variants when user is not authenticated',
      () async {
        final client = MockClient((_) async => http.Response('', 201));
        final result = await _serviceWithClient(client).createRule(
          canonical: 'lard',
          category: 'haram',
          reason: 'pig fat',
          variants: ['schmalz', 'saindoux'],
        );
        expect(result, isFalse);
      },
    );
  });

  // ── updateRule — AuthService.currentUser guard ─────────────────────────

  group('KeywordService.updateRule — no auth', () {
    test('returns false when user is not authenticated', () async {
      final client = MockClient((_) async => http.Response('', 204));
      final result = await _serviceWithClient(client).updateRule(
        id: 'rule-1',
        canonical: 'lard',
        category: 'haram',
        reason: 'pig fat',
      );
      expect(result, isFalse);
    });

    test(
      'returns false with variants when user is not authenticated',
      () async {
        final client = MockClient((_) async => http.Response('', 204));
        final result = await _serviceWithClient(client).updateRule(
          id: 'rule-1',
          canonical: 'lard',
          category: 'haram',
          reason: 'pig fat',
          variants: ['schmalz'],
        );
        expect(result, isFalse);
      },
    );
  });

  // ── deleteRule — AuthService.currentUser guard ─────────────────────────

  group('KeywordService.deleteRule — no auth', () {
    test('returns false when user is not authenticated', () async {
      final client = MockClient((_) async => http.Response('', 204));
      expect(await _serviceWithClient(client).deleteRule('rule-1'), isFalse);
    });
  });

  // ── deleteSuggestion — AuthService.currentUser guard ──────────────────

  group('KeywordService.deleteSuggestion — no auth', () {
    test('returns false when user is not authenticated', () async {
      final client = MockClient((_) async => http.Response('', 204));
      expect(
        await _serviceWithClient(client).deleteSuggestion('sugg-1'),
        isFalse,
      );
    });
  });

  // ── approveSuggestion ─────────────────────────────────────────────────
  // approveSuggestion delegates to createRule, so without auth it fails.

  group('KeywordService.approveSuggestion — no auth', () {
    test('returns false when user is not authenticated', () async {
      final client = MockClient((_) async => http.Response('', 201));
      final result = await _serviceWithClient(client).approveSuggestion({
        'keyword': 'shellac',
        'category': 'suspicious',
        'reason': 'insect-derived',
        'id': 'sugg-1',
      });
      expect(result, isFalse);
    });
  });
}
