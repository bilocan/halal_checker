import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_colors.dart';
import '../config.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/product_service.dart';
import '../localization/app_localizations.dart';
import '../widgets/halal_scan_logo.dart';
import 'result_screen.dart';
import 'home_screen.dart';
import 'keywords_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = true;
  bool _isLoadingProduct = false;

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final scans = await DatabaseService.instance.getRecentScans();
    if (mounted) {
      setState(() {
        _recentScans = scans;
        _isLoading = false;
      });
    }
  }

  Future<void> _openScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    await _loadRecentScans();
  }

  Future<void> _openResult(
    Map<String, dynamic> scan, {
    bool recheck = false,
  }) async {
    setState(() => _isLoadingProduct = true);
    try {
      final product = recheck
          ? await _productService.refreshProduct(scan['barcode'] as String)
          : await _productService.getProduct(scan['barcode'] as String);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            product: product,
            barcode: scan['barcode'] as String,
          ),
        ),
      );
      if (mounted) await _loadRecentScans();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).productCouldNotBeRefreshed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    final loc = AppLocalizations.of(context);

    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';

    if (difference.inDays == 0) return '${loc.today}, $time';
    if (difference.inDays == 1) return '${loc.yesterday}, $time';
    if (difference.inDays < 7) {
      return '${loc.daysAgo(difference.inDays)}, $time';
    }

    final y = date.year;
    final mo = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$mo-$d, $time';
  }

  Widget _buildAuthButton(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = AuthService.currentUser;
        if (user == null) {
          return IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Sign in',
            onPressed: () => _signIn(context),
          );
        }
        final avatarUrl = AuthService.avatarUrl;
        return PopupMenuButton<String>(
          offset: const Offset(0, 40),
          onSelected: (value) async {
            if (value == 'signout') await AuthService.signOut();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                AuthService.displayName ?? user.email ?? 'Signed in',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Sign out'),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: avatarUrl != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(avatarUrl),
                  )
                : const Icon(Icons.person),
          ),
        );
      },
    );
  }

  Future<void> _signIn(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign-in failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.startTitle),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: localizations.keywords,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KeywordsScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              HalalCheckerApp.of(context)?.setLocale(Locale(value));
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'en', child: Text(localizations.english)),
              PopupMenuItem(value: 'tr', child: Text(localizations.turkish)),
              PopupMenuItem(value: 'de', child: Text(localizations.german)),
            ],
            icon: const Icon(Icons.language),
          ),
          if (AppConfig.hasSupabase) _buildAuthButton(context),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Logo + tagline header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kGreenDark, kGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const HalalScanLogo(size: 72, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        localizations.tagline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          localizations.taglineSubtitle,
                          style: TextStyle(
                            color: Colors.white.withAlpha(190),
                            fontSize: 12,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Main scan button
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: kGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kGreen.withAlpha(80),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _openScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          localizations.scanButton,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Recent scans section
                Text(
                  localizations.lastResults,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _recentScans.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations.noRecentResults,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizations.noRecentResultsHint,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _recentScans.length,
                          itemBuilder: (context, index) {
                            final scan = _recentScans[index];
                            final isHalal = scan['isHalal'] as bool;
                            final barcode = scan['barcode'] as String;

                            return Dismissible(
                              key: ValueKey(barcode),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) async {
                                final removed = scan;
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _recentScans.removeAt(index));
                                await DatabaseService.instance.deleteScan(
                                  barcode,
                                );
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      localizations.deletedFromHistory,
                                    ),
                                    action: SnackBarAction(
                                      label: localizations.undo,
                                      onPressed: () async {
                                        await DatabaseService.instance
                                            .insertScan(
                                              barcode:
                                                  removed['barcode'] as String,
                                              productName:
                                                  removed['productName']
                                                      as String,
                                              isHalal:
                                                  removed['isHalal'] as bool,
                                            );
                                        await _loadRecentScans();
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Semantics(
                                    label: isHalal
                                        ? localizations.halal
                                        : localizations.notHalal,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: isHalal ? kGreen : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    scan['productName'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${localizations.lastScanned}: ${_formatDate(scan['timestamp'] as int)}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.refresh),
                                        color: kGreen,
                                        tooltip: localizations.recheck,
                                        onPressed: () =>
                                            _openResult(scan, recheck: true),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  onTap: () => _openResult(scan),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_isLoadingProduct)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: kGreen),
              ),
            ),
        ],
      ),
    );
  }
}
