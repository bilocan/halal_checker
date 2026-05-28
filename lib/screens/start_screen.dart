import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../main.dart' show HalalCheckerApp;
import '../services/analysis_service.dart';
import '../widgets/lazy_indexed_stack.dart';
import '../services/auth_service.dart';
import '../services/version_service.dart';
import 'about_screen.dart';
import 'admin_panel_screen.dart';
import 'directory_screen.dart';
import 'keywords_screen.dart';
import 'start/start_tab_index.dart';
import 'start/widgets/start_home_tab.dart';

export 'start/start_tab_index.dart' show remapStartScreenTabIndex;

class StartScreen extends StatefulWidget {
  const StartScreen({
    super.key,
    @visibleForTesting this.analysisService,
    @visibleForTesting this.adminPanel,
  });

  /// When set (tests only), bypasses live Supabase admin checks.
  final AnalysisService? analysisService;

  /// When set (tests only), replaces [AdminPanelScreen] to avoid Supabase in tests.
  final Widget? adminPanel;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isAdmin = false;
  bool _canBatchImport = false;
  int _selectedIndex = 0;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    _authSubscription = AuthService.authStateChanges.listen((_) {
      if (mounted) _checkAdmin();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final service = widget.analysisService ?? AnalysisService();
    final results = await Future.wait([
      service.isAdmin(),
      service.hasOperation('admin.batch_import'),
    ]);
    if (!mounted) return;
    setState(() {
      final wasAdmin = _isAdmin;
      _isAdmin = results[0];
      _canBatchImport = results[1];
      _selectedIndex = remapStartScreenTabIndex(
        selectedIndex: _selectedIndex,
        wasAdmin: wasAdmin,
        isAdmin: _isAdmin,
      );
    });
  }

  Future<void> _checkForUpdate() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final info = await VersionService().checkForUpdate();
      if (info.status != UpdateStatus.updateAvailable) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).newVersionAvailable),
          action: SnackBarAction(
            label: 'Update',
            onPressed: () async {
              try {
                await VersionService.performUpdate(storeUrl: info.storeUrl);
              } catch (_) {}
            },
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (_) {}
  }

  int get _tabCount => _isAdmin ? 5 : 4;

  Widget _tabBody(BuildContext context, int index) {
    switch (index) {
      case 0:
        return StartHomeTab(
          key: const ValueKey('start_home_tab'),
          canBatchImport: _canBatchImport,
          onLocaleChanged: (locale) =>
              HalalCheckerApp.of(context)?.setLocale(locale),
        );
      case 1:
        return const KeywordsScreen();
      case 2:
        return const DirectoryScreen();
      case 3:
        if (_isAdmin) {
          return widget.adminPanel ?? const AdminPanelScreen();
        }
        return const AboutScreen();
      case 4:
        return const AboutScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: LazyIndexedStack(
        index: _selectedIndex,
        itemCount: _tabCount,
        itemBuilder: _tabBody,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: kGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: loc.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: loc.keywords,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store_outlined),
            activeIcon: const Icon(Icons.store),
            label: loc.halalDirectory,
          ),
          if (_isAdmin)
            BottomNavigationBarItem(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              activeIcon: const Icon(Icons.admin_panel_settings),
              label: loc.adminPanel,
            ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            activeIcon: const Icon(Icons.info),
            label: loc.about,
          ),
        ],
      ),
    );
  }
}
