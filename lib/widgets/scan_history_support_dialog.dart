import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/app_localizations.dart';
import '../services/scan_history_diagnostics.dart';

/// Support dialog for scan-history failures (screenshot and share without Xcode).
void showScanHistorySupportDialog(
  BuildContext context,
  ScanHistoryDiagnostics diagnostics,
) {
  final loc = AppLocalizations.of(context);
  final text = diagnostics.toSupportText();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(loc.scanHistoryShowDetails),
      content: SingleChildScrollView(
        child: SelectableText(text, style: const TextStyle(fontSize: 13)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(loc.scanHistoryCopied)));
          },
          child: Text(loc.scanHistoryCopy),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(loc.cancel),
        ),
      ],
    ),
  );
}
