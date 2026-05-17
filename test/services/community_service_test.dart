import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/community_service.dart';

// Minimal row factories matching what Supabase returns for each table.

Map<String, dynamic> _challengeRow({
  String id = 'chal-1',
  String barcode = '111222333',
  String ingredient = 'gelatin',
  String currentVerdict = 'suspicious',
  String claimedVerdict = 'haram',
  String reason = 'Producer confirmed pork source',
  String status = 'open',
  String createdBy = 'uid-1',
  String? username = 'tester',
}) => {
  'id': id,
  'barcode': barcode,
  'ingredient': ingredient,
  'current_verdict': currentVerdict,
  'claimed_verdict': claimedVerdict,
  'reason': reason,
  'status': status,
  'created_by': createdBy,
  'created_at': '2024-01-01T00:00:00',
  'profiles': username != null ? {'username': username} : null,
};

Map<String, dynamic> _discussionRow({
  String id = 'disc-1',
  String barcode = '111222333',
  String createdBy = 'uid-1',
  String? username = 'tester',
  String? title,
  String? challengeId,
}) => {
  'id': id,
  'barcode': barcode,
  'created_by': createdBy,
  'created_at': '2024-01-01T00:00:00',
  'is_locked': false,
  'profiles': username != null ? {'username': username} : null,
  'title': ?title,
  'challenge_id': ?challengeId,
};

Map<String, dynamic> _commentRow({
  String id = 'cmt-1',
  String discussionId = 'disc-1',
  String body = 'Test comment',
  String createdBy = 'uid-1',
  String? username = 'tester',
  String? avatarUrl,
  String? parentId,
}) => {
  'id': id,
  'discussion_id': discussionId,
  'body': body,
  'is_deleted': false,
  'created_by': createdBy,
  'created_at': '2024-01-01T00:00:00',
  'profiles': {'username': username, 'avatar_url': avatarUrl},
  'parent_id': ?parentId,
};

