import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/community.dart';
import 'auth_service.dart';

class CommunityService {
  static SupabaseClient get _db => Supabase.instance.client;
  static String? get _uid => AuthService.currentUser?.id;

  // ── challenges ─────────────────────────────────────────────────────────────

  static Future<List<IngredientChallenge>> getChallenges(String barcode) async {
    if (!AppConfig.hasSupabase) return [];
    try {
      final rows = await _db
          .from('ingredient_challenges')
          .select('*, profiles(username)')
          .eq('barcode', barcode)
          .order('created_at', ascending: false);
      return rows.map((r) => IngredientChallenge.fromJson(r)).toList();
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
    if (!AppConfig.hasSupabase || uid == null) return null;
    try {
      final row = await _db
          .from('ingredient_challenges')
          .insert({
            'barcode': barcode,
            'ingredient': ingredient,
            'current_verdict': currentVerdict,
            'claimed_verdict': claimedVerdict,
            'reason': reason,
            'created_by': uid,
          })
          .select('*, profiles(username)')
          .single();
      return IngredientChallenge.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  // ── discussions ────────────────────────────────────────────────────────────

  static Future<List<Discussion>> getDiscussions(String barcode) async {
    if (!AppConfig.hasSupabase) return [];
    try {
      final rows = await _db
          .from('discussions')
          .select('*, profiles(username)')
          .eq('barcode', barcode)
          .order('created_at', ascending: false);
      final ids = rows.map((r) => r['id'] as String).toList();
      Map<String, int> counts = {};
      if (ids.isNotEmpty) {
        final countRows = await _db
            .from('comments')
            .select('discussion_id')
            .inFilter('discussion_id', ids)
            .eq('is_deleted', false);
        counts = aggregateCommentCounts(
          List<Map<String, dynamic>>.from(countRows as List),
        );
      }
      return rows.map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        return Discussion.fromJson({
          ...m,
          'comment_count': counts[m['id']] ?? 0,
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
    if (!AppConfig.hasSupabase || uid == null) return null;
    try {
      final row = await _db
          .from('discussions')
          .insert({
            'barcode': barcode,
            if (challengeId != null) 'challenge_id': challengeId,
            if (title != null && title.isNotEmpty) 'title': title,
            'created_by': uid,
          })
          .select('*, profiles(username)')
          .single();
      return Discussion.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  // ── comments ───────────────────────────────────────────────────────────────

  static Future<List<Comment>> getComments(String discussionId) async {
    if (!AppConfig.hasSupabase) return [];
    final uid = _uid;
    try {
      final rows = await _db
          .from('comments')
          .select('*, profiles(username, avatar_url)')
          .eq('discussion_id', discussionId)
          .order('created_at');

      final commentIds = rows.map((r) => r['id'] as String).toList();
      final Map<String, int> scores = {};
      final Map<String, int> myVotes = {};

      if (commentIds.isNotEmpty) {
        final voteRows = await _db
            .from('comment_votes')
            .select('comment_id, value, user_id')
            .inFilter('comment_id', commentIds);
        final agg = aggregateVotes(
          List<Map<String, dynamic>>.from(voteRows as List),
          uid,
        );
        scores.addAll(agg.scores);
        myVotes.addAll(agg.myVotes);
      }

      return rows.map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        final id = m['id'] as String;
        return Comment.fromJson({
          ...m,
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
    if (!AppConfig.hasSupabase || uid == null) return null;
    try {
      final row = await _db
          .from('comments')
          .insert({
            'discussion_id': discussionId,
            'body': body,
            if (parentId != null) 'parent_id': parentId,
            'created_by': uid,
          })
          .select('*, profiles(username, avatar_url)')
          .single();
      return Comment.fromJson({...row, 'vote_score': 0, 'my_vote': null});
    } catch (_) {
      return null;
    }
  }

  static Future<bool> softDeleteComment(String commentId) async {
    final uid = _uid;
    if (!AppConfig.hasSupabase || uid == null) return false;
    try {
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
    if (!AppConfig.hasSupabase || uid == null) return null;
    try {
      if (currentMyVote == value) {
        await _db
            .from('comment_votes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', uid);
        return 0;
      }
      await _db.from('comment_votes').upsert({
        'comment_id': commentId,
        'user_id': uid,
        'value': value,
      });
      return value;
    } catch (_) {
      return null;
    }
  }
}
