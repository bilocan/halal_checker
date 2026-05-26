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
    this.onSubmitPackPhotos,
  });

  final String barcode;
  final AppLocalizations loc;
  final VoidCallback onCopyBarcode;
  final VoidCallback onScanAgain;

  /// When set (e.g. Supabase configured), user can contribute front + ingredient photos.
  final VoidCallback? onSubmitPackPhotos;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Column(
          key: IntegrationTestKeys.productNotFound,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(loc.productNotFound, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              loc.missingProductFlowHelpHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            CopyBarcodeRow(barcode: barcode, onCopy: onCopyBarcode),
            const SizedBox(height: 24),
            if (onSubmitPackPhotos != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: IntegrationTestKeys.submitPackPhotosNotFound,
                  onPressed: onSubmitPackPhotos,
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(loc.missingProductOpenFlow),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onScanAgain,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kGreen,
                  side: BorderSide(color: kGreen.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(loc.scanAgain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
