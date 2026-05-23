part of '../discussion_screen.dart';

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
