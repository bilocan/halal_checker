import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/community.dart';
import 'auth_service.dart';

class CommunityService {
  static SupabaseClient get _db => Supabase.instance.client;
  static String? get _uid => _uidOverride ?? AuthService.currentUser?.id;

  // ── test seams ─────────────────────────────────────────────────────────────
  // Each nullable lambda replaces exactly one Supabase query when set.
  // Production code is unchanged when all are null.

  static bool _supabaseAvailable = AppConfig.hasSupabase;
  static String? _uidOverride;

  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(String)?
  fakeFetchChallenges;
  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(Map<String, dynamic>)?
  fakeInsertChallenge;
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(String)?
  fakeFetchDiscussions;
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(List<String>)?
  fakeFetchCommentCounts;
  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(Map<String, dynamic>)?
  fakeInsertDiscussion;
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(String)? fakeFetchComments;
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(List<String>)?
  fakeFetchVotes;
  @visibleForTesting
  static Future<Map<String, dynamic>?> Function(Map<String, dynamic>)?
  fakeInsertComment;
  @visibleForTesting
  static Future<bool> Function(String commentId, String uid)? fakeSoftDelete;
  @visibleForTesting
  static Future<void> Function(String commentId, String uid)? fakeDeleteVote;
  @visibleForTesting
  static Future<void> Function(Map<String, dynamic>)? fakeUpsertVote;

  @visibleForTesting
  static void enableForTesting({String? uid}) {
    _supabaseAvailable = true;
    _uidOverride = uid;
  }

  @visibleForTesting
  static void resetForTesting() {
    _supabaseAvailable = AppConfig.hasSupabase;
    _uidOverride = null;
    fakeFetchChallenges = null;
    fakeInsertChallenge = null;
    fakeFetchDiscussions = null;
    fakeFetchCommentCounts = null;
    fakeInsertDiscussion = null;
    fakeFetchComments = null;
    fakeFetchVotes = null;
    fakeInsertComment = null;
    fakeSoftDelete = null;
    fakeDeleteVote = null;
    fakeUpsertVote = null;
  }

  // ── challenges ─────────────────────────────────────────────────────────────

