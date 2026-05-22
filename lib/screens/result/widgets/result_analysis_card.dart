import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/product_analysis.dart';

class ResultAnalysisCard extends StatelessWidget {
  const ResultAnalysisCard({
    super.key,
    required this.loc,
    required this.analysis,
    required this.isRequesting,
    required this.onRequest,
    required this.onOpenAnalysis,
  });

  final AppLocalizations loc;
  final ProductAnalysis? analysis;
  final bool isRequesting;
  final VoidCallback onRequest;
  final VoidCallback onOpenAnalysis;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (analysis?.status) {
      AnalysisStatus.resolved => Colors.green.shade700,
      AnalysisStatus.aiDone ||
      AnalysisStatus.communityReview ||
      AnalysisStatus.consulting => Colors.blue.shade700,
      AnalysisStatus.aiAnalyzing => Colors.orange.shade700,
      _ => Colors.purple.shade700,
    };

    final canOpen =
        analysis != null &&
        analysis!.status != AnalysisStatus.pending &&
        analysis!.status != AnalysisStatus.aiAnalyzing;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canOpen ? onOpenAnalysis : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.biotech, color: statusColor, size: 28),
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
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      analysis == null
                          ? loc.perIngredientAiAnalysis
                          : analysis!.status.label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isRequesting)
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
                  onPressed: onRequest,
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
    );
  }
}
