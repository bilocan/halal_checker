import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../screens/about_screen.dart';

/// One-line entry point to the community hub (website, GitHub, contact).
class CommunityContributePrompt extends StatelessWidget {
  const CommunityContributePrompt({super.key});

  void _openCommunityHub(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Material(
      color: kGreen.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openCommunityHub(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: kGreenDark, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.contributePrompt,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
              ),
              Text(
                loc.contributePromptAction,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kGreenDark,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, color: kGreenDark, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
