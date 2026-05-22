import 'package:flutter/material.dart';

/// Shared palette for the ingredient-source badge and ingredient list cards.
class IngredientSourceStyle {
  const IngredientSourceStyle._(this.label, this.color);

  final String label;
  final Color color;

  Color get fillColor => color.withAlpha(25);
  Color get borderColor => color.withAlpha(100);

  static IngredientSourceStyle of(String? source) {
    return switch (source) {
      'ai' => const IngredientSourceStyle._('AI', Color(0xFF7C3AED)),
      'community' => const IngredientSourceStyle._(
        'Community',
        Color(0xFF0D9488),
      ),
      _ => const IngredientSourceStyle._('OFF', Color(0xFF6B7280)),
    };
  }
}

class IngredientSourceBadge extends StatelessWidget {
  const IngredientSourceBadge({super.key, required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final style = IngredientSourceStyle.of(source);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: style.fillColor,
        border: Border.all(color: style.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
