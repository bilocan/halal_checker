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
  });
}
