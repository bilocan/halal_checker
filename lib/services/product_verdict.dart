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
    if (product.haramIngredients.isNotEmpty) return ProductOutcome.haram;
    if (product.suspiciousIngredients.isNotEmpty) {
      return ProductOutcome.suspicious;
    }
    if (product.requiresHalalCert) return ProductOutcome.noCert;
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
