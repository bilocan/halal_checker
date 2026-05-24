part of '../discussion_screen.dart';

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
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.signInToComment)));
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
            result.error ?? AppLocalizations.of(context).couldNotPostComment,
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
    final loc = AppLocalizations.of(context);
    final title = widget.discussion.title;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title != null && title.isNotEmpty
              ? title
              : loc.discussionFallbackTitle,
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
                      loc.noCommentsYet,
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
    final loc = AppLocalizations.of(context);
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
                    loc.replyingTo(_replyToUsername!),
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
                  decoration: InputDecoration(
                    hintText: loc.writeCommentHint,
                    border: const OutlineInputBorder(),
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
    final loc = AppLocalizations.of(context);
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
                      comment.createdByUsername ?? loc.anonymous,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatRelativeTime(loc, comment.createdAt),
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
                        loc.commentDeleted,
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
                          loc.reply,
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
        SnackBar(
          content: Text(AppLocalizations.of(context).failedStartDiscussion),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
          Text(
            loc.startDiscussionTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: loc.topicOptionalLabel,
              hintText: loc.topicOptionalHint,
              border: const OutlineInputBorder(),
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
                  : Text(loc.startDiscussionButton),
            ),
          ),
        ],
      ),
    );
  }
}
