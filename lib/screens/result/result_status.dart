import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../models/product.dart';

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
    final isHalal = product.isHalal;
    final isUnknown = product.isUnknown;
    final isNonFood = product.isNonFood;
    final requiresHalalCert = product.requiresHalalCert;

    final color = isNonFood
        ? Colors.blueGrey.shade600
        : isUnknown
        ? Colors.orange.shade700
        : requiresHalalCert
        ? Colors.orange.shade700
        : (isHalal ? kGreen : Colors.red);

    final icon = isNonFood
        ? Icons.info_outline
        : isUnknown
        ? Icons.help_outline
        : requiresHalalCert
        ? Icons.warning_amber_outlined
        : (isHalal ? Icons.check_circle : Icons.cancel);

    final label = isNonFood
        ? loc.nonFood
        : isUnknown
        ? loc.unknown
        : requiresHalalCert
        ? loc.noCert
        : (isHalal ? '✅ HALAL' : '❌ NOT HALAL');

    final resultLabel = isNonFood
        ? loc.nonFood
        : isUnknown
        ? loc.unknown
        : requiresHalalCert
        ? loc.noCert
        : isHalal
        ? loc.halal
        : loc.notHalal;

    final explanation = product.isNonFood
        ? loc.explanationNonFood
        : product.requiresHalalCert
        ? loc.explanationNoCert
        : product.explanation.isNotEmpty
        ? product.explanation
        : halalReasonText(
            isHalal: isHalal,
            isUnknown: isUnknown,
            suspiciousIngredients: product.suspiciousIngredients,
            loc: loc,
          );

    return ResultStatus(
      color: color,
      icon: icon,
      label: label,
      explanation: explanation,
      resultLabel: resultLabel,
    );
  }
}

String halalReasonText({
  required bool isHalal,
  required bool isUnknown,
  required List<String> suspiciousIngredients,
  required AppLocalizations loc,
}) {
  if (isUnknown) return loc.explanationUnknown;
  if (isHalal) {
    return suspiciousIngredients.isEmpty
        ? loc.explanationClean
        : loc.explanationSuspiciousOnly(suspiciousIngredients.join(', '));
  }
  return loc.explanationHaram;
}
