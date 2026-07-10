import 'package:flutter/material.dart';

import '../../../config.dart';
import '../../../localization/app_localizations.dart';
import '../../../main.dart' show HalalCheckerApp;
import 'start_auth_app_bar_action.dart';

/// Language picker and account control shared across start-flow tab AppBars.
class StartAppBarActions {
  StartAppBarActions._();

  static List<Widget> build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      PopupMenuButton<String>(
        onSelected: (value) {
          HalalCheckerApp.of(context)?.setLocale(Locale(value));
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'en',
            child: Row(
              children: [
                const Text('🇬🇧', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(loc.english),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'tr',
            child: Row(
              children: [
                const Text('🇹🇷', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(loc.turkish),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'de',
            child: Row(
              children: [
                const Text('🇩🇪', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(loc.german),
              ],
            ),
          ),
        ],
        icon: const Icon(Icons.language),
      ),
      if (AppConfig.hasSupabase) const StartAuthAppBarAction(),
    ];
  }
}
