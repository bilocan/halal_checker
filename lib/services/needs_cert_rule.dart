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
    if (product.suspiciousLabels.isNotEmpty) return false;
    final items = [
      ...product.suspiciousIngredients,
      ...product.suspiciousAdditives,
    ];
    if (items.isEmpty) return true;
    return items.every(
      (item) => itemIsNeedsCert(item, product.ingredientCanonicals),
    );
  }

  /// True when category/name would already require a slaughter certificate.
  /// Cysteine copy must not replace that animal-product explanation.
  static bool hasAnimalProductSignal(Product product) {
    if (product.isNonFood) return false;
    final tags = product.categoriesTags.map((c) => c.toLowerCase());
    if (tags.any(FoodCategories.haram.contains)) return false;
    final vegan =
        product.labels.any(
          (l) =>
              FoodCategories.veganOrVegetarianLabels.contains(l.toLowerCase()),
        ) ||
        FoodCategories.veganOrVegetarianNameTerms.any(
          (term) => _wordMatch(product.name, term),
        );
    if (vegan) return false;
    if (tags.any(FoodCategories.animalProduct.contains)) return true;
    final categoriesUnknown =
        tags.isEmpty || tags.every((c) => c.contains('unknown'));
    return categoriesUnknown &&
        FoodCategories.animalProductNameTerms.any(
          (term) => _wordMatch(product.name, term),
        );
  }

  static bool _wordMatch(String text, String term) {
    return RegExp(
      '(?<![a-zA-ZÀ-ɏ])${RegExp.escape(term)}(?![a-zA-ZÀ-ɏ])',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static bool _haramByCategory(Product product) {
    return product.categoriesTags.any(
      (c) => FoodCategories.haram.contains(c.toLowerCase()),
    );
  }

  static Product applyToProduct(Product product) {
    final hasHalalCert = product.labels.any(
      (l) => FoodCategories.halalCertificationLabels.contains(l.toLowerCase()),
    );
    final haramByCategory = _haramByCategory(product);
    final hasHaram =
        product.haramIngredients.isNotEmpty ||
        product.haramLabels.isNotEmpty ||
        product.haramAdditives.isNotEmpty ||
        haramByCategory;
    final cysteineFound = foundOn(product);
    final applied = apply(
      alreadyRequiresHalalCert: product.requiresHalalCert,
      hasHalalCert: hasHalalCert,
      hasHaram: hasHaram,
      isNonFood: product.isNonFood,
      suspicious: product.suspiciousIngredients,
      suspiciousAdditives: product.suspiciousAdditives,
      canonicals: product.ingredientCanonicals,
      warnings: product.ingredientWarnings,
    );

    final computedHalal =
        !product.isUnknown &&
        !product.isNonFood &&
        !haramByCategory &&
        product.haramIngredients.isEmpty &&
        product.haramLabels.isEmpty &&
        product.haramAdditives.isEmpty &&
        applied.suspicious.isEmpty &&
        applied.suspiciousAdditives.isEmpty &&
        product.suspiciousLabels.isEmpty &&
        !applied.requiresHalalCert;
    // A trusted mark may only clear a cysteine-only result. Do not upgrade
    // category/name haram (or other non-cysteine not-halal) to halal.
    final canClearViaHalalMark =
        hasHalalCert && cysteineFound && !hasHaram && !product.isNonFood;
    final isHalal = computedHalal && (product.isHalal || canClearViaHalalMark);

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
    bool isNonFood = false,
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
        explanation: waivedAll && !hasHaram && !isNonFood
            ? 'No haram or suspicious ingredients detected. Assessed by keyword matching.'
            : null,
      );
    }

    if (isNonFood || hasHaram) {
      return (
        requiresHalalCert: alreadyRequiresHalalCert && !hasHalalCert,
        suspicious: suspicious,
        suspiciousAdditives: suspiciousAdditives,
        warnings: warnings,
        explanation: null,
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
      // Animal-category cert already has its own slaughter explanation.
      explanation: alreadyRequiresHalalCert ? null : cysteineExplanation,
    );
  }
}
