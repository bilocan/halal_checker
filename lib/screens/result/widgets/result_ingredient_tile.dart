import 'package:flutter/material.dart';

import '../../../app_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../../../services/product_service.dart';
import '../../../widgets/ingredient_source_badge.dart';
import '../ingredient_display.dart';

class ResultIngredientTile extends StatelessWidget {
  const ResultIngredientTile({
    super.key,
    required this.product,
    required this.ingredient,
    required this.showTranslated,
    required this.languageCode,
    required this.loc,
    this.isReported = false,
    this.reportExplanation,
  });

  final Product product;
  final String ingredient;
  final bool showTranslated;
  final String languageCode;
  final AppLocalizations loc;
  final bool isReported;
  final String? reportExplanation;

  @override
  Widget build(BuildContext context) {
    final sourceStyle = IngredientSourceStyle.of(product.ingredientSource);
    final warning = product.ingredientWarnings[ingredient];
    final isHaramIngredient = product.haramIngredients.contains(ingredient);
    final canonical = product.ingredientCanonicals[ingredient];
    final localizedWarning = localizedIngredientWarning(
      ingredient: ingredient,
      canonical: canonical,
      warning: warning,
      languageCode: languageCode,
    );
    final fattyAlcohol =
        warning == null && ProductService.isFattyAlcohol(ingredient);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isReported ? Colors.orange.shade50 : sourceStyle.fillColor,
        border: Border.all(
          color: isReported ? Colors.orange.shade400 : sourceStyle.borderColor,
          width: isReported ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            tileColor: Colors.transparent,
            leading: Icon(
              warning != null
                  ? (isHaramIngredient
                        ? Icons.warning
                        : Icons.warning_amber_outlined)
                  : fattyAlcohol
                  ? Icons.info_outline
                  : Icons.check_circle_outline,
              color: warning != null
                  ? (isHaramIngredient ? Colors.red : Colors.orange.shade700)
                  : fattyAlcohol
                  ? Colors.blue.shade400
                  : kGreen,
            ),
            title: IngredientTitle(
              ingredient: ingredient,
              canonical: canonical,
              showTranslated: showTranslated,
              languageCode: languageCode,
            ),
            subtitle: localizedWarning != null
                ? SelectableText(localizedWarning)
                : fattyAlcohol
                ? Text(
                    loc.fattyAlcoholNote,
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  )
                : null,
            dense: true,
          ),
          if (isReported)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.report_problem_outlined,
                    size: 13,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reportExplanation?.isNotEmpty == true
                          ? reportExplanation!
                          : loc.reportedIngredient,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
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
