import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import '../app_colors.dart';
import '../config.dart';
import '../main.dart';
import '../models/product.dart';
import '../services/analysis_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/ingredient_sanitizer.dart';
import '../services/ocr_service.dart';
import '../services/product_service.dart';
import '../services/version_service.dart';
import '../localization/app_localizations.dart';
import '../widgets/halal_scan_logo.dart';
import 'result_screen.dart';
import 'home_screen.dart';
import 'about_screen.dart';
import 'keywords_screen.dart';
import 'admin_panel_screen.dart';
import 'directory_screen.dart';

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
  bool _showFlaggedOnly = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
    _checkAdmin();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    AuthService.authStateChanges.listen((_) {
      if (mounted) _checkAdmin();
    });
  }

  Future<void> _checkAdmin() async {
    final admin = await AnalysisService().isAdmin();
    if (mounted) setState(() => _isAdmin = admin);
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

  Future<void> _analyzeIngredientsPhoto() async {
    final loc = AppLocalizations.of(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(loc.takePhotoOfIngredients),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(loc.extractFromExistingImage),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(source: source, imageQuality: 85);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.cameraError)));
      }
      return;
    }
    if (photo == null || !mounted) return;

    setState(() => _isLoadingProduct = true);
    try {
      final text = await OcrService.extractIngredientsFromFile(
        File(photo.path),
      );
      if (!mounted) return;
      if (text == null || text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.ocrFailed)));
        return;
      }

      final ingredients = IngredientSanitizer.sanitize(text);

      final analysis = ProductService.analyzeWithKeywords(ingredients);
      final barcode = 'photo_${DateTime.now().millisecondsSinceEpoch}';

      final product = Product(
        barcode: barcode,
        name: loc.photoAnalysisProductName,
        ingredients: ingredients,
        isHalal: analysis.isHalal,
        haramIngredients: analysis.haram,
        suspiciousIngredients: analysis.suspicious,
        ingredientWarnings: analysis.warnings,
        ingredientTranslations: analysis.translations,
        labels: const [],
        explanation: analysis.explanation,
        analyzedByAI: false,
        analysisMethod: 'keyword',
      );

      await DatabaseService.instance.insertScan(
        barcode: barcode,
        productName: product.name,
        isHalal: product.isHalal,
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(product: product, barcode: barcode),
        ),
      );
      if (mounted) await _loadRecentScans();
    } finally {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
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
      if (recheck && product != null) {
        await DatabaseService.instance.insertScan(
          barcode: scan['barcode'] as String,
          productName: product.name,
          isHalal: product.isHalal,
        );
      }
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
            tooltip: AppLocalizations.of(context).signIn,
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
                AuthService.displayName ??
                    user.email ??
                    AppLocalizations.of(context).signedIn,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).signOut),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: avatarUrl != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: CachedNetworkImageProvider(avatarUrl),
                  )
                : const Icon(Icons.person),
          ),
        );
      },
    );
  }

  Future<void> _signIn(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.signIn,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SignInWithAppleButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _signInWithApple();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _signInWithGoogle();
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithApple() async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context);
    try {
      final success = await AuthService.signInWithApple();
      if (!success && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(loc.signInFailed),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(loc.signInFailed)));
    }
  }

  Future<void> _signInWithGoogle() async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context);
    try {
      final success = await AuthService.signInWithGoogle();
      if (!success && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(loc.signInFailed),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(loc.signInFailed)));
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
            icon: const Icon(Icons.info_outline),
            tooltip: localizations.about,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
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
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: localizations.adminPanel,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              ),
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _analyzeIngredientsPhoto,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGreen,
                    side: const BorderSide(color: kGreenLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    localizations.photoIngredientsButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DirectoryScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kGreen,
                    side: const BorderSide(color: kGreenLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.store),
                  label: Text(
                    localizations.halalDirectory,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Recent scans section
                Text(
                  localizations.lastResults,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _FilterChip(
                      label: localizations.allScans,
                      selected: !_showFlaggedOnly,
                      onTap: () => setState(() => _showFlaggedOnly = false),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: localizations.flaggedOnly,
                      selected: _showFlaggedOnly,
                      icon: Icons.bookmark,
                      onTap: () => setState(() => _showFlaggedOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                      : Builder(
                          builder: (context) {
                            final displayed = _showFlaggedOnly
                                ? _recentScans
                                      .where((s) => s['isFlagged'] == true)
                                      .toList()
                                : _recentScans;
                            if (displayed.isEmpty) {
                              return Center(
                                child: Text(
                                  localizations.noRecentResults,
                                  style: const TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: displayed.length,
                              itemBuilder: (context, index) {
                                final scan = displayed[index];
                                final isHalal = scan['isHalal'] as bool;
                                final isFlagged = scan['isFlagged'] as bool;
                                final barcode = scan['barcode'] as String;
                                final note = scan['notes'] as String?;

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
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    setState(
                                      () => _recentScans.removeWhere(
                                        (s) => s['barcode'] == barcode,
                                      ),
                                    );
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
                                                      removed['barcode']
                                                          as String,
                                                  productName:
                                                      removed['productName']
                                                          as String,
                                                  isHalal:
                                                      removed['isHalal']
                                                          as bool,
                                                  notes:
                                                      removed['notes']
                                                          as String?,
                                                  isFlagged:
                                                      removed['isFlagged']
                                                          as bool,
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
                                            color: isHalal
                                                ? kGreen
                                                : Colors.red,
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
                                        note != null && note.isNotEmpty
                                            ? note.length > 50
                                                  ? '${note.substring(0, 50)}…'
                                                  : note
                                            : '${localizations.lastScanned}: ${_formatDate(scan['timestamp'] as int)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isFlagged)
                                            Icon(
                                              Icons.bookmark,
                                              color: Colors.orange.shade700,
                                              size: 18,
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.refresh),
                                            color: kGreen,
                                            tooltip: localizations.recheck,
                                            onPressed: () => _openResult(
                                              scan,
                                              recheck: true,
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
                                      onTap: () => _openResult(scan),
                                    ),
                                  ),
                                );
                              },
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? kGreen : Colors.grey.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
