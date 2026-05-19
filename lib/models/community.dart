class IngredientChallenge {
  final String id;
  final String barcode;
  final String ingredient;
  final String currentVerdict;
  final String claimedVerdict;
  final String reason;
  final String status; // 'open' | 'resolved' | 'dismissed'
  final String createdBy;
  final String? createdByUsername;
  final String? resolutionNote;
  final DateTime createdAt;

  const IngredientChallenge({
    required this.id,
    required this.barcode,
    required this.ingredient,
    required this.currentVerdict,
    required this.claimedVerdict,
    required this.reason,
    required this.status,
    required this.createdBy,
    this.createdByUsername,
    this.resolutionNote,
    required this.createdAt,
  });

  factory IngredientChallenge.fromJson(Map<String, dynamic> j) =>
      IngredientChallenge(
        id: j['id'] as String,
        barcode: j['barcode'] as String,
        ingredient: j['ingredient'] as String,
        currentVerdict: j['current_verdict'] as String,
        claimedVerdict: j['claimed_verdict'] as String,
        reason: j['reason'] as String,
        status: j['status'] as String? ?? 'open',
        createdBy: j['created_by'] as String,
        createdByUsername:
            (j['profiles'] as Map<String, dynamic>?)?['username'] as String?,
        resolutionNote: j['resolution_note'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class Discussion {
  final String id;
  final String barcode;
  final String? challengeId;
  final String? title;
  final bool isLocked;
  final String createdBy;
  final String? createdByUsername;
  final DateTime createdAt;
  final int commentCount;

  const Discussion({
    required this.id,
    required this.barcode,
    this.challengeId,
    this.title,
    required this.isLocked,
    required this.createdBy,
    this.createdByUsername,
    required this.createdAt,
    this.commentCount = 0,
  });

  factory Discussion.fromJson(Map<String, dynamic> j) => Discussion(
    id: j['id'] as String,
    barcode: j['barcode'] as String,
    challengeId: j['challenge_id'] as String?,
    title: j['title'] as String?,
    isLocked: j['is_locked'] as bool? ?? false,
    createdBy: j['created_by'] as String,
    createdByUsername:
        (j['profiles'] as Map<String, dynamic>?)?['username'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    commentCount: j['comment_count'] as int? ?? 0,
  );
}

class Comment {
  final String id;
  final String discussionId;
  final String? parentId;
  final String body;
  final bool isDeleted;
  final String createdBy;
  final String? createdByUsername;
  final String? createdByAvatarUrl;
  final DateTime createdAt;
  final int voteScore;
  final int? myVote; // 1, -1, or null

  const Comment({
    required this.id,
    required this.discussionId,
    this.parentId,
    required this.body,
    required this.isDeleted,
    required this.createdBy,
    this.createdByUsername,
    this.createdByAvatarUrl,
    required this.createdAt,
    this.voteScore = 0,
    this.myVote,
  });

  factory Comment.fromJson(Map<String, dynamic> j) {
    final profiles = _readProfiles(j['profiles']);
    return Comment(
      id: j['id'] as String,
      discussionId: j['discussion_id'] as String,
      parentId: j['parent_id'] as String?,
      body: j['body'] as String? ?? '',
      isDeleted: j['is_deleted'] as bool? ?? false,
      createdBy: j['created_by'] as String,
      createdByUsername: profiles?['username'] as String?,
      createdByAvatarUrl: profiles?['avatar_url'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
      voteScore: (j['vote_score'] as num?)?.toInt() ?? 0,
      myVote: (j['my_vote'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic>? _readProfiles(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  Comment copyWith({int? voteScore, int? myVote, bool clearMyVote = false}) =>
      Comment(
        id: id,
        discussionId: discussionId,
        parentId: parentId,
        body: body,
        isDeleted: isDeleted,
        createdBy: createdBy,
        createdByUsername: createdByUsername,
        createdByAvatarUrl: createdByAvatarUrl,
        createdAt: createdAt,
        voteScore: voteScore ?? this.voteScore,
        myVote: clearMyVote ? null : (myVote ?? this.myVote),
      );
}
