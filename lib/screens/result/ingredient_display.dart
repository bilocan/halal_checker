import 'package:flutter/material.dart';

import '../../constants/ingredient_keywords.dart';
import '../../services/product_service.dart';

/// Localized warning for an ingredient, preferring canonical keyword text.
String? localizedIngredientWarning({
  required String ingredient,
  required String? canonical,
  required String? warning,
  required String languageCode,
}) {
  if (canonical != null) {
    return IngredientKeywords.localizedReason(canonical, languageCode) ??
        warning;
  }
  return warning;
}

/// Title for a single ingredient row (original + optional canonical translation).
class IngredientTitle extends StatelessWidget {
  const IngredientTitle({
    super.key,
    required this.ingredient,
    this.canonical,
    this.showTranslated = false,
    required this.languageCode,
  });

  final String ingredient;
  final String? canonical;
  final bool showTranslated;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    if (canonical == null) return Text(ingredient);
    final display = ProductService.canonicalDisplay(canonical!, languageCode);
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[-\s]'), '');
    if (norm(ingredient).contains(norm(display))) return Text(ingredient);
    if (showTranslated) return Text(display);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: ingredient),
          TextSpan(
            text: '  ($display)',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
