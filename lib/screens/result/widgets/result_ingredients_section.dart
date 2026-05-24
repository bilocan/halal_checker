import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../../../models/review_status.dart';
import '../../../widgets/ingredient_source_badge.dart';
import 'result_flagged_ingredient_lists.dart';
import 'result_ingredient_tile.dart';
import 'result_missing_ingredients.dart';

class ResultIngredientsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ingredients = product.ingredients;

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
                onPressed: onToggleTranslation,
                icon: Icon(
                  showTranslated ? Icons.language : Icons.translate,
                  size: 16,
                ),
                label: Text(
                  showTranslated
                      ? loc.showOriginal
                      : languageCode.toUpperCase(),
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
                onPressed: onCopyIngredients,
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
            aiRequestStatus: aiRequestStatus,
            isFetchingAiIngredients: isFetchingAiIngredients,
            onRequestAiIngredients: onRequestAiIngredients,
            onContributed: onRefreshProduct,
          ),
        ] else ...[
          ...ingredients.map(
            (ingredient) => ResultIngredientTile(
              product: product,
              ingredient: ingredient,
              showTranslated: showTranslated,
              languageCode: languageCode,
              loc: loc,
              isReported:
                  adminReportedIngredients?.contains(ingredient) ?? false,
              reportExplanation: adminReportExplanation,
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
              onPressed: onReportIngredient,
              icon: const Icon(Icons.report_outlined, size: 16),
              label: Text(
                loc.reportWrongIngredient,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
        ResultFlaggedIngredientLists(
          product: product,
          showTranslated: showTranslated,
          languageCode: languageCode,
          loc: loc,
        ),
      ],
    );
  }
}
