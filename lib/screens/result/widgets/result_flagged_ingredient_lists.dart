import 'package:flutter/material.dart';

import '../../../constants/ingredient_guides.dart';
import '../../../constants/ingredient_keywords.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../ingredient_display.dart';
import 'ingredient_guide_link_row.dart';

class ResultFlaggedIngredientLists extends StatelessWidget {
  const ResultFlaggedIngredientLists({
    super.key,
    required this.product,
    required this.showTranslated,
    required this.languageCode,
    required this.loc,
  });

  final Product product;
  final bool showTranslated;
  final String languageCode;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    if (product.isHalal &&
        product.haramIngredients.isEmpty &&
        product.suspiciousIngredients.isEmpty &&
        product.haramLabels.isEmpty &&
        product.suspiciousLabels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!product.isHalal && product.haramIngredients.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loc.flaggedIngredients,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...product.haramIngredients.map(
            (e) => _FlaggedListTile(
              ingredient: e,
              warnings: product.ingredientWarnings,
              product: product,
              showTranslated: showTranslated,
              languageCode: languageCode,
              loc: loc,
              fallbackWarning: loc.foundInIngredients,
              icon: const Icon(Icons.error, color: Colors.red),
              linkColor: Colors.red.shade700,
            ),
          ),
        ],
        if (product.suspiciousIngredients.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loc.mayBeAnimalDerived,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...product.suspiciousIngredients.map(
            (e) => _FlaggedListTile(
              ingredient: e,
              warnings: product.ingredientWarnings,
              product: product,
              showTranslated: showTranslated,
              languageCode: languageCode,
              loc: loc,
              fallbackWarning: loc.mayBeAnimalDerivedNote,
              icon: Icon(Icons.warning, color: Colors.orange.shade600),
              linkColor: Colors.orange.shade800,
            ),
          ),
        ],
        if (product.haramLabels.isNotEmpty ||
            product.suspiciousLabels.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loc.flaggedLabels,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...product.haramLabels.map(
            (e) => _FlaggedListTile(
              ingredient: e,
              warnings: product.labelWarnings,
              product: product,
              showTranslated: false,
              languageCode: languageCode,
              loc: loc,
              fallbackWarning: loc.foundInLabels,
              icon: const Icon(Icons.error, color: Colors.red),
            ),
          ),
          ...product.suspiciousLabels.map(
            (e) => _FlaggedListTile(
              ingredient: e,
              warnings: product.labelWarnings,
              product: product,
              showTranslated: false,
              languageCode: languageCode,
              loc: loc,
              fallbackWarning: loc.foundInLabels,
              icon: Icon(Icons.warning, color: Colors.orange.shade600),
            ),
          ),
        ],
      ],
    );
  }
}

class _FlaggedListTile extends StatelessWidget {
  const _FlaggedListTile({
    required this.ingredient,
    required this.warnings,
    required this.product,
    required this.showTranslated,
    required this.languageCode,
    required this.loc,
    required this.fallbackWarning,
    required this.icon,
    this.linkColor,
  });

  final String ingredient;
  final Map<String, String> warnings;
  final Product product;
  final bool showTranslated;
  final String languageCode;
  final AppLocalizations loc;
  final String fallbackWarning;
  final Widget icon;
  final Color? linkColor;

  @override
  Widget build(BuildContext context) {
    final warning = warnings[ingredient];
    final canonical = product.ingredientCanonicals[ingredient];
    final displayWarning =
        localizedIngredientWarning(
          ingredient: ingredient,
          canonical: canonical,
          warning: warning,
          languageCode: languageCode,
        ) ??
        _fallbackSuspiciousWarning(
          canonical: canonical,
          languageCode: languageCode,
          loc: loc,
        );
    final guides = IngredientGuides.linksForTerm(
      ingredient,
      languageCode,
      storedCanonicals: product.ingredientCanonicals,
    );

    return ListTile(
      leading: icon,
      title: IngredientTitle(
        ingredient: ingredient,
        canonical: canonical,
        showTranslated: showTranslated,
        languageCode: languageCode,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(displayWarning),
          if (guides.isNotEmpty)
            IngredientGuideLinkRow(
              guides: guides,
              readLabel: loc.readGuide,
              linkColor: linkColor,
            ),
        ],
      ),
      dense: true,
    );
  }
}

String _fallbackSuspiciousWarning({
  required String? canonical,
  required String languageCode,
  required AppLocalizations loc,
}) {
  if (canonical != null &&
      IngredientKeywords.flavouringAromaCanonicals.contains(canonical)) {
    return IngredientKeywords.localizedReason('flavouring', languageCode) ??
        loc.mayBeAnimalDerivedNote;
  }
  return loc.mayBeAnimalDerivedNote;
}
