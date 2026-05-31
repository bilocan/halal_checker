import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/product.dart';
import '../../services/product_verdict.dart';

/// Visual and textual halal verdict derived from a [Product].
class ResultStatus {
  const ResultStatus({
    required this.color,
    required this.icon,
    required this.label,
    required this.explanation,
    required this.resultLabel,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String explanation;
  final String resultLabel;

  factory ResultStatus.from(Product product, AppLocalizations loc) {
    final outcome = ProductVerdict.outcome(product);

    final color = switch (outcome) {
      ProductOutcome.nonFood => Colors.blueGrey.shade600,
      ProductOutcome.unknown => Colors.orange.shade700,
      ProductOutcome.haram => Colors.red,
      ProductOutcome.suspicious => Colors.orange.shade700,
      ProductOutcome.noCert => Colors.orange.shade700,
      ProductOutcome.halal => kGreen,
    };

    final icon = switch (outcome) {
      ProductOutcome.nonFood => Icons.info_outline,
      ProductOutcome.unknown => Icons.help_outline,
      ProductOutcome.haram => Icons.cancel,
      ProductOutcome.suspicious => Icons.warning_amber_outlined,
      ProductOutcome.noCert => Icons.warning_amber_outlined,
      ProductOutcome.halal => Icons.check_circle,
    };

    final label = switch (outcome) {
      ProductOutcome.nonFood => loc.nonFood,
      ProductOutcome.unknown => loc.unknown,
      ProductOutcome.haram => '❌ ${loc.notHalal}',
      ProductOutcome.suspicious => loc.suspiciousVerdict,
      ProductOutcome.noCert => loc.noCert,
      ProductOutcome.halal => '✅ ${loc.halal}',
    };

    final resultLabel = switch (outcome) {
      ProductOutcome.nonFood => loc.nonFood,
      ProductOutcome.unknown => loc.unknown,
      ProductOutcome.haram => loc.notHalal,
      ProductOutcome.suspicious => loc.suspiciousResult,
      ProductOutcome.noCert => loc.noCert,
      ProductOutcome.halal => loc.halal,
    };

    final explanation = product.isNonFood
        ? loc.explanationNonFood
        : product.requiresHalalCert && outcome == ProductOutcome.noCert
        ? loc.explanationNoCert
        : product.explanation.isNotEmpty
        ? product.explanation
        : defaultExplanation(product, outcome, loc);

    return ResultStatus(
      color: color,
      icon: icon,
      label: label,
      explanation: explanation,
      resultLabel: resultLabel,
    );
  }
}

String defaultExplanation(
  Product product,
  ProductOutcome outcome,
  AppLocalizations loc,
) {
  return switch (outcome) {
    ProductOutcome.unknown => loc.explanationUnknown,
    ProductOutcome.haram => loc.explanationHaram,
    ProductOutcome.suspicious => loc.explanationSuspiciousOnly(
      [
        ...product.suspiciousIngredients,
        ...product.suspiciousLabels,
      ].join(', '),
    ),
    ProductOutcome.halal => loc.explanationClean,
    ProductOutcome.noCert => loc.explanationNoCert,
    ProductOutcome.nonFood => loc.explanationNonFood,
  };
}