void main() {
  tearDown(CommunityService.resetForTesting);

  // ── no Supabase config (guard-path) ───────────────────────────────────────

  group('CommunityService — no Supabase config', () {
    test('getChallenges returns empty list', () async {
      expect(await CommunityService.getChallenges('111222333'), isEmpty);
    });

    test('submitChallenge returns null', () async {
      expect(
        await CommunityService.submitChallenge(
          barcode: '111222333',
          ingredient: 'gelatin',
          currentVerdict: 'suspicious',
          claimedVerdict: 'haram',
          reason: 'test',
        ),
        isNull,
      );
    });

    test('getDiscussions returns empty list', () async {
      expect(await CommunityService.getDiscussions('111222333'), isEmpty);
    });

    test('startDiscussion returns null', () async {
      expect(
        await CommunityService.startDiscussion(barcode: '111222333'),
        isNull,
      );
    });

    test('getComments returns empty list', () async {
      expect(await CommunityService.getComments('disc-uuid'), isEmpty);
    });

    test('postComment returns null', () async {
      expect(
        await CommunityService.postComment(
          discussionId: 'disc-uuid',
          body: 'hello',
        ),
        isNull,
      );
    });

    test('softDeleteComment returns false', () async {
      expect(await CommunityService.softDeleteComment('cmt-uuid'), isFalse);
    });

    test('vote returns null', () async {
      expect(
        await CommunityService.vote(commentId: 'cmt-uuid', value: 1),
        isNull,
      );
    });

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

  // ── unauthenticated (Supabase enabled but no uid) ─────────────────────────

  group('CommunityService — authenticated methods require uid', () {
    setUp(() => CommunityService.enableForTesting()); // no uid

    test('submitChallenge returns null when uid is null', () async {
      expect(
        await CommunityService.submitChallenge(
          barcode: '111222333',
          ingredient: 'gelatin',
          currentVerdict: 'suspicious',
          claimedVerdict: 'haram',
          reason: 'test',
        ),
        isNull,
      );
    });

    test('startDiscussion returns null when uid is null', () async {
      expect(
        await CommunityService.startDiscussion(barcode: '111222333'),
        isNull,
      );
    });

    test('postComment returns null when uid is null', () async {
      expect(
        await CommunityService.postComment(
          discussionId: 'disc-uuid',
          body: 'hello',
        ),
        isNull,
      );
    });

    test('softDeleteComment returns false when uid is null', () async {
      expect(await CommunityService.softDeleteComment('cmt-uuid'), isFalse);
    });

    test('vote returns null when uid is null', () async {
      expect(
        await CommunityService.vote(commentId: 'cmt-uuid', value: 1),
        isNull,
      );
    });
  });

  // ── getChallenges ─────────────────────────────────────────────────────────

  group('CommunityService.getChallenges', () {
    setUp(() => CommunityService.enableForTesting());

    test('maps rows to IngredientChallenge list', () async {
      CommunityService.fakeFetchChallenges = (_) async => [
        _challengeRow(id: 'c1', ingredient: 'pork', status: 'open'),
        _challengeRow(id: 'c2', ingredient: 'alcohol', status: 'resolved'),
      ];
      final result = await CommunityService.getChallenges('111222333');
      expect(result, hasLength(2));
      expect(result[0].id, 'c1');
      expect(result[0].ingredient, 'pork');
      expect(result[1].id, 'c2');
      expect(result[1].status, 'resolved');
    });

    test('passes barcode to query', () async {
      String? capturedBarcode;
      CommunityService.fakeFetchChallenges = (b) async {
        capturedBarcode = b;
        return [];
      };
      await CommunityService.getChallenges('9876543210');
      expect(capturedBarcode, '9876543210');
    });

    test('maps username from nested profiles', () async {
      CommunityService.fakeFetchChallenges = (_) async => [
        _challengeRow(username: 'alice'),
      ];
      final result = await CommunityService.getChallenges('111222333');
      expect(result.first.createdByUsername, 'alice');
    });

    test('returns empty list on exception', () async {
      CommunityService.fakeFetchChallenges = (_) async =>
          throw Exception('DB error');
      expect(await CommunityService.getChallenges('111222333'), isEmpty);
    });

    test('returns empty list when no rows', () async {
      CommunityService.fakeFetchChallenges = (_) async => [];
      expect(await CommunityService.getChallenges('111222333'), isEmpty);
    });
  });

  // ── submitChallenge ───────────────────────────────────────────────────────

  group('CommunityService.submitChallenge', () {
    setUp(() => CommunityService.enableForTesting(uid: 'uid-me'));

    test('returns IngredientChallenge on success', () async {
      CommunityService.fakeInsertChallenge = (_) async =>
          _challengeRow(ingredient: 'gelatin', claimedVerdict: 'haram');
      final result = await CommunityService.submitChallenge(
        barcode: '111222333',
        ingredient: 'gelatin',
        currentVerdict: 'suspicious',
        claimedVerdict: 'haram',
        reason: 'Producer confirmed',
      );
      expect(result, isNotNull);
      expect(result!.ingredient, 'gelatin');
      expect(result.claimedVerdict, 'haram');
    });

    test('payload includes all required fields including uid', () async {
      Map<String, dynamic>? captured;
      CommunityService.fakeInsertChallenge = (p) async {
        captured = p;
        return _challengeRow();
      };
      await CommunityService.submitChallenge(
        barcode: '111222333',
        ingredient: 'pork',
        currentVerdict: 'halal',
        claimedVerdict: 'haram',
        reason: 'It is pork',
      );
      expect(captured!['barcode'], '111222333');
      expect(captured!['ingredient'], 'pork');
      expect(captured!['current_verdict'], 'halal');
      expect(captured!['claimed_verdict'], 'haram');
      expect(captured!['reason'], 'It is pork');
      expect(captured!['created_by'], 'uid-me');
    });

    test('returns null when insert returns null', () async {
      CommunityService.fakeInsertChallenge = (_) async => null;
      final result = await CommunityService.submitChallenge(
        barcode: '111222333',
        ingredient: 'gelatin',
        currentVerdict: 'suspicious',
        claimedVerdict: 'haram',
        reason: 'test',
      );
      expect(result, isNull);
    });

    test('returns null on exception', () async {
      CommunityService.fakeInsertChallenge = (_) async =>
          throw Exception('DB error');
      expect(
        await CommunityService.submitChallenge(
          barcode: '111222333',
          ingredient: 'gelatin',
          currentVerdict: 'suspicious',
          claimedVerdict: 'haram',
          reason: 'test',
        ),
        isNull,
      );
    });
  });

  // ── getDiscussions ────────────────────────────────────────────────────────

  group('CommunityService.getDiscussions', () {
    setUp(() => CommunityService.enableForTesting());

    test(
      'maps rows to Discussion list with zero comment_count by default',
      () async {
        CommunityService.fakeFetchDiscussions = (_) async => [
          _discussionRow(id: 'disc-1'),
          _discussionRow(id: 'disc-2'),
        ];
        CommunityService.fakeFetchCommentCounts = (_) async => [];
        final result = await CommunityService.getDiscussions('111222333');
        expect(result, hasLength(2));
        expect(result[0].commentCount, 0);
        expect(result[1].commentCount, 0);
      },
    );

    test('merges comment counts into discussions', () async {
      CommunityService.fakeFetchDiscussions = (_) async => [
        _discussionRow(id: 'disc-1'),
        _discussionRow(id: 'disc-2'),
      ];
      CommunityService.fakeFetchCommentCounts = (_) async => [
        {'discussion_id': 'disc-1'},
        {'discussion_id': 'disc-1'},
        {'discussion_id': 'disc-2'},
      ];
      final result = await CommunityService.getDiscussions('111222333');
      expect(result.firstWhere((d) => d.id == 'disc-1').commentCount, 2);
      expect(result.firstWhere((d) => d.id == 'disc-2').commentCount, 1);
    });

    test('passes discussion ids to comment-count query', () async {
      CommunityService.fakeFetchDiscussions = (_) async => [
        _discussionRow(id: 'disc-a'),
        _discussionRow(id: 'disc-b'),
      ];
      List<String>? capturedIds;
      CommunityService.fakeFetchCommentCounts = (ids) async {
        capturedIds = ids;
        return [];
      };
      await CommunityService.getDiscussions('111222333');
      expect(capturedIds, containsAll(['disc-a', 'disc-b']));
    });

    test('skips comment-count query when no discussions', () async {
      CommunityService.fakeFetchDiscussions = (_) async => [];
      var countQueryCalled = false;
      CommunityService.fakeFetchCommentCounts = (_) async {
        countQueryCalled = true;
        return [];
      };
      await CommunityService.getDiscussions('111222333');
      expect(countQueryCalled, isFalse);
    });

    test('returns empty list on exception', () async {
      CommunityService.fakeFetchDiscussions = (_) async =>
          throw Exception('DB error');
      expect(await CommunityService.getDiscussions('111222333'), isEmpty);
    });
  });

  // ── startDiscussion ───────────────────────────────────────────────────────

  group('CommunityService.startDiscussion', () {
    setUp(() => CommunityService.enableForTesting(uid: 'uid-me'));

    test('returns Discussion on success', () async {
      CommunityService.fakeInsertDiscussion = (_) async =>
          _discussionRow(id: 'disc-new', barcode: '111222333');
      final result = await CommunityService.startDiscussion(
        barcode: '111222333',
      );
      expect(result, isNotNull);
      expect(result!.id, 'disc-new');
      expect(result.barcode, '111222333');
    });

    test('payload includes created_by uid', () async {
      Map<String, dynamic>? captured;
      CommunityService.fakeInsertDiscussion = (p) async {
        captured = p;
        return _discussionRow();
      };
      await CommunityService.startDiscussion(barcode: '111222333');
      expect(captured!['created_by'], 'uid-me');
    });

    test('title included when non-empty', () async {
      Map<String, dynamic>? captured;
      CommunityService.fakeInsertDiscussion = (p) async {
        captured = p;
        return _discussionRow(title: 'Is this halal?');
      };
      await CommunityService.startDiscussion(
        barcode: '111222333',
        title: 'Is this halal?',
      );
      expect(captured!['title'], 'Is this halal?');
    });

    test('empty title omitted from payload', () async {
      Map<String, dynamic>? captured;
      CommunityService.fakeInsertDiscussion = (p) async {
        captured = p;
        return _discussionRow();
      };
      await CommunityService.startDiscussion(barcode: '111222333', title: '');
      expect(captured!.containsKey('title'), isFalse);
    });

    test('challengeId included when provided', () async {
      Map<String, dynamic>? captured;
      CommunityService.fakeInsertDiscussion = (p) async {
        captured = p;
        return _discussionRow(challengeId: 'ch-1');
      };
      await CommunityService.startDiscussion(
        barcode: '111222333',
        challengeId: 'ch-1',
      );
      expect(captured!['challenge_id'], 'ch-1');
    });

    test('returns null on exception', () async {
      CommunityService.fakeInsertDiscussion = (_) async =>
          throw Exception('DB error');
      expect(
        await CommunityService.startDiscussion(barcode: '111222333'),
        isNull,
      );
    });
  });

  // ── getComments ───────────────────────────────────────────────────────────

  group('CommunityService.getComments', () {
    setUp(() => CommunityService.enableForTesting(uid: 'uid-me'));

    test('maps rows to Comment list', () async {
      CommunityService.fakeFetchComments = (_) async => [
        _commentRow(id: 'cmt-1', body: 'Hello'),
        _commentRow(id: 'cmt-2', body: 'World'),
      ];
      CommunityService.fakeFetchVotes = (_) async => [];
      final result = await CommunityService.getComments('disc-1');
      expect(result, hasLength(2));
      expect(result[0].body, 'Hello');
      expect(result[1].body, 'World');
    });

    test('merges vote scores into comments', () async {
      CommunityService.fakeFetchComments = (_) async => [
        _commentRow(id: 'cmt-1'),
      ];
      CommunityService.fakeFetchVotes = (_) async => [
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-a'},
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-b'},
      ];
      final result = await CommunityService.getComments('disc-1');
      expect(result.first.voteScore, 2);
    });

    test('records current user vote in myVote', () async {
      CommunityService.fakeFetchComments = (_) async => [
        _commentRow(id: 'cmt-1'),
      ];
      CommunityService.fakeFetchVotes = (_) async => [
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-me'},
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-other'},
      ];
      final result = await CommunityService.getComments('disc-1');
      expect(result.first.myVote, 1);
    });

    test('myVote is null when current user has not voted', () async {
      CommunityService.fakeFetchComments = (_) async => [
        _commentRow(id: 'cmt-1'),
      ];
      CommunityService.fakeFetchVotes = (_) async => [
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-other'},
      ];
      final result = await CommunityService.getComments('disc-1');
      expect(result.first.myVote, isNull);
    });

    test('skips vote query when no comments', () async {
      CommunityService.fakeFetchComments = (_) async => [];
      var voteQueryCalled = false;
      CommunityService.fakeFetchVotes = (_) async {
        voteQueryCalled = true;
        return [];
      };
      await CommunityService.getComments('disc-1');
      expect(voteQueryCalled, isFalse);
    });

    test('returns empty list on exception', () async {
      CommunityService.fakeFetchComments = (_) async =>
          throw Exception('DB error');
      expect(await CommunityService.getComments('disc-1'), isEmpty);
    });
  });

  // ── postComment ───────────────────────────────────────────────────────────

  group('CommunityService.postComment', () {
    setUp(() => CommunityService.enableForTesting(uid: 'uid-me'));

    test('returns Comment with vote_score 0 and myVote null', () async {
      CommunityService.fakeInsertComment = (_) async =>
          _commentRow(id: 'cmt-new', body: 'My comment');
      final result = await CommunityService.postComment(
        discussionId: 'disc-1',
        body: 'My comment',
      );
      expect(result, isNotNull);
      expect(result!.body, 'My comment');
      expect(result.voteScore, 0);
      expect(result.myVote, isNull);
    });

    test('payload includes discussionId, body, and uid', () async {
      Map<String, dynamic>? captured;
      CommunityService.fakeInsertComment = (p) async {
        captured = p;
        return _commentRow();
      };
      await CommunityService.postComment(discussionId: 'disc-1', body: 'Hello');
      expect(captured!['discussion_id'], 'disc-1');
      expect(captured!['body'], 'Hello');
      expect(captured!['created_by'], 'uid-me');
    });

    test('parentId included when provided', () async {
      Map<String, dynamic>? captured;
      CommunityService.fakeInsertComment = (p) async {
        captured = p;
        return _commentRow(parentId: 'cmt-parent');
      };
      await CommunityService.postComment(
        discussionId: 'disc-1',
        body: 'Reply',
        parentId: 'cmt-parent',
      );
      expect(captured!['parent_id'], 'cmt-parent');
    });

    test('parentId omitted from payload when null', () async {
      Map<String, dynamic>? captured;
      CommunityService.fakeInsertComment = (p) async {
        captured = p;
        return _commentRow();
      };
      await CommunityService.postComment(discussionId: 'disc-1', body: 'Top');
      expect(captured!.containsKey('parent_id'), isFalse);
    });

    test('returns null on exception', () async {
      CommunityService.fakeInsertComment = (_) async =>
          throw Exception('DB error');
      expect(
        await CommunityService.postComment(discussionId: 'disc-1', body: 'Hi'),
        isNull,
      );
    });
  });

  // ── softDeleteComment ─────────────────────────────────────────────────────

  group('CommunityService.softDeleteComment', () {
    setUp(() => CommunityService.enableForTesting(uid: 'uid-me'));

    test('returns true on success', () async {
      CommunityService.fakeSoftDelete = (_, _) async => true;
      expect(await CommunityService.softDeleteComment('cmt-1'), isTrue);
    });

    test('passes commentId and uid to the operation', () async {
      String? capturedId;
      String? capturedUid;
      CommunityService.fakeSoftDelete = (id, uid) async {
        capturedId = id;
        capturedUid = uid;
        return true;
      };
      await CommunityService.softDeleteComment('cmt-42');
      expect(capturedId, 'cmt-42');
      expect(capturedUid, 'uid-me');
    });

    test('returns false on exception', () async {
      CommunityService.fakeSoftDelete = (_, _) async =>
          throw Exception('DB error');
      expect(await CommunityService.softDeleteComment('cmt-1'), isFalse);
    });
  });

  // ── vote ──────────────────────────────────────────────────────────────────

  group('CommunityService.vote', () {
    setUp(() => CommunityService.enableForTesting(uid: 'uid-me'));

    test('upvote when not previously voted → upserts and returns +1', () async {
      Map<String, dynamic>? captured;
      CommunityService.fakeUpsertVote = (p) async => captured = p;
      final result = await CommunityService.vote(commentId: 'cmt-1', value: 1);
      expect(result, 1);
      expect(captured!['value'], 1);
      expect(captured!['comment_id'], 'cmt-1');
      expect(captured!['user_id'], 'uid-me');
    });

    test(
      'downvote when not previously voted → upserts and returns -1',
      () async {
        CommunityService.fakeUpsertVote = (_) async {};
        final result = await CommunityService.vote(
          commentId: 'cmt-1',
          value: -1,
        );
        expect(result, -1);
      },
    );

    test('same value as currentMyVote → retracts and returns 0', () async {
      String? capturedId;
      CommunityService.fakeDeleteVote = (id, _) async => capturedId = id;
      final result = await CommunityService.vote(
        commentId: 'cmt-1',
        value: 1,
        currentMyVote: 1,
      );
      expect(result, 0);
      expect(capturedId, 'cmt-1');
    });

    test('retract passes correct uid to delete', () async {
      String? capturedUid;
      CommunityService.fakeDeleteVote = (_, uid) async => capturedUid = uid;
      await CommunityService.vote(
        commentId: 'cmt-1',
        value: -1,
        currentMyVote: -1,
      );
      expect(capturedUid, 'uid-me');
    });

    test(
      'different value from currentMyVote → upserts (not retract)',
      () async {
        var deleteWasCalled = false;
        var upsertWasCalled = false;
        CommunityService.fakeDeleteVote = (_, _) async =>
            deleteWasCalled = true;
        CommunityService.fakeUpsertVote = (_) async => upsertWasCalled = true;
        await CommunityService.vote(
          commentId: 'cmt-1',
          value: -1,
          currentMyVote: 1,
        );
        expect(deleteWasCalled, isFalse);
        expect(upsertWasCalled, isTrue);
      },
    );

    test('returns null on exception', () async {
      CommunityService.fakeUpsertVote = (_) async =>
          throw Exception('DB error');
      expect(await CommunityService.vote(commentId: 'cmt-1', value: 1), isNull);
    });

    test('retract exception returns null', () async {
      CommunityService.fakeDeleteVote = (_, _) async =>
          throw Exception('DB error');
      expect(
        await CommunityService.vote(
          commentId: 'cmt-1',
          value: 1,
          currentMyVote: 1,
        ),
        isNull,
      );
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
      final (:scores, :myVotes) = CommunityService.aggregateVotes([
        {'comment_id': 'cmt-1', 'value': 1, 'user_id': 'uid-me'},
        {'comment_id': 'cmt-1', 'value': -1, 'user_id': 'uid-me'},
      ], 'uid-me');
      expect(myVotes['cmt-1'], -1);
      expect(scores['cmt-1'], 0);
    });
  });
}
