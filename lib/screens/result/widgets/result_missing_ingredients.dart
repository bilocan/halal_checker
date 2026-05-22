import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../../../models/review_status.dart';
import '../../../widgets/contribute_ingredients_sheet.dart';

class ResultMissingIngredients extends StatelessWidget {
  const ResultMissingIngredients({
    super.key,
    required this.product,
    required this.loc,
    required this.aiRequestStatus,
    required this.isFetchingAiIngredients,
    required this.onRequestAiIngredients,
    required this.onContributed,
  });

  final Product product;
  final AppLocalizations loc;
  final ReviewStatus? aiRequestStatus;
  final bool isFetchingAiIngredients;
  final VoidCallback onRequestAiIngredients;
  final VoidCallback onContributed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: const Color(0xFFF5F3FF),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      aiRequestStatus == ReviewStatus.pending
                          ? Icons.hourglass_top
                          : aiRequestStatus == ReviewStatus.rejected
                          ? Icons.block
                          : Icons.auto_awesome,
                      color: aiRequestStatus == ReviewStatus.rejected
                          ? Colors.red.shade400
                          : const Color(0xFF7C3AED),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Find ingredients via AI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B21B6),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  aiRequestStatus == ReviewStatus.pending
                      ? 'AI lookup requested — an admin will review and approve it shortly.'
                      : aiRequestStatus == ReviewStatus.rejected
                      ? 'The AI request was rejected by an admin.'
                      : 'Ask AI to search the web for this product\'s ingredient list.',
                  style: TextStyle(
                    color: aiRequestStatus == ReviewStatus.rejected
                        ? Colors.red.shade700
                        : const Color(0xFF6D28D9),
                    fontSize: 13,
                  ),
                ),
                if (aiRequestStatus == null ||
                    aiRequestStatus == ReviewStatus.rejected) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: isFetchingAiIngredients
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        aiRequestStatus == ReviewStatus.rejected
                            ? 'Request again'
                            : 'Request via AI',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isFetchingAiIngredients
                          ? null
                          : onRequestAiIngredients,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.contributeIngredients,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loc.contributeIngredientsHint,
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(loc.contributeIngredients),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => showContributeIngredientsSheet(
                      context,
                      product,
                      loc,
                      onContributed: onContributed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.open_in_new, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.improveOnOpenFoodFacts,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loc.improveOnOpenFoodFactsHint,
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(loc.improveOnOpenFoodFacts),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://world.openfoodfacts.org/cgi/product.pl'
                        '?type=edit&code=${product.barcode}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
