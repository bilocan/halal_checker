import 'package:flutter/material.dart';

import '../../../app_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../../../services/keyword_match_display.dart';
import '../../../services/product_service.dart';
import '../../keywords_screen.dart';
import '../result_status.dart';

class ResultTransparencyCard extends StatelessWidget {
  const ResultTransparencyCard({
    super.key,
    required this.product,
    required this.loc,
  });

  final Product product;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final status = ResultStatus.from(product, loc);
    final checkedText = product.ingredients.isEmpty
        ? loc.transparentNoIngredients
        : '${product.ingredients.length} ${loc.ingredients.toLowerCase()}';
    final flaggedText = product.haramIngredients.isEmpty
        ? loc.transparentNoMatches
        : product.haramIngredients.join(', ');
    final suspiciousText = product.suspiciousIngredients.isEmpty
        ? loc.transparentNoMatches
        : product.suspiciousIngredients.join(', ');

    final matchSourceText = KeywordMatchDisplay.combinedSourcesLabel(
      loc,
      product.keywordMatchSource,
    );
    final matchOriginsText = KeywordMatchDisplay.originSummary(
      loc,
      product.keywordMatchOrigins,
    );
    final displayLangText = product.displayLang?.isNotEmpty == true
        ? product.displayLang!.toUpperCase()
        : loc.transparentNoMatches;

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(
          loc.analysisTransparency,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        leading: const Icon(Icons.visibility_outlined),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.transparentSummary,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  icon: Icons.fact_check_outlined,
                  label: loc.transparentResult,
                  value: status.resultLabel,
                  color: product.isHalal ? kGreen : Colors.red.shade600,
                ),
                _SummaryRow(
                  icon: Icons.format_list_bulleted,
                  label: loc.transparentIngredientsChecked,
                  value: checkedText,
                  color: Colors.blueGrey.shade600,
                ),
                _SummaryRow(
                  icon: Icons.rule,
                  label: loc.transparentRulesChecked,
                  value: product.ingredients.isEmpty
                      ? loc.transparentRulesAvailable(
                          ProductService.keywordRuleCount,
                        )
                      : ProductService.keywordRuleCount.toString(),
                  color: Colors.blueGrey.shade600,
                ),
                _SummaryRow(
                  icon: Icons.translate,
                  label: loc.transparentDisplayLanguage,
                  value: displayLangText,
                  color: Colors.blueGrey.shade600,
                ),
                _SummaryRow(
                  icon: Icons.compare_arrows,
                  label: loc.transparentMatchSource,
                  value: matchSourceText,
                  color: Colors.blueGrey.shade700,
                ),
                if (product.keywordMatchOrigins.isNotEmpty)
                  _SummaryRow(
                    icon: Icons.link,
                    label: loc.transparentMatchOrigins,
                    value: matchOriginsText,
                    color: Colors.blueGrey.shade700,
                  ),
                _SummaryRow(
                  icon: Icons.error_outline,
                  label: loc.transparentFlagged,
                  value: flaggedText,
                  color: Colors.red.shade600,
                ),
                _SummaryRow(
                  icon: Icons.warning_amber,
                  label: loc.transparentSuspicious,
                  value: suspiciousText,
                  color: Colors.orange.shade700,
                ),
                _SummaryRow(
                  icon: Icons.notes_outlined,
                  label: loc.transparentExplanation,
                  value: status.explanation,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KeywordsScreen()),
              ),
              icon: const Icon(Icons.list_alt_outlined),
              label: Text(loc.viewAllCheckedKeywords),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.transparencyNote,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade900,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
