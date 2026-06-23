import 'package:flutter/material.dart';

import '../../../app_colors.dart';
import '../../../localization/app_localizations.dart';

class ResultFooterActions extends StatelessWidget {
  const ResultFooterActions({
    super.key,
    required this.loc,
    required this.onScanAnother,
    required this.onFeedback,
    required this.onReport,
    required this.onShare,
  });

  final AppLocalizations loc;
  final VoidCallback onScanAnother;
  final VoidCallback onFeedback;
  final VoidCallback onReport;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: onScanAnother,
            child: Text(
              loc.scanAnotherProduct,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kGreen),
              foregroundColor: kGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: onFeedback,
            child: Text(
              loc.provideFeedback,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(
                  loc.shareAnalysis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onReport,
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: Text(
                  loc.reportWrongResult,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
