import '../constants/food_categories.dart';
import '../constants/ingredient_keywords.dart';
import '../models/product.dart';

/// L-cysteine / E920: source is often hair, feathers, or pig bristles unless a
/// trusted halal certificate confirms microbial or synthetic production.
abstract final class NeedsCertRule {
  static const Set<String> canonicals = {'e920', 'l-cysteine'};

  static const String cysteineExplanation =
      'This product contains L-cysteine (E920), which needs a verified halal '
      'certificate. Commercial L-cysteine is often made from hair, feathers, or '
      'pig bristles; microbial or synthetic sources exist but are rarely labelled. '
      'Check the packaging for a trusted halal mark.';

  static bool isNeedsCertCanonical(String? canonical) =>
      canonical != null && canonicals.contains(canonical);

  static bool isNeedsCertText(String text) {
    final lower = text.toLowerCase();
    for (final canonical in canonicals) {
      final variants =
          IngredientKeywords.suspiciousVariants[canonical] ?? [canonical];
      for (final variant in variants) {
        final escaped = RegExp.escape(variant);
        if (RegExp(
          '${IngredientKeywords.wPre}$escaped${IngredientKeywords.wPost}',
          caseSensitive: false,
        ).hasMatch(lower)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool itemIsNeedsCert(String item, Map<String, String> canonicalsMap) {
    return isNeedsCertCanonical(canonicalsMap[item]) || isNeedsCertText(item);
  }

  static bool foundOn(Product product) {
    return [
      ...product.suspiciousIngredients,
      ...product.suspiciousAdditives,
    ].any((item) => itemIsNeedsCert(item, product.ingredientCanonicals));
  }

  /// True when every suspicious ingredient/additive is a needs-cert match
  /// (or there are none). Used so animal-category cert still wins when the
  /// suspicious list is empty.
  static bool onlyNeedsCertFlags(Product product) {
    final items = [
      ...product.suspiciousIngredients,
      ...product.suspiciousAdditives,
    ];
    if (items.isEmpty) return true;
    return items.every(
      (item) => itemIsNeedsCert(item, product.ingredientCanonicals),
    );
  }

  static Product applyToProduct(Product product) {
    final hasHalalCert = product.labels.any(
      (l) => FoodCategories.halalCertificationLabels.contains(l.toLowerCase()),
    );
    final applied = apply(
      alreadyRequiresHalalCert: product.requiresHalalCert,
      hasHalalCert: hasHalalCert,
      hasHaram:
          product.haramIngredients.isNotEmpty ||
          product.haramLabels.isNotEmpty ||
          product.haramAdditives.isNotEmpty,
      suspicious: product.suspiciousIngredients,
      suspiciousAdditives: product.suspiciousAdditives,
      canonicals: product.ingredientCanonicals,
      warnings: product.ingredientWarnings,
    );

    final computedHalal =
        !product.isUnknown &&
        product.haramIngredients.isEmpty &&
        product.haramLabels.isEmpty &&
        product.haramAdditives.isEmpty &&
        applied.suspicious.isEmpty &&
        applied.suspiciousAdditives.isEmpty &&
        !applied.requiresHalalCert;
    // Do not turn a category/name haram product into halal. Only a halal label
    // may clear a cysteine-only not-halal result.
    final isHalal = computedHalal && (product.isHalal || hasHalalCert);

    return product.copyWith(
      isHalal: isHalal,
      requiresHalalCert: applied.requiresHalalCert,
      suspiciousIngredients: applied.suspicious,
      suspiciousAdditives: applied.suspiciousAdditives,
      ingredientWarnings: applied.warnings,
      explanation: applied.explanation ?? product.explanation,
    );
  }

  static ({
    bool requiresHalalCert,
    List<String> suspicious,
    List<String> suspiciousAdditives,
    Map<String, String> warnings,
    String? explanation,
  })
  apply({
    required bool alreadyRequiresHalalCert,
    required bool hasHalalCert,
    required bool hasHaram,
    required List<String> suspicious,
    required List<String> suspiciousAdditives,
    required Map<String, String> canonicals,
    required Map<String, String> warnings,
  }) {
    bool isNeeds(String item) => itemIsNeedsCert(item, canonicals);

    final certSuspicious = suspicious.where(isNeeds).toList();
    final otherSuspicious = suspicious.where((s) => !isNeeds(s)).toList();
    final certAdditives = suspiciousAdditives.where(isNeeds).toList();
    final otherAdditives = suspiciousAdditives
        .where((s) => !isNeeds(s))
        .toList();
    final found = certSuspicious.isNotEmpty || certAdditives.isNotEmpty;

    if (!found) {
      return (
        requiresHalalCert: alreadyRequiresHalalCert && !hasHalalCert,
        suspicious: suspicious,
        suspiciousAdditives: suspiciousAdditives,
        warnings: warnings,
        explanation: null,
      );
    }

    if (hasHalalCert) {
      final waivedAll = otherSuspicious.isEmpty && otherAdditives.isEmpty;
      return (
        requiresHalalCert: false,
        suspicious: otherSuspicious,
        suspiciousAdditives: otherAdditives,
        warnings: warnings,
        explanation: waivedAll
            ? 'No haram or suspicious ingredients detected. Assessed by keyword matching.'
            : null,
      );
    }

    final updatedWarnings = Map<String, String>.from(warnings);
    const reason = IngredientKeywords.suspicious;
    for (final item in [...certSuspicious, ...certAdditives]) {
      updatedWarnings[item] =
          updatedWarnings[item] ?? reason['l-cysteine'] ?? cysteineExplanation;
    }

    return (
      requiresHalalCert: true,
      suspicious: suspicious,
      suspiciousAdditives: suspiciousAdditives,
      warnings: updatedWarnings,
      explanation: hasHaram ? null : cysteineExplanation,
    );
  }
}
