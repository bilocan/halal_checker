import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// Row from the `events` table (admin-managed; listed in the Events screen).
class AppEvent {
  const AppEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    this.description,
    this.imageUrl,
    this.linkUrl,
    this.endsAt,
    this.published = true,
  });

  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? linkUrl;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool published;

  factory AppEvent.fromJson(Map<String, dynamic> json) => AppEvent(
    id: json['id'].toString(),
    title: (json['title'] ?? '').toString(),
    description: _nonEmpty(json['description']),
    imageUrl: _nonEmpty(json['image_url']),
    linkUrl: _nonEmpty(json['link_url']),
    startsAt: DateTime.parse(json['starts_at'].toString()),
    endsAt: json['ends_at'] is String
        ? DateTime.tryParse(json['ends_at'] as String)
        : null,
    published: json['published'] != false,
  );

  static String? _nonEmpty(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Last moment of the event (end, or start for single-date events).
  DateTime get lastAt => endsAt ?? startsAt;

  /// Past once the local calendar day of [lastAt] is over, so an event stays
  /// "upcoming" for the whole day it takes place.
  bool isPastAt(DateTime now) {
    final last = lastAt.toLocal();
    final endOfDay = DateTime(last.year, last.month, last.day + 1);
    return !now.isBefore(endOfDay);
  }
}

/// Upcoming events (soonest first) and past events (most recent first).
class EventsSplit {
  const EventsSplit({required this.upcoming, required this.past});
  final List<AppEvent> upcoming;
  final List<AppEvent> past;

  bool get isEmpty => upcoming.isEmpty && past.isEmpty;

  factory EventsSplit.from(List<AppEvent> events, DateTime now) {
    final upcoming = <AppEvent>[];
    final past = <AppEvent>[];
    for (final e in events) {
      (e.isPastAt(now) ? past : upcoming).add(e);
    }
    upcoming.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    past.sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return EventsSplit(upcoming: upcoming, past: past);
  }
}

class EventsService {
  static const table = 'events';
  static const _timeout = Duration(seconds: 10);

  @visibleForTesting
  static Future<List<AppEvent>?> Function()? fakeFetchAll;

  @visibleForTesting
  static void resetTestOverrides() => fakeFetchAll = null;

  /// Events visible to the current user (RLS: published only, superadmins
  /// also get drafts). Returns null on error.
  static Future<List<AppEvent>?> fetchAll() async {
    if (fakeFetchAll != null) return fakeFetchAll!();
    if (!AppConfig.hasSupabase) return null;
    try {
      final rows = await Supabase.instance.client
          .from(table)
          .select()
          .order('starts_at', ascending: true)
          .timeout(_timeout);
      return rows.map(AppEvent.fromJson).toList();
    } catch (e) {
      debugPrint('[EventsService] fetchAll failed: $e');
      return null;
    }
  }

  /// Published events only (for the public list, even when viewed by a
  /// superadmin).
  static Future<List<AppEvent>?> fetchPublished() async {
    final all = await fetchAll();
    return all?.where((e) => e.published).toList();
  }
}
