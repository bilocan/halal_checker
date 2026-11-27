import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/events_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Routes EventsService's Supabase calls through [handler]. Responses get the
/// originating request attached (postgrest reads `response.request`).
void _useMockSupabase(Future<http.Response> Function(http.Request) handler) {
  EventsService.fakeHasSupabase = true;
  EventsService.fakeClient = SupabaseClient(
    'https://example.supabase.co',
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
  );
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

AppEvent _event(String id, DateTime start, [DateTime? end]) =>
    AppEvent(id: id, title: id, startsAt: start, endsAt: end);

void main() {
  tearDown(EventsService.resetTestOverrides);

  group('AppEvent.fromJson', () {
    test('parses fields and trims empty strings', () {
      final e = AppEvent.fromJson({
        'id': 'a',
        'title': 'Seminar',
        'description': ' ',
        'image_url': 'https://x/p.jpg',
        'link_url': 'https://x',
        'starts_at': '2026-12-05T18:00:00+00:00',
        'ends_at': '2026-12-19T18:00:00+00:00',
        'published': false,
      });
      expect(e.title, 'Seminar');
      expect(e.description, isNull);
      expect(e.imageUrl, 'https://x/p.jpg');
      expect(e.startsAt, DateTime.utc(2026, 12, 5, 18));
      expect(e.endsAt, DateTime.utc(2026, 12, 19, 18));
      expect(e.published, isFalse);
    });

    test('published defaults to true, ends_at optional', () {
      final e = AppEvent.fromJson({
        'id': 'a',
        'title': 'x',
        'starts_at': '2026-12-05T18:00:00Z',
      });
      expect(e.published, isTrue);
      expect(e.endsAt, isNull);
      expect(e.lastAt, e.startsAt);
    });
  });

  group('isPastAt', () {
    final start = DateTime(2026, 12, 5, 19); // local
    test('upcoming for the whole day of the event', () {
      final e = _event('a', start);
      expect(e.isPastAt(DateTime(2026, 12, 5, 23, 59)), isFalse);
      expect(e.isPastAt(DateTime(2026, 12, 6)), isTrue);
    });

    test('multi-date event uses its end date', () {
      final e = _event('a', start, DateTime(2026, 12, 19, 19));
      expect(e.isPastAt(DateTime(2026, 12, 12)), isFalse);
      expect(e.isPastAt(DateTime(2026, 12, 20)), isTrue);
    });
  });

  group('EventsSplit', () {
    test('upcoming soonest first, past most recent first', () {
      final now = DateTime(2026, 12, 10);
      final split = EventsSplit.from([
        _event('later', DateTime(2027, 1, 20)),
        _event('old', DateTime(2026, 10, 1)),
        _event('soon', DateTime(2026, 12, 12)),
        _event('recent', DateTime(2026, 11, 1)),
        _event('running', DateTime(2026, 12, 5), DateTime(2026, 12, 19)),
      ], now);
      expect(split.upcoming.map((e) => e.id), ['running', 'soon', 'later']);
      expect(split.past.map((e) => e.id), ['recent', 'old']);
      expect(split.isEmpty, isFalse);
    });

    test('empty', () {
      expect(EventsSplit.from([], DateTime.now()).isEmpty, isTrue);
    });
  });

  test('fetchPublished filters drafts', () async {
    EventsService.fakeFetchAll = () async => [
      AppEvent(id: 'p', title: 'p', startsAt: DateTime(2026, 12, 5)),
      AppEvent(
        id: 'd',
        title: 'd',
        startsAt: DateTime(2026, 12, 5),
        published: false,
      ),
    ];
    final list = await EventsService.fetchPublished();
    expect(list!.map((e) => e.id), ['p']);
  });

  test('fetchPublished null on failure', () async {
    EventsService.fakeFetchAll = () async => null;
    expect(await EventsService.fetchPublished(), isNull);
  });

  group('fetchAll via Supabase', () {
    test('null when Supabase not configured', () async {
      EventsService.fakeHasSupabase = false;
      expect(await EventsService.fetchAll(), isNull);
    });

    test('queries events ordered by start and parses rows', () async {
      _useMockSupabase((req) async {
        expect(req.method, 'GET');
        expect(req.url.path, '/rest/v1/events');
        expect(req.url.queryParameters['order'], startsWith('starts_at.asc'));
        return _json([
          {
            'id': 'a',
            'title': 'Seminar',
            'starts_at': '2026-12-05T18:00:00Z',
            'ends_at': '2026-12-19T18:00:00Z',
            'published': true,
          },
          {
            'id': 'b',
            'title': 'Draft',
            'starts_at': '2027-01-10T18:00:00Z',
            'published': false,
          },
        ]);
      });
      final events = await EventsService.fetchAll();
      expect(events!.map((e) => e.id), ['a', 'b']);
      expect(events.first.endsAt, DateTime.utc(2026, 12, 19, 18));
      expect((await EventsService.fetchPublished())!.map((e) => e.id), ['a']);
    });

    test('null on server error', () async {
      _useMockSupabase((_) async => _json({'message': 'boom'}, 500));
      expect(await EventsService.fetchAll(), isNull);
    });
  });
}
