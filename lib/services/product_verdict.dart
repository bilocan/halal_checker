import '../models/product.dart';

/// Display / storage outcome for a product scan.
enum ProductOutcome { nonFood, unknown, haram, suspicious, noCert, halal }

/// Shared rules for [Product.isHalal] and result-screen status.
abstract final class ProductVerdict {
  /// True only when there are no haram or suspicious ingredients and no cert gap.
  static bool isHalalFromFlags({
    required List<String> haramIngredients,
    required List<String> suspiciousIngredients,
    required bool requiresHalalCert,
    bool isUnknown = false,
    bool isHalalByCategory = false,
  }) {
    if (isHalalByCategory) return true;
    if (isUnknown) return false;
    if (haramIngredients.isNotEmpty) return false;
    if (suspiciousIngredients.isNotEmpty) return false;
    if (requiresHalalCert) return false;
    return true;
  }

  static ProductOutcome outcome(Product product) {
    if (product.isNonFood) return ProductOutcome.nonFood;
    if (product.isUnknown) return ProductOutcome.unknown;
    // Haram/suspicious can also come from labels or additives, not just the
    // ingredient list — check all three sources before falling back to the
    // collapsed isHalal flag, so e.g. a suspicious-only additive (may be
    // animal-derived, not confirmed haram) shows as suspicious, not haram.
    if (product.haramIngredients.isNotEmpty ||
        product.haramLabels.isNotEmpty ||
        product.haramAdditives.isNotEmpty) {
      return ProductOutcome.haram;
    }
    // Cert-required beats merely-suspicious: requiresHalalCert means the
    // product is *confirmed* animal-derived (category/name/ingredient match)
    // and just needs slaughter verification, which is more specific than a
    // "might be animal-derived" suspicious flag from an unrelated signal
    // (e.g. a suspicious additive on a confirmed-meat product).
    if (product.requiresHalalCert) return ProductOutcome.noCert;
    if (product.suspiciousIngredients.isNotEmpty ||
        product.suspiciousLabels.isNotEmpty ||
        product.suspiciousAdditives.isNotEmpty) {
      return ProductOutcome.suspicious;
    }
    if (product.isHalal) return ProductOutcome.halal;
    return ProductOutcome.haram;
  }

  /// E2E registry key suffix for [IntegrationTestKeys.resultStatus].
  static String e2eOutcomeKey(Product product) {
    switch (outcome(product)) {
      case ProductOutcome.nonFood:
        return 'nonfood';
      case ProductOutcome.unknown:
        return 'unknown';
      case ProductOutcome.haram:
        return 'haram';
      case ProductOutcome.suspicious:
        return 'suspicious';
      case ProductOutcome.noCert:
        return 'nocert';
      case ProductOutcome.halal:
        return 'halal';
    }
  }

  /// Persisted in [DatabaseService] `scans.verdict` for history list colors.
  static String storageKey(Product product) => e2eOutcomeKey(product);
}
