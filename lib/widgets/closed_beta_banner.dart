import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../utils/beta_feedback_mailto.dart';

/// Home-tab banner guiding closed-testers through core flows.
class ClosedBetaBanner extends StatelessWidget {
  const ClosedBetaBanner({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  Future<void> _sendFeedback(BuildContext context) async {
    final uri = await buildBetaFeedbackMailto();
    if (!context.mounted) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Material(
      color: kGreen.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.science_outlined, color: kGreenDark, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.closedBetaBannerTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: kGreenDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.closedBetaBannerSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey.shade600,
                  onPressed: onDismiss,
                  tooltip: loc.close,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              loc.closedBetaBannerTasks,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _sendFeedback(context),
                icon: const Icon(Icons.mail_outline, size: 18),
                label: Text(loc.sendBetaFeedback),
                style: TextButton.styleFrom(foregroundColor: kGreenDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
