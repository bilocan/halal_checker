import 'package:flutter/material.dart';

import '../../../integration_test_keys.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../../../services/product_verdict.dart';
import '../../../widgets/product_label_chips.dart';
import '../result_status.dart';
import 'copy_barcode_row.dart';

class ResultHeroCard extends StatelessWidget {
  const ResultHeroCard({
    super.key,
    required this.product,
    required this.barcode,
    required this.loc,
    required this.onCopyBarcode,
  });

  final Product product;
  final String barcode;
  final AppLocalizations loc;
  final VoidCallback onCopyBarcode;

  @override
  Widget build(BuildContext context) {
    final status = ResultStatus.from(product, loc);
    final chips = ProductLabelChips.build(
      product.labels,
      haramLabels: product.haramLabels.toSet(),
      suspiciousLabels: product.suspiciousLabels.toSet(),
    );

    return Card(
      key: IntegrationTestKeys.resultStatus(
        ProductVerdict.e2eOutcomeKey(product),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: status.color,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(status.icon, color: Colors.white, size: 44),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: status.label,
                        child: Text(
                          status.label,
                          semanticsLabel: '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status.explanation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _AnalysisBadge(
                            icon: product.analyzedByAI
                                ? Icons.auto_awesome
                                : Icons.manage_search,
                            label: product.analyzedByAI
                                ? loc.aiAnalysis
                                : loc.keywordAnalysis,
                          ),
                          if (product.isManaged)
                            _AnalysisBadge(
                              icon: Icons.verified,
                              label: loc.managedProduct,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  product.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.brand.isNotEmpty || product.quantity.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      [
                        if (product.brand.isNotEmpty) product.brand,
                        if (product.quantity.isNotEmpty) product.quantity,
                      ].join(' · '),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 6),
                CopyBarcodeRow(barcode: barcode, onCopy: onCopyBarcode),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 6, children: chips),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisBadge extends StatelessWidget {
  const _AnalysisBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
