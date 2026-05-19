import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../models/community.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';

class DiscussionScreen extends StatefulWidget {
  final String barcode;
  final String productName;

  const DiscussionScreen({
    super.key,
    required this.barcode,
    required this.productName,
  });

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  List<Discussion> _discussions = [];
  List<IngredientChallenge> _challenges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      CommunityService.getDiscussions(widget.barcode),
      CommunityService.getChallenges(widget.barcode),
    ]);
    if (!mounted) return;
    setState(() {
      _discussions = results[0] as List<Discussion>;
      _challenges = results[1] as List<IngredientChallenge>;
      _loading = false;
    });
  }

  void _startDiscussion() {
    if (AuthService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signInToDiscuss)),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StartDiscussionSheet(barcode: widget.barcode),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.productName, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: AppLocalizations.of(context).discussions),
              Tab(text: AppLocalizations.of(context).challenges),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _startDiscussion,
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context).newDiscussion),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _DiscussionsTab(
                    discussions: _discussions,
                    barcode: widget.barcode,
                    productName: widget.productName,
                    onRefresh: _load,
                  ),
                  _ChallengesTab(challenges: _challenges),
                ],
              ),
      ),
    );
  }
}

// ── Discussions tab ───────────────────────────────────────────────────────────

class _DiscussionsTab extends StatelessWidget {
  final List<Discussion> discussions;
  final String barcode;
  final String productName;
  final VoidCallback onRefresh;

