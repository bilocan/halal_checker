import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../result_status.dart';

class ResultStatusBanner extends StatelessWidget {
  const ResultStatusBanner({
    super.key,
    required this.product,
    required this.loc,
  });

  final Product product;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final status = ResultStatus.from(product, loc);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(status.icon, color: Colors.white, size: 64),
          const SizedBox(height: 12),
          Semantics(
            label: status.label,
            child: Text(
              status.label,
              semanticsLabel: '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status.explanation,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  product.analyzedByAI
                      ? Icons.auto_awesome
                      : Icons.manage_search,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  product.analyzedByAI ? loc.aiAnalysis : loc.keywordAnalysis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (product.isManaged) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    loc.managedProduct,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