  static Future<List<IngredientChallenge>> getChallenges(String barcode) async {
    if (!_supabaseAvailable) return [];
    try {
      final rows = fakeFetchChallenges != null
          ? await fakeFetchChallenges!(barcode)
          : List<Map<String, dynamic>>.from(
              await _db
                      .from('ingredient_challenges')
                      .select('*, profiles(username)')
                      .eq('barcode', barcode)
                      .order('created_at', ascending: false)
                  as List,
            );
      return rows.map(IngredientChallenge.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<IngredientChallenge?> submitChallenge({
    required String barcode,
    required String ingredient,
    required String currentVerdict,
    required String claimedVerdict,
    required String reason,
  }) async {
    final uid = _uid;
    if (!_supabaseAvailable || uid == null) return null;
    try {
      final payload = {
        'barcode': barcode,
        'ingredient': ingredient,
        'current_verdict': currentVerdict,
        'claimed_verdict': claimedVerdict,
        'reason': reason,
        'created_by': uid,
      };
      final row = fakeInsertChallenge != null
          ? await fakeInsertChallenge!(payload)
          : Map<String, dynamic>.from(
              await _db
                      .from('ingredient_challenges')
                      .insert(payload)
                      .select('*, profiles(username)')
                      .single()
                  as Map,
            );
      if (row == null) return null;
      return IngredientChallenge.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  // ── discussions ────────────────────────────────────────────────────────────

  static Future<List<Discussion>> getDiscussions(String barcode) async {
    if (!_supabaseAvailable) return [];
    try {
      final rows = fakeFetchDiscussions != null
          ? await fakeFetchDiscussions!(barcode)
          : List<Map<String, dynamic>>.from(
              await _db
                      .from('discussions')
                      .select('*, profiles(username)')
                      .eq('barcode', barcode)
                      .order('created_at', ascending: false)
                  as List,
            );
      final ids = rows.map((r) => r['id'] as String).toList();
      Map<String, int> counts = {};
      if (ids.isNotEmpty) {
        final countRows = fakeFetchCommentCounts != null
            ? await fakeFetchCommentCounts!(ids)
            : List<Map<String, dynamic>>.from(
                await _db
                        .from('comments')
                        .select('discussion_id')
                        .inFilter('discussion_id', ids)
                        .eq('is_deleted', false)
                    as List,
              );
        counts = aggregateCommentCounts(countRows);
      }
      return rows.map((r) {
        return Discussion.fromJson({
          ...r,
          'comment_count': counts[r['id']] ?? 0,
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @visibleForTesting
  static Map<String, int> aggregateCommentCounts(
    List<Map<String, dynamic>> rows,
  ) {
    final Map<String, int> counts = {};
    for (final r in rows) {
      final id = r['discussion_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  static Future<Discussion?> startDiscussion({
    required String barcode,
    String? challengeId,
    String? title,
  }) async {
    final uid = _uid;
    if (!_supabaseAvailable || uid == null) return null;
    try {
      final payload = <String, dynamic>{
        'barcode': barcode,
        'challenge_id': ?challengeId,
        if (title != null && title.isNotEmpty) 'title': title,
        'created_by': uid,
      };
      final row = fakeInsertDiscussion != null
          ? await fakeInsertDiscussion!(payload)
          : Map<String, dynamic>.from(
              await _db
                      .from('discussions')
                      .insert(payload)
                      .select('*, profiles(username)')
                      .single()
                  as Map,
            );
      return row != null ? Discussion.fromJson(row) : null;
    } catch (_) {
      return null;
    }
  }

  // ── comments ───────────────────────────────────────────────────────────────

  static Future<List<Comment>> getComments(String discussionId) async {
    if (!_supabaseAvailable) return [];
    final uid = _uid;
    try {
      final rows = fakeFetchComments != null
          ? await fakeFetchComments!(discussionId)
          : List<Map<String, dynamic>>.from(
              await _db
                      .from('comments')
                      .select('*, profiles(username, avatar_url)')
                      .eq('discussion_id', discussionId)
                      .order('created_at')
                  as List,
            );

      final commentIds = rows.map((r) => r['id'] as String).toList();
      final Map<String, int> scores = {};
      final Map<String, int> myVotes = {};

      if (commentIds.isNotEmpty) {
        final voteRows = fakeFetchVotes != null
            ? await fakeFetchVotes!(commentIds)
            : List<Map<String, dynamic>>.from(
                await _db
                        .from('comment_votes')
                        .select('comment_id, value, user_id')
                        .inFilter('comment_id', commentIds)
                    as List,
              );
        final agg = aggregateVotes(voteRows, uid);
        scores.addAll(agg.scores);
        myVotes.addAll(agg.myVotes);
      }

      return rows.map((r) {
        final id = r['id'] as String;
        return Comment.fromJson({
          ...r,
          'vote_score': scores[id] ?? 0,
          'my_vote': myVotes[id],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @visibleForTesting
  static ({Map<String, int> scores, Map<String, int> myVotes}) aggregateVotes(
    List<Map<String, dynamic>> voteRows,
    String? uid,
  ) {
    final Map<String, int> scores = {};
    final Map<String, int> myVotes = {};
    for (final v in voteRows) {
      final cid = v['comment_id'] as String;
      scores[cid] = (scores[cid] ?? 0) + (v['value'] as int);
      if (uid != null && v['user_id'] == uid) {
        myVotes[cid] = v['value'] as int;
      }
    }
    return (scores: scores, myVotes: myVotes);
  }

  static Future<Comment?> postComment({
    required String discussionId,
    required String body,
    String? parentId,
  }) async {
    final uid = _uid;
    if (!_supabaseAvailable || uid == null) return null;
    try {
      final payload = <String, dynamic>{
        'discussion_id': discussionId,
        'body': body,
        'parent_id': ?parentId,
        'created_by': uid,
      };
      final row = fakeInsertComment != null
          ? await fakeInsertComment!(payload)
          : Map<String, dynamic>.from(
              await _db
                      .from('comments')
                      .insert(payload)
                      .select('*, profiles(username, avatar_url)')
                      .single()
                  as Map,
            );
      return row != null
          ? Comment.fromJson({...row, 'vote_score': 0, 'my_vote': null})
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> softDeleteComment(String commentId) async {
    final uid = _uid;
    if (!_supabaseAvailable || uid == null) return false;
    try {
      if (fakeSoftDelete != null) return await fakeSoftDelete!(commentId, uid);
      await _db
          .from('comments')
          .update({'body': '', 'is_deleted': true})
          .eq('id', commentId)
          .eq('created_by', uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── votes ──────────────────────────────────────────────────────────────────

  /// Upvotes (+1) or downvotes (-1). Passing the same value twice retracts it.
  static Future<int?> vote({
    required String commentId,
    required int value, // 1 or -1
    int? currentMyVote,
  }) async {
    final uid = _uid;
    if (!_supabaseAvailable || uid == null) return null;
    try {
      if (currentMyVote == value) {
        if (fakeDeleteVote != null) {
          await fakeDeleteVote!(commentId, uid);
        } else {
          await _db
              .from('comment_votes')
              .delete()
              .eq('comment_id', commentId)
              .eq('user_id', uid);
        }
        return 0;
      }
      final payload = {'comment_id': commentId, 'user_id': uid, 'value': value};
      if (fakeUpsertVote != null) {
        await fakeUpsertVote!(payload);
      } else {
        await _db.from('comment_votes').upsert(payload);
      }
      return value;
    } catch (_) {
      return null;
    }
  }
}
