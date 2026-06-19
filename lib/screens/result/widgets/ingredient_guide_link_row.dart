import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/ingredient_guides.dart';

/// Compact inline links for one flagged term (opens blog guide in browser).
class IngredientGuideLinkRow extends StatelessWidget {
  const IngredientGuideLinkRow({
    super.key,
    required this.guides,
    required this.readLabel,
    this.linkColor,
  });

  final List<IngredientGuideLink> guides;
  final String readLabel;

  /// Defaults to theme primary; pass red/orange on flagged tiles.
  final Color? linkColor;

  Future<void> _open(IngredientGuideLink guide) async {
    final uri = Uri.parse(guide.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (guides.isEmpty) return const SizedBox.shrink();

    final color = linkColor ?? Theme.of(context).colorScheme.primary;

    if (guides.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: color,
          ),
          onPressed: () => _open(guides.first),
          child: Text(readLabel),
        ),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 0,
      children: [
        for (final guide in guides)
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: color,
            ),
            onPressed: () => _open(guide),
            child: Text(guide.title),
          ),
      ],
    );
  }
}
