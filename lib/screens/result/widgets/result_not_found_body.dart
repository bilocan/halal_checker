import 'package:flutter/material.dart';

import '../../../app_colors.dart';
import '../../../integration_test_keys.dart';
import '../../../localization/app_localizations.dart';
import 'copy_barcode_row.dart';

class ResultNotFoundBody extends StatelessWidget {
  const ResultNotFoundBody({
    super.key,
    required this.barcode,
    required this.loc,
    required this.onCopyBarcode,
    required this.onScanAgain,
  });

  final String barcode;
  final AppLocalizations loc;
  final VoidCallback onCopyBarcode;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: IntegrationTestKeys.productNotFound,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(loc.productNotFound, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          CopyBarcodeRow(barcode: barcode, onCopy: onCopyBarcode),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onScanAgain,
            style: ElevatedButton.styleFrom(backgroundColor: kGreen),
            child: Text(loc.scanAgain),
          ),
        ],
      ),
    );
  }
}
