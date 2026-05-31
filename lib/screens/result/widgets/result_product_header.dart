import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../widgets/product_label_chips.dart';
import 'copy_barcode_row.dart';

class ResultProductHeader extends StatelessWidget {
  const ResultProductHeader({
    super.key,
    required this.product,
    required this.barcode,
    required this.onCopyBarcode,
  });

  final Product product;
  final String barcode;
  final VoidCallback onCopyBarcode;

  @override
  Widget build(BuildContext context) {
    final chips = ProductLabelChips.build(
      product.labels,
      haramLabels: product.haramLabels.toSet(),
      suspiciousLabels: product.suspiciousLabels.toSet(),
    );

    return Column(
      children: [
        SelectableText(
          product.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        CopyBarcodeRow(barcode: barcode, onCopy: onCopyBarcode),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ],
    );
  }
}
