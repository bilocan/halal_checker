import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app_colors.dart';
import '../../../config.dart';
import '../../../integration_test_keys.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../../../services/database_service.dart';
import '../../../services/ingredient_sanitizer.dart';
import '../../../services/ocr_service.dart';
import '../../../services/product_service.dart';
import '../../batch_scan_screen.dart';
import '../../home_screen.dart';
import '../../result_screen.dart';
import '../format_scan_date.dart';
import 'start_auth_app_bar_action.dart';
import 'start_filter_chip.dart';

/// Loads recent scans for the home tab (override in widget tests).
typedef LoadRecentScans = Future<List<Map<String, dynamic>>> Function();

/// Home tab: recent scans, scan actions, and locale/auth app bar.
class StartHomeTab extends StatefulWidget {
  const StartHomeTab({
    super.key,
    required this.canBatchImport,
    this.onLocaleChanged,
    ProductService? productService,
    this.loadRecentScans,
    this.enableSwipeToDelete = true,
  }) : _productService = productService;

  final bool canBatchImport;
  final ValueChanged<Locale>? onLocaleChanged;
  final ProductService? _productService;
  final LoadRecentScans? loadRecentScans;

  /// When false, list rows omit [Dismissible] (avoids timer hangs in widget tests).
  final bool enableSwipeToDelete;

  @override
  State<StartHomeTab> createState() => _StartHomeTabState();
}

class _StartHomeTabState extends State<StartHomeTab> {
  ProductService get _productService =>
      widget._productService ?? ProductService();

  List<Map<String, dynamic>> _recentScans = [];
  bool _isLoading = true;
  bool _isLoadingProduct = false;
  bool _showFlaggedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final scans = widget.loadRecentScans != null
        ? await widget.loadRecentScans!()
        : await DatabaseService.instance.getRecentScans();
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

  Future<void> _openBatchScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BatchScanScreen()),
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.startTitle),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              widget.onLocaleChanged?.call(Locale(value));
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
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.lastResults,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StartFilterChip(
                      label: loc.allScans,
                      selected: !_showFlaggedOnly,
                      onTap: () => setState(() => _showFlaggedOnly = false),
                    ),
                    const SizedBox(width: 8),
                    StartFilterChip(
                      label: loc.flaggedOnly,
                      selected: _showFlaggedOnly,
                      icon: Icons.bookmark,
                      onTap: () => setState(() => _showFlaggedOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildScanList(loc)),
                const SizedBox(height: 16),
                _buildActionButtons(loc),
                if (widget.canBatchImport) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openBatchScan,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(loc.batchImport),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kGreen,
                        side: const BorderSide(color: kGreenLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
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

  Future<void> _onScanDismissed(
    Map<String, dynamic> removed,
    String barcode,
    AppLocalizations loc,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _recentScans.removeWhere((s) => s['barcode'] == barcode));
    await DatabaseService.instance.deleteScan(barcode);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(loc.deletedFromHistory),
        action: SnackBarAction(
          label: loc.undo,
          onPressed: () async {
            await DatabaseService.instance.insertScan(
              barcode: removed['barcode'] as String,
              productName: removed['productName'] as String,
              isHalal: removed['isHalal'] as bool,
              notes: removed['notes'] as String?,
              isFlagged: removed['isFlagged'] as bool,
            );
            await _loadRecentScans();
          },
        ),
      ),
    );
  }

  Widget _buildScanList(AppLocalizations loc) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recentScans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              loc.noRecentResults,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.noRecentResultsHint,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final displayed = _showFlaggedOnly
        ? _recentScans.where((s) => s['isFlagged'] == true).toList()
        : _recentScans;

    if (displayed.isEmpty) {
      return Center(
        child: Text(
          loc.noRecentResults,
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

        final tile = Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Semantics(
              label: isHalal ? loc.halal : loc.notHalal,
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
              note != null && note.isNotEmpty
                  ? note.length > 50
                        ? '${note.substring(0, 50)}…'
                        : note
                  : '${loc.lastScanned}: ${formatScanDate(loc, scan['timestamp'] as int)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFlagged)
                  Icon(Icons.bookmark, color: Colors.orange.shade700, size: 18),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: kGreen,
                  tooltip: loc.recheck,
                  onPressed: () => _openResult(scan, recheck: true),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _openResult(scan),
          ),
        );

        if (!widget.enableSwipeToDelete) {
          return KeyedSubtree(key: ValueKey(barcode), child: tile);
        }

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
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => _onScanDismissed(scan, barcode, loc),
          child: tile,
        );
      },
    );
  }

  Widget _buildActionButtons(AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: Container(
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
              key: IntegrationTestKeys.startScan,
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
                    size: 36,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.scanButton,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: kGreenLight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: _analyzeIngredientsPhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 36),
                  const SizedBox(height: 6),
                  Text(
                    loc.photoIngredientsButton,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
