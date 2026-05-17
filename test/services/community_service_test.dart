import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/community_service.dart';

// CommunityService uses Supabase.instance.client directly for all data access,
// so full happy-path testing requires a live Supabase connection. These tests
// cover the guard paths (hasSupabase: false / unauthenticated) that must fail
// gracefully without any network calls.
//
// The guard paths are the most critical to test: they prevent crashes when the
// app is run without Supabase configured (e.g. CI without dart-define secrets).

void main() {
  // AppConfig.hasSupabase reads String.fromEnvironment('SUPABASE_URL'), which
  // is empty in the standard test runner (no --dart-define flags), so all
  // CommunityService calls will hit the !AppConfig.hasSupabase guard and return
  // their zero-value immediately.

  group('CommunityService — no Supabase config', () {
    // ── challenges ───────────────────────────────────────────────────────────

    test('getChallenges returns empty list', () async {
      final result = await CommunityService.getChallenges('111222333');
      expect(result, isEmpty);
    });

    test('submitChallenge returns null', () async {
      final result = await CommunityService.submitChallenge(
        barcode: '111222333',
        ingredient: 'gelatin',
        currentVerdict: 'suspicious',
        claimedVerdict: 'haram',
        reason: 'Producer confirmed pork source',
      );
      expect(result, isNull);
    });

    // ── discussions ──────────────────────────────────────────────────────────

    test('getDiscussions returns empty list', () async {
      final result = await CommunityService.getDiscussions('111222333');
      expect(result, isEmpty);
    });

    test('startDiscussion returns null', () async {
      final result = await CommunityService.startDiscussion(
        barcode: '111222333',
        title: 'Is this safe?',
      );
      expect(result, isNull);
    });

    test('startDiscussion with challengeId returns null', () async {
      final result = await CommunityService.startDiscussion(
        barcode: '111222333',
        challengeId: 'ch-uuid',
      );
      expect(result, isNull);
    });

    // ── comments ─────────────────────────────────────────────────────────────

    test('getComments returns empty list', () async {
      final result = await CommunityService.getComments('disc-uuid');
      expect(result, isEmpty);
    });

    test('postComment returns null', () async {
      final result = await CommunityService.postComment(
        discussionId: 'disc-uuid',
        body: 'Test comment',
      );
      expect(result, isNull);
    });

    test('postComment with parentId returns null', () async {
      final result = await CommunityService.postComment(
        discussionId: 'disc-uuid',
        body: 'Reply comment',
        parentId: 'cmt-uuid',
      );
      expect(result, isNull);
    });

    test('softDeleteComment returns false', () async {
      final result = await CommunityService.softDeleteComment('cmt-uuid');
      expect(result, isFalse);
    });

    // ── votes ─────────────────────────────────────────────────────────────────

    test('vote returns null', () async {
      final result = await CommunityService.vote(
        commentId: 'cmt-uuid',
        value: 1,
      );
      expect(result, isNull);
    });

    test('vote with downvote returns null', () async {
      final result = await CommunityService.vote(
        commentId: 'cmt-uuid',
        value: -1,
        currentMyVote: 1,
      );
      expect(result, isNull);
    });

    test('vote retract (currentMyVote == value) returns null', () async {
      final result = await CommunityService.vote(
        commentId: 'cmt-uuid',
        value: 1,
        currentMyVote: 1,
      );
      expect(result, isNull);
    });

    // ── edge cases ────────────────────────────────────────────────────────────

    test(
      'startDiscussion with no title and no challengeId returns null',
      () async {
        final result = await CommunityService.startDiscussion(
          barcode: '111222333',
        );
        expect(result, isNull);
      },
    );

    test(
      'getChallenges for a different barcode still returns empty list',
      () async {
        final result = await CommunityService.getChallenges('000000000000');
        expect(result, isEmpty);
      },
    );

    test('postComment with empty body returns null', () async {
      final result = await CommunityService.postComment(
        discussionId: 'disc-uuid',
        body: '',
      );
      expect(result, isNull);
    });

    // ── empty-string edge cases ───────────────────────────────────────────────

    test('getChallenges with empty barcode returns empty list', () async {
      expect(await CommunityService.getChallenges(''), isEmpty);
    });

    test('getDiscussions with empty barcode returns empty list', () async {
      expect(await CommunityService.getDiscussions(''), isEmpty);
    });

    test('getComments with empty discussionId returns empty list', () async {
      expect(await CommunityService.getComments(''), isEmpty);
    });
  });

  // ── aggregateCommentCounts ────────────────────────────────────────────────

  group('CommunityService.aggregateCommentCounts', () {
    test('empty rows → empty map', () {
      expect(CommunityService.aggregateCommentCounts([]), isEmpty);
    });

    test('single row → count 1 for that discussion', () {
      final result = CommunityService.aggregateCommentCounts([
        {'discussion_id': 'disc-1'},
      ]);
      expect(result, {'disc-1': 1});
    });

    test('two rows for same discussion → count 2', () {
      final result = CommunityService.aggregateCommentCounts([
        {'discussion_id': 'disc-1'},
        {'discussion_id': 'disc-1'},
      ]);
      expect(result['disc-1'], 2);
    });

    test('rows across multiple discussions → independent counts', () {
      final result = CommunityService.aggregateCommentCounts([
        {'discussion_id': 'disc-a'},
        {'discussion_id': 'disc-b'},
        {'discussion_id': 'disc-a'},
        {'discussion_id': 'disc-c'},
        {'discussion_id': 'disc-a'},
      ]);
      expect(result['disc-a'], 3);
      expect(result['disc-b'], 1);
      expect(result['disc-c'], 1);
    });

    test('discussion absent from rows is absent from result map', () {
      final result = CommunityService.aggregateCommentCounts([
        {'discussion_id': 'disc-1'},
      ]);
      expect(result.containsKey('disc-2'), isFalse);
    });
  });

  // ── aggregateVotes ────────────────────────────────────────────────────────

  group('CommunityService.aggregateVotes', () {
    test('empty rows → empty scores and myVotes', () {
      final (:scores, :myVotes) = CommunityService.aggregateVotes([], null);
      expect(scores, isEmpty);
      expect(myVotes, isEmpty);
    });

    test('single upvote → score +1', () {
      final (:scores, :myVotes) = CommunityService.aggregateVotes([
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'user-a'},
      ], null);
      expect(scores['cmt-1'], 1);
      expect(myVotes, isEmpty);
    });

    test('single downvote → score -1', () {
      final (:scores, :myVotes) = CommunityService.aggregateVotes([
        {'comment_id': 'cmt-1', 'value': -1, 'user_id': 'user-a'},
      ], null);
      expect(scores['cmt-1'], -1);
    });

    test('upvote + downvote on same comment → score 0', () {
      final (:scores, :myVotes) = CommunityService.aggregateVotes([
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'user-a'},
        {'comment_id': 'cmt-1', 'value': -1, 'user_id': 'user-b'},
      ], null);
      expect(scores['cmt-1'], 0);
      expect(myVotes, isEmpty);
    });

    test('current user upvote recorded in myVotes', () {
      final (:scores, :myVotes) = CommunityService.aggregateVotes([
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-me'},
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-other'},
      ], 'uid-me');
      expect(myVotes['cmt-1'], 1);
      expect(scores['cmt-1'], 2);
    });

    test('current user downvote recorded as -1 in myVotes', () {
      final (:scores, :myVotes) = CommunityService.aggregateVotes([
        {'comment_id': 'cmt-2', 'value': -1, 'user_id': 'uid-me'},
      ], 'uid-me');
      expect(myVotes['cmt-2'], -1);
      expect(scores['cmt-2'], -1);
    });

    test('null uid → myVotes always empty regardless of votes', () {
      final (:scores, :myVotes) = CommunityService.aggregateVotes([
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-other'},
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-another'},
      ], null);
      expect(myVotes, isEmpty);
      expect(scores['cmt-1'], 2);
    });

    test('votes across multiple comments tracked independently', () {
      final (:scores, :myVotes) = CommunityService.aggregateVotes([
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'user-a'},
        {'comment_id': 'cmt-2', 'value': -1, 'user_id': 'user-b'},
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'user-b'},
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'user-c'},
      ], 'user-a');
      expect(scores['cmt-1'], 3);
      expect(scores['cmt-2'], -1);
      expect(myVotes['cmt-1'], 1);
      expect(myVotes.containsKey('cmt-2'), isFalse);
    });

    test('current user vote overwrites if they appear twice (last wins)', () {
      // Should not happen in practice, but the aggregator uses assignment.
      final (:scores, :myVotes) = CommunityService.aggregateVotes([
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-me'},
        {'comment_id': 'cmt-1', 'value': -1, 'user_id': 'uid-me'},
      ], 'uid-me');
      expect(myVotes['cmt-1'], -1);
      expect(scores['cmt-1'], 0);
    });
  });
}
