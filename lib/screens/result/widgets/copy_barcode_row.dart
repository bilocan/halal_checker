import 'package:flutter/material.dart';

class CopyBarcodeRow extends StatelessWidget {
  const CopyBarcodeRow({
    super.key,
    required this.barcode,
    required this.onCopy,
  });

  final String barcode;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Barcode: $barcode', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 4),
          Icon(Icons.copy, size: 14, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
