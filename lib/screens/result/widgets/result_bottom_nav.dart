import 'package:flutter/material.dart';

import '../../../app_colors.dart';
import '../../../localization/app_localizations.dart';

class ResultBottomNav extends StatelessWidget {
  const ResultBottomNav({
    super.key,
    required this.loc,
    required this.isAdmin,
    required this.onHome,
    required this.onAdmin,
  });

  final AppLocalizations loc;
  final bool isAdmin;
  final VoidCallback onHome;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) {
    final adminIndex = isAdmin ? 3 : -1;
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 0) {
          onHome();
        } else if (index == adminIndex) {
          onAdmin();
        }
      },
      selectedItemColor: kGreen,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: loc.home),
        BottomNavigationBarItem(
          icon: const Icon(Icons.list_alt),
          label: loc.keywords,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.store_outlined),
          label: loc.halalDirectory,
        ),
        if (isAdmin)
          BottomNavigationBarItem(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            activeIcon: const Icon(Icons.admin_panel_settings),
            label: loc.adminPanel,
          ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.info_outline),
          label: loc.about,
        ),
      ],
    );
  }
}
