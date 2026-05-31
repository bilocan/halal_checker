import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/product_analysis.dart';

class ResultCommunitySection extends StatelessWidget {
  const ResultCommunitySection({
    super.key,
    required this.loc,
    required this.analysis,
    required this.isRequestingAnalysis,
    required this.discussionCount,
    required this.onRequestAnalysis,
    required this.onOpenAnalysis,
    required this.onOpenDiscussion,
  });

  final AppLocalizations loc;
  final ProductAnalysis? analysis;
  final bool isRequestingAnalysis;
  final int discussionCount;
  final VoidCallback onRequestAnalysis;
  final VoidCallback onOpenAnalysis;
  final VoidCallback onOpenDiscussion;

  @override
  Widget build(BuildContext context) {
    final analysisStatusColor = switch (analysis?.status) {
      AnalysisStatus.resolved => Colors.green.shade700,
      AnalysisStatus.aiDone ||
      AnalysisStatus.communityReview ||
      AnalysisStatus.consulting => Colors.blue.shade700,
      AnalysisStatus.aiAnalyzing => Colors.orange.shade700,
      _ => Colors.purple.shade700,
    };

    final canOpenAnalysis =
        analysis != null &&
        analysis!.status != AnalysisStatus.pending &&
        analysis!.status != AnalysisStatus.aiAnalyzing;

    return Card(
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: canOpenAnalysis ? onOpenAnalysis : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.biotech, color: analysisStatusColor, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.deepAnalysis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: analysisStatusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          analysis == null
                              ? loc.perIngredientAiAnalysis
                              : analysis!.status.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isRequestingAnalysis)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (analysis == null ||
                      analysis!.status == AnalysisStatus.pending)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: onRequestAnalysis,
                      child: Text(
                        loc.analyse,
                        style: const TextStyle(fontSize: 13),
                      ),
                    )
                  else if (analysis!.status == AnalysisStatus.aiAnalyzing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey.shade200,
          ),
          InkWell(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            onTap: onOpenDiscussion,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.forum_outlined,
                    color: Colors.blue.shade700,
                    size: 26,
                  ),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
