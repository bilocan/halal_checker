import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/community.dart';

const _ts = '2026-01-01T00:00:00.000Z';

void main() {
  // ── IngredientChallenge ────────────────────────────────────────────────────

  group('IngredientChallenge.fromJson', () {
    Map<String, dynamic> base() => {
      'id': 'ch-1',
      'barcode': '111222333',
      'ingredient': 'gelatin',
      'current_verdict': 'suspicious',
      'claimed_verdict': 'haram',
      'reason': 'Gelatin at this producer is pork-derived',
      'status': 'open',
      'created_by': 'user-uuid',
      'resolution_note': null,
      'created_at': _ts,
    };

    test('parses all fields', () {
      final c = IngredientChallenge.fromJson({
        ...base(),
        'profiles': {'username': 'testuser'},
      });

      expect(c.id, 'ch-1');
      expect(c.barcode, '111222333');
      expect(c.ingredient, 'gelatin');
      expect(c.currentVerdict, 'suspicious');
      expect(c.claimedVerdict, 'haram');
      expect(c.reason, 'Gelatin at this producer is pork-derived');
      expect(c.status, 'open');
      expect(c.createdBy, 'user-uuid');
      expect(c.createdByUsername, 'testuser');
      expect(c.resolutionNote, isNull);
      expect(c.createdAt, DateTime.parse(_ts));
    });

    test('handles missing profiles key', () {
      final c = IngredientChallenge.fromJson(base());
      expect(c.createdByUsername, isNull);
    });

    test('parses resolution_note when present', () {
      final c = IngredientChallenge.fromJson({
        ...base(),
        'resolution_note': 'Confirmed haram — producer confirmed pork source.',
      });
      expect(
        c.resolutionNote,
        'Confirmed haram — producer confirmed pork source.',
      );
    });

    test('accepts each status value', () {
      for (final s in ['open', 'resolved', 'dismissed']) {
        final c = IngredientChallenge.fromJson({...base(), 'status': s});
        expect(c.status, s);
      }
    });

    test('accepts each verdict value', () {
      for (final v in ['halal', 'haram', 'suspicious', 'unknown']) {
        final c = IngredientChallenge.fromJson({
          ...base(),
          'current_verdict': v,
        });
        expect(c.currentVerdict, v);
      }
    });
  });

  // ── Discussion ─────────────────────────────────────────────────────────────

  group('Discussion.fromJson', () {
    Map<String, dynamic> base() => {
      'id': 'disc-1',
      'barcode': '111222333',
      'challenge_id': null,
      'title': 'Is the gelatin bovine or porcine?',
      'is_locked': false,
      'created_by': 'user-uuid',
      'created_at': _ts,
    };

    test('parses all fields', () {
      final d = Discussion.fromJson({
        ...base(),
        'profiles': {'username': 'alice'},
        'comment_count': 7,
      });

      expect(d.id, 'disc-1');
      expect(d.barcode, '111222333');
      expect(d.challengeId, isNull);
      expect(d.title, 'Is the gelatin bovine or porcine?');
      expect(d.isLocked, false);
      expect(d.createdBy, 'user-uuid');
      expect(d.createdByUsername, 'alice');
      expect(d.commentCount, 7);
      expect(d.createdAt, DateTime.parse(_ts));
    });

    test('defaults commentCount to 0 when key is absent', () {
      final d = Discussion.fromJson(base());
      expect(d.commentCount, 0);
    });

    test('parses challenge_id when present', () {
      final d = Discussion.fromJson({...base(), 'challenge_id': 'ch-99'});
      expect(d.challengeId, 'ch-99');
    });

    test('isLocked true is preserved', () {
      final d = Discussion.fromJson({...base(), 'is_locked': true});
      expect(d.isLocked, true);
    });

    test('handles missing profiles key', () {
      final d = Discussion.fromJson(base());
      expect(d.createdByUsername, isNull);
    });

    test('handles null title', () {
      final d = Discussion.fromJson({...base(), 'title': null});
      expect(d.title, isNull);
    });
  });

  // ── Comment ────────────────────────────────────────────────────────────────

  group('Comment.fromJson', () {
    Map<String, dynamic> base() => {
      'id': 'cmt-1',
      'discussion_id': 'disc-1',
      'parent_id': null,
      'body': 'Has anyone confirmed the gelatin source with the producer?',
      'is_deleted': false,
      'created_by': 'user-uuid',
      'created_at': _ts,
    };

    test('parses all fields', () {
      final c = Comment.fromJson({
        ...base(),
        'profiles': {
          'username': 'bob',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
        'vote_score': 5,
        'my_vote': 1,
      });

      expect(c.id, 'cmt-1');
      expect(c.discussionId, 'disc-1');
      expect(c.parentId, isNull);
      expect(
        c.body,
        'Has anyone confirmed the gelatin source with the producer?',
      );
      expect(c.isDeleted, false);
      expect(c.createdBy, 'user-uuid');
      expect(c.createdByUsername, 'bob');
      expect(c.createdByAvatarUrl, 'https://example.com/avatar.jpg');
      expect(c.voteScore, 5);
      expect(c.myVote, 1);
      expect(c.createdAt, DateTime.parse(_ts));
    });

    test('defaults voteScore to 0 and myVote to null when absent', () {
      final c = Comment.fromJson(base());
      expect(c.voteScore, 0);
      expect(c.myVote, isNull);
    });

    test('parses parent_id for reply comments', () {
      final c = Comment.fromJson({...base(), 'parent_id': 'cmt-0'});
      expect(c.parentId, 'cmt-0');
    });

    test('handles deleted comment', () {
      final c = Comment.fromJson({...base(), 'is_deleted': true, 'body': ''});
      expect(c.isDeleted, true);
      expect(c.body, '');
    });

    test('parses negative voteScore', () {
      final c = Comment.fromJson({...base(), 'vote_score': -3, 'my_vote': -1});
      expect(c.voteScore, -3);
      expect(c.myVote, -1);
    });

    test('handles missing profiles key', () {
      final c = Comment.fromJson(base());
      expect(c.createdByUsername, isNull);
      expect(c.createdByAvatarUrl, isNull);
    });
  });

  // ── Comment.copyWith ───────────────────────────────────────────────────────

  group('Comment.copyWith', () {
    Comment base() => Comment(
      id: 'cmt-1',
      discussionId: 'disc-1',
      body: 'Hello',
      isDeleted: false,
      createdBy: 'user-uuid',
      createdAt: DateTime(2026, 1, 1),
      voteScore: 2,
      myVote: 1,
    );

    test('updates voteScore while leaving other fields unchanged', () {
      final c = base().copyWith(voteScore: 10);
      expect(c.voteScore, 10);
      expect(c.myVote, 1);
      expect(c.body, 'Hello');
    });

    test('updates myVote while leaving voteScore unchanged', () {
      final c = base().copyWith(myVote: -1);
      expect(c.myVote, -1);
      expect(c.voteScore, 2);
    });

    test('clearMyVote sets myVote to null regardless of myVote param', () {
      final c = base().copyWith(clearMyVote: true);
      expect(c.myVote, isNull);
    });

    test('clearMyVote takes precedence over myVote param', () {
      final c = base().copyWith(myVote: 1, clearMyVote: true);
      expect(c.myVote, isNull);
    });

    test('copyWith with no args returns equivalent comment', () {
      final original = base();
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.voteScore, original.voteScore);
      expect(copy.myVote, original.myVote);
    });

    test('can update both voteScore and clearMyVote together', () {
      final c = base().copyWith(voteScore: 0, clearMyVote: true);
      expect(c.voteScore, 0);
      expect(c.myVote, isNull);
    });
  });
}