  const _DiscussionsTab({
    required this.discussions,
    required this.barcode,
    required this.productName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (discussions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).noDiscussionsYet,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).noDiscussionsHint,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: discussions.length,
        itemBuilder: (_, i) {
          final d = discussions[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _CommentsScreen(discussion: d),
                ),
              ).then((_) => onRefresh()),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (d.title != null && d.title!.isNotEmpty)
                      Text(
                        d.title!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    if (d.challengeId != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Linked to challenge',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          d.createdByUsername ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.comment_outlined,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${d.commentCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (d.isLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock,
                              size: 13,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Locked',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Challenges tab ────────────────────────────────────────────────────────────

class _ChallengesTab extends StatelessWidget {
  final List<IngredientChallenge> challenges;

  const _ChallengesTab({required this.challenges});

  Color _statusColor(String status) => switch (status) {
    'resolved' => kGreen,
    'dismissed' => Colors.grey.shade500,
    _ => Colors.orange.shade700,
  };

  Color _verdictColor(String verdict) => switch (verdict) {
    'halal' => kGreen,
    'haram' => Colors.red.shade700,
    _ => kAmber,
  };

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No ingredient challenges yet.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap an ingredient in Deep Analysis to challenge its verdict.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: challenges.length,
      itemBuilder: (_, i) {
        final c = challenges[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.ingredient,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(c.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(c.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _verdictChip(c.currentVerdict, label: 'was'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 14),
                    ),
                    _verdictChip(c.claimedVerdict, label: 'should be'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c.reason, style: const TextStyle(fontSize: 13)),
                if (c.resolutionNote != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kGreenSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.resolutionNote!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'by ${c.createdByUsername ?? 'Anonymous'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _verdictChip(String verdict, {required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _verdictColor(verdict).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $verdict',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _verdictColor(verdict),
        ),
      ),
    );
  }
}

// ── Comments screen ───────────────────────────────────────────────────────────

class _CommentsScreen extends StatefulWidget {
  final Discussion discussion;

  const _CommentsScreen({required this.discussion});

  @override
  State<_CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<_CommentsScreen> {
  List<Comment> _comments = [];
  bool _loading = true;
  final _bodyController = TextEditingController();
  bool _posting = false;
  String? _replyToId;
  String? _replyToUsername;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final comments = await CommunityService.getComments(widget.discussion.id);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _postComment() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _posting) return;

    if (!await AuthService.ensureInitialized() ||
        AuthService.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to comment.')),
      );
      return;
    }

    setState(() => _posting = true);
    final countBefore = _comments.length;
    final result = await CommunityService.postCommentResult(
      discussionId: widget.discussion.id,
      body: body,
      parentId: _replyToId,
    );
    if (!mounted) return;

    if (result.comment != null) {
      setState(() {
        _posting = false;
        _comments.add(result.comment!);
        _clearCommentInput();
      });
      return;
    }

    // Insert may have succeeded even when the returned row could not be parsed.
    await _loadComments();
    if (!mounted) return;

    final posted = _comments.length > countBefore;
    setState(() {
      _posting = false;
      if (posted) _clearCommentInput();
    });

    if (!mounted) return;
    if (!posted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.error ?? "Couldn't post your comment. Please try again.",
          ),
        ),
      );
    }
  }

  void _clearCommentInput() {
    _bodyController.clear();
    _replyToId = null;
    _replyToUsername = null;
  }

  Future<void> _vote(Comment comment, int value) async {
    final newVote = await CommunityService.vote(
      commentId: comment.id,
      value: value,
      currentMyVote: comment.myVote,
    );
    if (!mounted || newVote == null) return;
    setState(() {
      final idx = _comments.indexWhere((c) => c.id == comment.id);
      if (idx == -1) return;
      final delta = (newVote) - (comment.myVote ?? 0);
      _comments[idx] = comment.copyWith(
        voteScore: comment.voteScore + delta,
        myVote: newVote == 0 ? null : newVote,
        clearMyVote: newVote == 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.discussion.title;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title != null && title.isNotEmpty ? title : 'Discussion',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet. Be the first!',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadComments,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => _CommentTile(
                        comment: _comments[i],
                        onReply: (id, username) => setState(() {
                          _replyToId = id;
                          _replyToUsername = username;
                        }),
                        onVote: (value) => _vote(_comments[i], value),
                      ),
                    ),
                  ),
          ),
          if (!widget.discussion.isLocked) _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyToUsername != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    'Replying to $_replyToUsername',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => setState(() {
                      _replyToId = null;
                      _replyToUsername = null;
                    }),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment…',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_posting && _bodyController.text.trim().isNotEmpty) {
                      _postComment();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: _bodyController,
                builder: (context, _) {
                  final canSend =
                      !_posting && _bodyController.text.trim().isNotEmpty;
                  return IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: canSend ? _postComment : null,
                    icon: _posting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Comment tile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final void Function(String id, String? username) onReply;
  final void Function(int value) onVote;

  const _CommentTile({
    required this.comment,
    required this.onReply,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final isReply = comment.parentId != null;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 24 : 0, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.createdByAvatarUrl != null
                ? CachedNetworkImageProvider(comment.createdByAvatarUrl!)
                : null,
            backgroundColor: Colors.blue.shade100,
            child: comment.createdByAvatarUrl == null
                ? Text(
                    (comment.createdByUsername ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.createdByUsername ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatAge(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                comment.isDeleted
                    ? Text(
                        '[deleted]',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(comment.body, style: const TextStyle(fontSize: 14)),
                if (!comment.isDeleted) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _voteButton(
                        icon: Icons.thumb_up_outlined,
                        activeIcon: Icons.thumb_up,
                        active: comment.myVote == 1,
                        onTap: () => onVote(1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.voteScore}',
                        style: TextStyle(
                          fontSize: 12,
                          color: comment.voteScore > 0
                              ? kGreen
                              : comment.voteScore < 0
                              ? Colors.red.shade700
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _voteButton(
                        icon: Icons.thumb_down_outlined,
                        activeIcon: Icons.thumb_down,
                        active: comment.myVote == -1,
                        onTap: () => onVote(-1),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () =>
                            onReply(comment.id, comment.createdByUsername),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _voteButton({
    required IconData icon,
    required IconData activeIcon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        active ? activeIcon : icon,
        size: 16,
        color: active ? Colors.blue.shade700 : Colors.grey.shade400,
      ),
    );
  }

  String _formatAge(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Start discussion sheet ────────────────────────────────────────────────────

class _StartDiscussionSheet extends StatefulWidget {
  final String barcode;

  const _StartDiscussionSheet({required this.barcode});

  @override
  State<_StartDiscussionSheet> createState() => _StartDiscussionSheetState();
}

class _StartDiscussionSheetState extends State<_StartDiscussionSheet> {
  final _titleController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final discussion = await CommunityService.startDiscussion(
      barcode: widget.barcode,
      title: _titleController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (discussion != null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _CommentsScreen(discussion: discussion),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start discussion. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start a Discussion',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Topic (optional)',
              hintText: 'e.g. Is the gelatin source specified?',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Start Discussion'),
            ),
          ),
        ],
      ),
    );
  }
}
