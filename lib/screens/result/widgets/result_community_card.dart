import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';

class ResultCommunityCard extends StatelessWidget {
  const ResultCommunityCard({
    super.key,
    required this.loc,
    required this.discussionCount,
    required this.onTap,
  });

  final AppLocalizations loc;
  final int discussionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.communityDiscussion,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      discussionCount == 0
                          ? loc.noDiscussionsYet
                          : '$discussionCount discussion${discussionCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
