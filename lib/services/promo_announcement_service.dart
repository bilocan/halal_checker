import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// Promo popup row from `promo_announcement` (single row, id = 1).
class PromoAnnouncement {
  const PromoAnnouncement({
    required this.campaignId,
    this.imageUrl,
    this.linkUrl,
    this.showInApp = false,
    this.showOnWeb = false,
    this.endsAt,
  });

  final String campaignId;
  final String? imageUrl;
  final String? linkUrl;
  final bool showInApp;
  final bool showOnWeb;
  final DateTime? endsAt;

  factory PromoAnnouncement.fromJson(Map<String, dynamic> json) {
    final endsRaw = json['ends_at'];
    return PromoAnnouncement(
      campaignId: (json['campaign_id'] ?? '').toString(),
      imageUrl: _nonEmpty(json['image_url']),
      linkUrl: _nonEmpty(json['link_url']),
      showInApp: json['show_in_app'] == true,
      showOnWeb: json['show_on_web'] == true,
      endsAt: endsRaw is String ? DateTime.tryParse(endsRaw) : null,
    );
  }

  static String? _nonEmpty(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  bool get hasContent => imageUrl != null && linkUrl != null;

  bool isExpired(DateTime now) => endsAt != null && !now.isBefore(endsAt!);

  /// Whether the app should consider showing this promo at [now].
  bool isActiveInAppAt(DateTime now) =>
      showInApp && hasContent && campaignId.isNotEmpty && !isExpired(now);
}

/// Loads, dismisses and (for superadmins) edits the promo popup.
class PromoAnnouncementService {
  static const table = 'promo_announcement';
  static const bucket = 'promo-images';
  static const dismissedPrefsKey = 'promo_dismissed_campaign_id';
  static const _fetchTimeout = Duration(seconds: 8);

  static bool _shownThisLaunch = false;

  @visibleForTesting
  static Future<PromoAnnouncement?> Function()? fakeFetch;

  @visibleForTesting
  static DateTime Function()? fakeNow;

  @visibleForTesting
  static bool? fakeHasSupabase;

  @visibleForTesting
  static SupabaseClient? fakeClient;

  @visibleForTesting
  static void resetTestOverrides() {
    fakeFetch = null;
    fakeNow = null;
    fakeHasSupabase = null;
    fakeClient = null;
    _shownThisLaunch = false;
  }

  static bool get _hasSupabase => fakeHasSupabase ?? AppConfig.hasSupabase;
  static SupabaseClient get _db => fakeClient ?? Supabase.instance.client;

  /// Fetches the promo row. Returns null when unavailable or on error.
  static Future<PromoAnnouncement?> fetch() async {
    if (fakeFetch != null) return fakeFetch!();
    if (!_hasSupabase) return null;
    try {
      final row = await _db
          .from(table)
          .select()
          .eq('id', 1)
          .maybeSingle()
          .timeout(_fetchTimeout);
      if (row == null) return null;
      return PromoAnnouncement.fromJson(row);
    } catch (e) {
      debugPrint('[PromoAnnouncementService] fetch failed: $e');
      return null;
    }
  }

  static Future<bool> isDismissed(String campaignId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(dismissedPrefsKey) == campaignId;
  }

  static Future<void> dismiss(String campaignId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dismissedPrefsKey, campaignId);
  }

  /// Returns the promo to show on this launch, or null.
  /// At most one non-null result per app process.
  static Future<PromoAnnouncement?> promoToShow() async {
    if (_shownThisLaunch) return null;
    final promo = await fetch();
    if (promo == null) return null;
    final now = fakeNow?.call() ?? DateTime.now();
    if (!promo.isActiveInAppAt(now)) return null;
    if (await isDismissed(promo.campaignId)) return null;
    _shownThisLaunch = true;
    return promo;
  }

  // ── Superadmin editing ───────────────────────────────────────────────────

  /// Updates the promo row. RLS restricts this to superadmins.
  static Future<bool> update({
    required String? imageUrl,
    required String? linkUrl,
    required bool showInApp,
    required bool showOnWeb,
    required DateTime? endsAt,
  }) async {
    if (!_hasSupabase) return false;
    try {
      final rows = await _db
          .from(table)
          .update({
            'image_url': imageUrl,
            'link_url': linkUrl,
            'show_in_app': showInApp,
            'show_on_web': showOnWeb,
            'ends_at': endsAt?.toUtc().toIso8601String(),
          })
          .eq('id', 1)
          .select('id');
      // RLS denial on UPDATE returns zero rows instead of throwing.
      return rows.isNotEmpty;
    } catch (e) {
      debugPrint('[PromoAnnouncementService] update failed: $e');
      return false;
    }
  }

  /// Uploads a poster to the `promo-images` bucket; returns its public URL.
  static Future<String?> uploadImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!_hasSupabase || bytes.isEmpty) return null;
    try {
      final ext = imageExtension(fileName);
      final path = 'promo_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _db.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeTypeForExtension(ext),
              upsert: true,
            ),
          );
      return _db.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('[PromoAnnouncementService] upload failed: $e');
      return null;
    }
  }

  @visibleForTesting
  static String imageExtension(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (ext.isEmpty) return 'jpg';
    final bare = ext.substring(1);
    const allowed = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
    if (!allowed.contains(bare)) return 'jpg';
    return bare == 'jpeg' ? 'jpg' : bare;
  }

  @visibleForTesting
  static String mimeTypeForExtension(String ext) => switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'image/jpeg',
  };

  /// True for absolute http(s) URLs with a host.
  static bool isValidHttpUrl(String? value) {
    if (value == null) return false;
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
