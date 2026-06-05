import '../../constants/food_categories.dart';
import '../../constants/ingredient_keywords.dart';
import '../../localization/app_localizations.dart';
import '../../models/product.dart';
import '../../services/product_verdict.dart';

/// User-facing verdict explanation in the active app locale.
///
/// Ignores [Product.explanation] (often English from keyword/AI/backend storage)
/// and derives copy from verdict flags and ingredient lists instead.
String localizedProductExplanation({
  required Product product,
  required ProductOutcome outcome,
  required AppLocalizations loc,
}) {
  if (product.isNonFood) return loc.explanationNonFood;

  if (product.requiresHalalCert && outcome == ProductOutcome.noCert) {
    return loc.explanationNoCert;
  }

  return switch (outcome) {
    ProductOutcome.nonFood => loc.explanationNonFood,
    ProductOutcome.unknown =>
      product.keywordMatchSource == 'unanalyzable'
          ? loc.explanationUnanalyzableLanguage
          : loc.explanationUnknown,
    ProductOutcome.haram => _haramExplanation(product, loc),
    ProductOutcome.suspicious => _localizedSuspiciousExplanation(product, loc),
    ProductOutcome.halal =>
      _isHalalInherentCategory(product)
          ? loc.explanationHalalInherentCategory
          : loc.explanationClean,
    ProductOutcome.noCert => loc.explanationNoCert,
  };
}

String _localizedSuspiciousExplanation(Product product, AppLocalizations loc) {
  final suspicious = [
    ...product.suspiciousIngredients,
    ...product.suspiciousLabels,
  ];
  if (suspicious.isEmpty) return loc.explanationSuspiciousOnly('');

  final canonicals = product.ingredientCanonicals;
  final flavouring = <String>[];
  final other = <String>[];
  for (final ing in suspicious) {
    final canonical = canonicals[ing];
    if (canonical != null &&
        IngredientKeywords.flavouringAromaCanonicals.contains(canonical)) {
      flavouring.add(ing);
    } else {
      other.add(ing);
    }
  }

  final vegan = IngredientKeywords.hasVeganLabelEvidence(
    product.labels,
    product.name,
  );

  if (vegan && flavouring.isNotEmpty && other.isEmpty) {
    return loc.explanationSuspiciousVeganFlavouringOnly(flavouring.join(', '));
  }
  if (vegan && flavouring.isNotEmpty && other.isNotEmpty) {
    return loc.explanationSuspiciousVeganFlavouringAndOther(
      flavouring.join(', '),
      other.join(', '),
    );
  }
  if (flavouring.isNotEmpty && other.isEmpty) {
    return loc.explanationSuspiciousFlavouringOnly(flavouring.join(', '));
  }
  if (flavouring.isNotEmpty && other.isNotEmpty) {
    return loc.explanationSuspiciousFlavouringAndOther(
      flavouring.join(', '),
      other.join(', '),
    );
  }
  return loc.explanationSuspiciousOnly(suspicious.join(', '));
}

String _haramExplanation(Product product, AppLocalizations loc) {
  if (product.haramIngredients.isNotEmpty) {
    return loc.explanationHaramWithIngredients(
      product.haramIngredients.join(', '),
    );
  }
  if (product.haramAdditives.isNotEmpty) {
    return loc.explanationHaramAdditives(product.haramAdditives.join(', '));
  }
  final category = _firstHaramCategoryTag(product.categoriesTags);
  if (category != null) {
    return loc.explanationHaramCategory(_formatCategoryTag(category));
  }
  return loc.explanationHaram;
}

bool _isHalalInherentCategory(Product product) {
  if (product.ingredients.isNotEmpty) return false;
  if (product.haramIngredients.isNotEmpty ||
      product.suspiciousIngredients.isNotEmpty) {
    return false;
  }
  return product.categoriesTags.any(
    (c) => FoodCategories.halal.contains(c.toLowerCase()),
  );
}

String? _firstHaramCategoryTag(List<String> tags) {
  for (final tag in tags) {
    if (FoodCategories.haram.contains(tag.toLowerCase())) return tag;
  }
  return null;
}

String _formatCategoryTag(String tag) {
  var s = tag.toLowerCase();
  final colon = s.indexOf(':');
  if (colon >= 0) s = s.substring(colon + 1);
  return s.replaceAll('-', ' ');
}
