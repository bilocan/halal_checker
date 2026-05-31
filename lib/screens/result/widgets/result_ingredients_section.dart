import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../../../models/review_status.dart';
import '../../../widgets/ingredient_source_badge.dart';
import 'result_flagged_ingredient_lists.dart';
import 'result_ingredient_tile.dart';
import 'result_missing_ingredients.dart';

class ResultIngredientsSection extends StatefulWidget {
  const ResultIngredientsSection({
    super.key,
    required this.product,
    required this.loc,
    required this.showTranslated,
    required this.languageCode,
    required this.onToggleTranslation,
    required this.onCopyIngredients,
    required this.onReportIngredient,
    required this.adminReportedIngredients,
    required this.adminReportExplanation,
    required this.aiRequestStatus,
    required this.isFetchingAiIngredients,
    required this.onRequestAiIngredients,
    required this.onRefreshProduct,
  });

  final Product product;
  final AppLocalizations loc;
  final bool showTranslated;
  final String languageCode;
  final VoidCallback onToggleTranslation;
  final VoidCallback onCopyIngredients;
  final VoidCallback onReportIngredient;
  final List<String>? adminReportedIngredients;
  final String? adminReportExplanation;
  final ReviewStatus? aiRequestStatus;
  final bool isFetchingAiIngredients;
  final VoidCallback onRequestAiIngredients;
  final VoidCallback onRefreshProduct;

  @override
  State<ResultIngredientsSection> createState() =>
      _ResultIngredientsSectionState();
}

class _ResultIngredientsSectionState extends State<ResultIngredientsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final loc = widget.loc;
    final ingredients = product.ingredients;
    final hasFlagged =
        product.haramIngredients.isNotEmpty ||
        product.suspiciousIngredients.isNotEmpty ||
        product.haramLabels.isNotEmpty ||
        product.suspiciousLabels.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              loc.ingredients,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(width: 8),
            if (product.ingredientSource != null)
              IngredientSourceBadge(source: product.ingredientSource!),
            const Spacer(),
            if (product.ingredientTranslations.isNotEmpty)
              TextButton.icon(
                onPressed: widget.onToggleTranslation,
                icon: Icon(
                  widget.showTranslated ? Icons.language : Icons.translate,
                  size: 16,
                ),
                label: Text(
                  widget.showTranslated
                      ? loc.showOriginal
                      : widget.languageCode.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            if (ingredients.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: widget.onCopyIngredients,
                tooltip: loc.copyIngredientsTooltip,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                color: Colors.grey.shade600,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (ingredients.isEmpty) ...[
          Text(
            loc.noIngredientData,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ResultMissingIngredients(
            product: product,
            loc: loc,
            aiRequestStatus: widget.aiRequestStatus,
            isFetchingAiIngredients: widget.isFetchingAiIngredients,
            onRequestAiIngredients: widget.onRequestAiIngredients,
            onContributed: widget.onRefreshProduct,
          ),
        ] else ...[
          // Flagged summary always visible — anchors the toggle button position
          ResultFlaggedIngredientLists(
            product: product,
            showTranslated: widget.showTranslated,
            languageCode: widget.languageCode,
            loc: loc,
          ),
          if (!hasFlagged) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  loc.transparentNoMatches,
                  style: TextStyle(color: Colors.green.shade700, fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Toggle button stays in the same position in both states
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showAll = !_showAll),
              icon: Icon(
                _showAll ? Icons.expand_less : Icons.expand_more,
                size: 16,
              ),
              label: Text(
                _showAll
                    ? loc.showLessIngredients
                    : loc.showAllIngredients(ingredients.length),
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          // Full list expands BELOW the button
          if (_showAll) ...[
            const SizedBox(height: 8),
            ...ingredients.map(
              (ingredient) => ResultIngredientTile(
                product: product,
                ingredient: ingredient,
                showTranslated: widget.showTranslated,
                languageCode: widget.languageCode,
                loc: loc,
                isReported:
                    widget.adminReportedIngredients?.contains(ingredient) ??
                    false,
                reportExplanation: widget.adminReportExplanation,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: widget.onReportIngredient,
                icon: const Icon(Icons.report_outlined, size: 16),
                label: Text(
                  loc.reportWrongIngredient,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
