import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_colors.dart';
import '../../../constants/ingredient_guides.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';

class ResultRelatedGuides extends StatelessWidget {
  const ResultRelatedGuides({
    super.key,
    required this.product,
    required this.languageCode,
    required this.loc,
  });

  final Product product;
  final String languageCode;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final guides = IngredientGuides.linksForProduct(product, languageCode);
    if (guides.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.relatedGuides,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        ...guides.map(
          (guide) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GuideCard(guide: guide, readLabel: loc.readGuide),
          ),
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide, required this.readLabel});

  final IngredientGuideLink guide;
  final String readLabel;

  Future<void> _open() async {
    final uri = Uri.parse(guide.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                guide.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                guide.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$readLabel →',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
