import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../config.dart';
import '../localization/app_localizations.dart';
import '../models/community.dart';
import '../models/product.dart';
import '../models/feedback.dart';
import '../models/product_analysis.dart';
import '../services/analysis_service.dart';
import '../services/cache_service.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../services/feedback_service.dart';
import '../services/database_service.dart';
import '../services/ingredient_contribution_service.dart';
import '../services/ingredient_sanitizer.dart';
import '../services/issue_report_service.dart';
import '../services/ocr_service.dart';
import '../services/product_image_service.dart';
import '../services/product_service.dart';
import 'deep_analysis_screen.dart';
import 'discussion_screen.dart';
import 'keywords_screen.dart';

class ResultScreen extends StatefulWidget {
  final Product? product;
  final String barcode;

  const ResultScreen({super.key, required this.product, required this.barcode});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  final ProductService _productService = ProductService();
  final AnalysisService _analysisService = AnalysisService();
  List<FeedbackItem> _feedbacks = [];
  bool _isLoadingFeedback = false;
  bool _isRefreshing = false;
  ProductImageType? _uploadingImageType;
  bool _showTranslated = false;
  String _note = '';
  bool _isFlagged = false;
  bool _noteExpanded = false;
  final _noteController = TextEditingController();

  ProductAnalysis? _analysis;
  bool _isRequestingAnalysis = false;
  List<Discussion> _discussions = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadFeedbacks(),
      _loadNote(),
      _loadAnalysis(),
      _loadDiscussions(),
    ]);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    final data = await DatabaseService.instance.getScanNote(widget.barcode);
    if (data != null && mounted) {
      setState(() {
        _note = data['notes'] as String? ?? '';
        _isFlagged = data['isFlagged'] as bool;
        _noteController.text = _note;
      });
    }
  }

  Future<void> _saveNote() async {
    final note = _noteController.text.trim();
    await DatabaseService.instance.updateScanNote(
      widget.barcode,
      note: note.isEmpty ? null : note,
      isFlagged: _isFlagged,
    );
    if (!mounted) return;
    setState(() => _note = note);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).noteSaved),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleFlag() async {
    final newFlag = !_isFlagged;
    setState(() => _isFlagged = newFlag);
    await DatabaseService.instance.updateScanNote(
      widget.barcode,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      isFlagged: newFlag,
    );
  }

  Future<void> _loadAnalysis() async {
    final a = await _analysisService.getAnalysis(widget.barcode);
    if (mounted) setState(() => _analysis = a);
  }

  Future<void> _loadDiscussions() async {
    final d = await CommunityService.getDiscussions(widget.barcode);
    if (mounted) setState(() => _discussions = d);
  }

  Future<void> _requestAnalysis() async {
    if (AuthService.currentUser == null) {
      _showSignInRequired(context);
      return;
    }
    setState(() => _isRequestingAnalysis = true);
    final result = await _analysisService.requestDeepAnalysis(
      widget.barcode,
      product: widget.product,
    );
    if (!mounted) return;
    setState(() {
      _isRequestingAnalysis = false;
      if (result != null) _analysis = result;
    });
    if (result != null && result.status != AnalysisStatus.pending) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeepAnalysisScreen(
            productName: widget.product?.name ?? widget.barcode,
            barcode: widget.barcode,
            analysis: result,
          ),
        ),
      );
    } else if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).analysisQueued),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).analysisFailed)),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _reportWithNote() {
    final product = widget.product;
    if (product == null) return;
    _showReportDialog(
      context,
      product,
      initialNote: _noteController.text.trim(),
    );
  }

  Widget _buildAnalysisCard() {
    final analysis = _analysis;
    final statusColor = switch (analysis?.status) {
      AnalysisStatus.resolved => Colors.green.shade700,
      AnalysisStatus.aiDone ||
      AnalysisStatus.communityReview ||
      AnalysisStatus.consulting => Colors.blue.shade700,
      AnalysisStatus.aiAnalyzing => Colors.orange.shade700,
      _ => Colors.purple.shade700,
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            analysis != null &&
                analysis.status != AnalysisStatus.pending &&
                analysis.status != AnalysisStatus.aiAnalyzing
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeepAnalysisScreen(
                    productName: widget.product?.name ?? widget.barcode,
                    barcode: widget.barcode,
                    analysis: analysis,
                  ),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.biotech, color: statusColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).deepAnalysis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      analysis == null
                          ? AppLocalizations.of(context).perIngredientAiAnalysis
                          : analysis.status.label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isRequestingAnalysis)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (analysis == null ||
                  analysis.status == AnalysisStatus.pending)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: _requestAnalysis,
                  child: Text(
                    AppLocalizations.of(context).analyse,
                    style: const TextStyle(fontSize: 13),
                  ),
                )
              else if (analysis.status == AnalysisStatus.aiAnalyzing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard() {
    final count = _discussions.length;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (AuthService.currentUser == null) {
            _showSignInRequired(context);
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DiscussionScreen(
                barcode: widget.barcode,
                productName: widget.product?.name ?? widget.barcode,
              ),
            ),
          );
          _loadDiscussions();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).communityDiscussion,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? AppLocalizations.of(context).noDiscussionsYet
                          : '$count discussion${count == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteSection(AppLocalizations loc) {
    final hasNote = _note.isNotEmpty;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _noteExpanded = !_noteExpanded),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.edit_note, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    loc.myNote,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasNote) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: kGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: _toggleFlag,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _isFlagged ? Icons.bookmark : Icons.bookmark_border,
                        color: _isFlagged
                            ? Colors.orange.shade700
                            : Colors.grey.shade500,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _noteExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _noteExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          maxLength: 300,
                          decoration: InputDecoration(
                            hintText: loc.noteHint,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _reportWithNote,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orange.shade700,
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.flag_outlined, size: 16),
                              label: Text(
                                loc.reportWrongResult,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _saveNote,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kGreen,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(loc.submit),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoadingFeedback = true);
    try {
      final feedbacks = await _feedbackService.getFeedbacksForBarcode(
        widget.barcode,
      );
      if (mounted) {
        setState(() => _feedbacks = feedbacks);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotLoadFeedback),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFeedback = false);
      }
    }
  }

  Future<void> _refreshProductData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      final refreshedProduct = await _productService.refreshProduct(
        widget.barcode,
      );
      if (refreshedProduct != null && mounted) {
        await DatabaseService.instance.insertScan(
          barcode: widget.barcode,
          productName: refreshedProduct.name,
          isHalal: refreshedProduct.isHalal,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              product: refreshedProduct,
              barcode: widget.barcode,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotRefreshProduct),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotRefreshProduct),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _showLocalDbDebug() async {
    final barcode = widget.barcode;
    final cacheRaw = await CacheService().getRaw(barcode);
    final dbProduct = await _productService.fetchFromSharedDbForDebug(barcode);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Local DB — $barcode'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '── SharedPreferences cache ──',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (cacheRaw == null)
                const Text('(empty)', style: TextStyle(color: Colors.grey))
              else
                _debugField('isHalal', _jsonField(cacheRaw, 'isHalal')),
              if (cacheRaw != null)
                _debugField('isUnknown', _jsonField(cacheRaw, 'isUnknown')),
              if (cacheRaw != null)
                _debugField('isManaged', _jsonField(cacheRaw, 'isManaged')),
              if (cacheRaw != null)
                _debugField(
                  'ingredients#',
                  _jsonListLen(cacheRaw, 'ingredients'),
                ),
              if (cacheRaw != null)
                _debugField('_cachedAt', _jsonField(cacheRaw, '_cachedAt')),
              const SizedBox(height: 12),
              const Text(
                '── Remote DB (products table) ──',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (dbProduct == null)
                const Text('(not found)', style: TextStyle(color: Colors.grey))
              else ...[
                _debugField('isHalal', '${dbProduct.isHalal}'),
                _debugField('isUnknown', '${dbProduct.isUnknown}'),
                _debugField('isManaged', '${dbProduct.isManaged}'),
                _debugField('ingredients#', '${dbProduct.ingredients.length}'),
                _debugField(
                  'ingredients',
                  dbProduct.ingredients.take(5).join(', '),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await CacheService().removeProduct(barcode);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
              }
            },
            child: const Text('Clear cache'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _debugField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontFamily: 'monospace',
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );

  static String _jsonField(String raw, String key) {
    try {
      final m = (jsonDecode(raw) as Map<String, dynamic>);
      return '${m[key]}';
    } catch (_) {
      return '?';
    }
  }

  static String _jsonListLen(String raw, String key) {
    try {
      final m = (jsonDecode(raw) as Map<String, dynamic>);
      final v = m[key];
      return v is List ? '${v.length}' : '?';
    } catch (_) {
      return '?';
    }
  }

  Future<void> _uploadProductImage(ProductImageType type) async {
    if (AuthService.currentUser == null) {
      _showSignInRequired(context);
      return;
    }
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
    } catch (e) {
      debugPrint('ImagePicker error ($source): $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.cameraError)));
      return;
    }
    if (photo == null || !mounted) return;

    setState(() => _uploadingImageType = type);
    final success = await ProductImageService.uploadImage(
      barcode: widget.barcode,
      imageFile: File(photo.path),
      type: type,
      productName: widget.product?.name,
    );
    if (!mounted) return;
    setState(() => _uploadingImageType = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? loc.photoUploaded : loc.photoUploadFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final product = widget.product;
    final barcode = widget.barcode;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.resultTitle),
          backgroundColor: kGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(loc.productNotFound, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(barcode, 'Barcode'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Barcode: $barcode',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.copy, size: 14, color: Colors.grey.shade400),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.scanAgain),
              ),
            ],
          ),
        ),
      );
    }

    final isHalal = product.isHalal;
    final isUnknown = product.isUnknown;
    final isNonFood = product.isNonFood;
    final ingredients = product.ingredients;
    final suspiciousIngredients = product.suspiciousIngredients;

    final bool requiresHalalCert = product.requiresHalalCert;
    final Color statusColor = isNonFood
        ? Colors.blueGrey.shade600
        : isUnknown
        ? Colors.orange.shade700
        : requiresHalalCert
        ? Colors.orange.shade700
        : (isHalal ? kGreen : Colors.red);
    final IconData statusIcon = isNonFood
        ? Icons.info_outline
        : isUnknown
        ? Icons.help_outline
        : requiresHalalCert
        ? Icons.warning_amber_outlined
        : (isHalal ? Icons.check_circle : Icons.cancel);
    final String statusLabel = isNonFood
        ? loc.nonFood
        : isUnknown
        ? loc.unknown
        : requiresHalalCert
        ? loc.noCert
        : (isHalal ? '✅ HALAL' : '❌ NOT HALAL');

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.resultTitle),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: _showLocalDbDebug,
              tooltip: 'Local DB debug',
            ),
          IconButton(
            icon: Icon(_isFlagged ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleFlag,
            tooltip: loc.checkLater,
          ),
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshProductData,
              tooltip: loc.refreshTooltip,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 64),
                    const SizedBox(height: 12),
                    Semantics(
                      label: statusLabel,
                      child: Text(
                        statusLabel,
                        semanticsLabel: '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.requiresHalalCert
                          ? loc.explanationNoCert
                          : product.explanation.isNotEmpty
                          ? product.explanation
                          : _halalReasonText(
                              isHalal,
                              isUnknown,
                              suspiciousIngredients,
                              loc,
                            ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            product.analyzedByAI
                                ? Icons.auto_awesome
                                : Icons.manage_search,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.analyzedByAI
                                ? loc.aiAnalysis
                                : loc.keywordAnalysis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (product.isManaged) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loc.managedProduct,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SelectableText(
                product.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(barcode, 'Barcode'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Barcode: $barcode',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.copy, size: 14, color: Colors.grey.shade400),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (product.labels.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildLabelChips(product.labels),
                ),
              if (product.labels.isNotEmpty) const SizedBox(height: 12),
              const SizedBox(height: 24),
              if (product.imageFrontUrl != null || product.imageUrl != null)
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildProductImage(product, loc),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _uploadingImageType == ProductImageType.front
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : GestureDetector(
                              onTap: () =>
                                  _uploadProductImage(ProductImageType.front),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Replace',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: _uploadingImageType == ProductImageType.front
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                loc.noProductImageAvailable,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _uploadProductImage(ProductImageType.front),
                                icon: const Icon(Icons.add_a_photo, size: 16),
                                label: Text(loc.uploadProductPhoto),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kGreen,
                                  side: const BorderSide(color: kGreen),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              const SizedBox(height: 24),
              if (!product.isNonFood) ...[
                Text(
                  loc.additionalImages,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildImageSlot(
                  product.imageIngredientsUrl,
                  loc.ingredients,
                  ProductImageType.ingredients,
                ),
                _buildImageSlot(
                  product.imageNutritionUrl,
                  loc.nutritionLabel,
                  ProductImageType.nutrition,
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Text(
                    loc.ingredients,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const Spacer(),
                  if (product.ingredientTranslations.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showTranslated = !_showTranslated),
                      icon: Icon(
                        _showTranslated ? Icons.language : Icons.translate,
                        size: 16,
                      ),
                      label: Text(
                        _showTranslated
                            ? 'Original'
                            : Localizations.localeOf(
                                context,
                              ).languageCode.toUpperCase(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  if (ingredients.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () => _copyToClipboard(
                        ingredients.join(', '),
                        'Ingredients',
                      ),
                      tooltip: 'Copy ingredients',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      color: Colors.grey.shade600,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (ingredients.isEmpty) ...[
                Text(
                  loc.noIngredientData,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildMissingIngredientActions(product, loc),
              ] else
                ...ingredients.map((ingredient) {
                  final warning = product.ingredientWarnings[ingredient];
                  final fattyAlcohol =
                      warning == null &&
                      ProductService.isFattyAlcohol(ingredient);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        warning != null
                            ? Icons.warning
                            : fattyAlcohol
                            ? Icons.info_outline
                            : Icons.check_circle_outline,
                        color: warning != null
                            ? Colors.red
                            : fattyAlcohol
                            ? Colors.blue.shade400
                            : kGreen,
                      ),
                      title: _ingredientTitle(
                        ingredient,
                        product.ingredientTranslations[ingredient],
                        showTranslated: _showTranslated,
                      ),
                      subtitle: warning != null
                          ? Text(warning)
                          : fattyAlcohol
                          ? Text(
                              loc.fattyAlcoholNote,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      dense: true,
                    ),
                  );
                }),
              if (!isHalal) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.flaggedIngredients,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...product.haramIngredients.map((e) {
                  final warning = product.ingredientWarnings[e];
                  return ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: _ingredientTitle(
                      e,
                      product.ingredientTranslations[e],
                      showTranslated: _showTranslated,
                    ),
                    subtitle: Text(warning ?? loc.foundInIngredients),
                    dense: true,
                  );
                }),
              ],
              if (suspiciousIngredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.mayBeAnimalDerived,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...suspiciousIngredients.map((e) {
                  final warning = product.ingredientWarnings[e];
                  return ListTile(
                    leading: Icon(Icons.warning, color: Colors.orange.shade600),
                    title: _ingredientTitle(
                      e,
                      product.ingredientTranslations[e],
                      showTranslated: _showTranslated,
                    ),
                    subtitle: Text(warning ?? loc.mayBeAnimalDerivedNote),
                    dense: true,
                  );
                }),
              ],
              const SizedBox(height: 16),
              _buildTransparencySection(product, loc),
              const SizedBox(height: 16),
              _buildNoteSection(loc),
              const SizedBox(height: 16),
              _buildAnalysisCard(),
              const SizedBox(height: 8),
              _buildCommunityCard(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.communityFeedback,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoadingFeedback)
                const Center(child: CircularProgressIndicator())
              else if (_feedbacks.isEmpty)
                Text(
                  loc.noFeedbackYet,
                  style: const TextStyle(color: Colors.grey),
                )
              else
                ..._feedbacks.map(
                  (feedback) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                loc.userFeedback,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(feedback.submittedAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(feedback.userFeedback),
                          if (feedback.attachments.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: feedback.attachments
                                  .map(
                                    (attachment) => Chip(
                                      label: Text(
                                        '📎 ${attachment.split(RegExp(r'[/\\]')).last}',
                                      ),
                                      backgroundColor: Colors.blue.shade50,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          if (feedback.producerReply != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kGreenSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kGreenLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.business,
                                        size: 16,
                                        color: kGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        loc.producerReply,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kGreenMid,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        feedback.repliedAt != null
                                            ? _formatDate(feedback.repliedAt!)
                                            : '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(feedback.producerReply!),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _showProducerReplyDialog(feedback.id),
                                icon: const Icon(Icons.reply, size: 16),
                                label: Text(loc.replyAsProducer),
                                style: TextButton.styleFrom(
                                  foregroundColor: kGreenMid,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
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
                  onPressed: () => _onFeedbackTap(context),
                  child: Text(
                    loc.provideFeedback,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _showReportDialog(context, product),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(
                    loc.reportWrongResult,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ingredientTitle(
    String ingredient,
    String? canonical, {
    bool showTranslated = false,
  }) {
    if (canonical == null) return Text(ingredient);
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[-\s]'), '');
    final locale = Localizations.localeOf(context).languageCode;
    final display = ProductService.canonicalDisplay(canonical, locale);
    if (norm(ingredient).contains(norm(display))) return Text(ingredient);
    if (showTranslated) return Text(display);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: ingredient),
          TextSpan(
            text: '  ($display)',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransparencySection(Product product, AppLocalizations loc) {
    Widget summaryRow(IconData icon, String label, String value, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade900,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final explanation = product.requiresHalalCert
        ? loc.explanationNoCert
        : product.explanation.isNotEmpty
        ? product.explanation
        : _halalReasonText(
            product.isHalal,
            product.isUnknown,
            product.suspiciousIngredients,
            loc,
          );
    final resultLabel = product.isNonFood
        ? loc.nonFood
        : product.isUnknown
        ? loc.unknown
        : product.requiresHalalCert
        ? loc.noCert
        : product.isHalal
        ? loc.halal
        : loc.notHalal;
    final checkedText = product.ingredients.isEmpty
        ? loc.transparentNoIngredients
        : '${product.ingredients.length} ${loc.ingredients.toLowerCase()}';
    final flaggedText = product.haramIngredients.isEmpty
        ? loc.transparentNoMatches
        : product.haramIngredients.join(', ');
    final suspiciousText = product.suspiciousIngredients.isEmpty
        ? loc.transparentNoMatches
        : product.suspiciousIngredients.join(', ');

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(
          loc.analysisTransparency,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        leading: const Icon(Icons.visibility_outlined),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.transparentSummary,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                summaryRow(
                  Icons.fact_check_outlined,
                  loc.transparentResult,
                  resultLabel,
                  product.isHalal ? kGreen : Colors.red.shade600,
                ),
                summaryRow(
                  Icons.format_list_bulleted,
                  loc.transparentIngredientsChecked,
                  checkedText,
                  Colors.blueGrey.shade600,
                ),
                summaryRow(
                  Icons.rule,
                  loc.transparentRulesChecked,
                  product.ingredients.isEmpty
                      ? loc.transparentRulesAvailable(
                          ProductService.keywordRuleCount,
                        )
                      : ProductService.keywordRuleCount.toString(),
                  Colors.blueGrey.shade600,
                ),
                summaryRow(
                  Icons.error_outline,
                  loc.transparentFlagged,
                  flaggedText,
                  Colors.red.shade600,
                ),
                summaryRow(
                  Icons.warning_amber,
                  loc.transparentSuspicious,
                  suspiciousText,
                  Colors.orange.shade700,
                ),
                summaryRow(
                  Icons.notes_outlined,
                  loc.transparentExplanation,
                  explanation,
                  Colors.grey.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KeywordsScreen()),
              ),
              icon: const Icon(Icons.list_alt_outlined),
              label: Text(loc.viewAllCheckedKeywords),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.transparencyNote,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _thumbnailUrl(String url) => url.replaceAll('.400.', '.200.');

  void _showFullscreenImage(String url, {String? label}) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 6.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, _) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 12,
              child: SafeArea(
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
            if (label != null)
              Positioned(
                bottom: 32,
                left: 16,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product, AppLocalizations loc) {
    final imageUrls = [
      product.imageFrontUrl,
      product.imageUrl,
    ].where((url) => url != null && url.isNotEmpty).cast<String>().toList();

    if (imageUrls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              loc.imageNotAvailable,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullscreenImage(imageUrls.first),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _thumbnailUrl(imageUrls.first),
            fit: BoxFit.contain,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) {
              if (imageUrls.length > 1) {
                return GestureDetector(
                  onTap: () => _showFullscreenImage(imageUrls[1]),
                  child: CachedNetworkImage(
                    imageUrl: _thumbnailUrl(imageUrls[1]),
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.imageNotAvailable,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.imageNotAvailable,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
          const Positioned(
            bottom: 8,
            right: 8,
            child: Icon(Icons.zoom_in, color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlot(String? url, String label, ProductImageType type) {
    debugPrint('[ImageSlot] $label → url=$url');
    if (url != null) {
      return Stack(
        children: [
          _buildLabelledImage(url, label),
          Positioned(
            bottom: 18,
            right: 8,
            child: _uploadingImageType == type
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : GestureDetector(
                    onTap: () => _uploadProductImage(type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'Replace',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () => _uploadProductImage(type),
      child: Container(
        width: double.infinity,
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade50,
        ),
        child: Center(
          child: _uploadingImageType == type
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      color: Colors.grey.shade400,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLabelledImage(String imageUrl, String label) {
    return GestureDetector(
      onTap: () => _showFullscreenImage(imageUrl, label: label),
      child: Container(
        width: double.infinity,
        height: 150,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: _thumbnailUrl(imageUrl),
                fit: BoxFit.contain,
                width: double.infinity,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  debugPrint('[Image] failed to load: $url — $error');
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const Positioned(
                bottom: 8,
                right: 8,
                child: Icon(Icons.zoom_in, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLabelChips(List<String> rawLabels) {
    final lowerLabels = rawLabels.map((l) => l.toLowerCase()).toList();
    final normalized = <String>{};

    if (lowerLabels.any((l) => l.contains('vegan'))) {
      normalized.add('Vegan');
    } else if (lowerLabels.any((l) => l.contains('vegetarian'))) {
      normalized.add('Vegetarian');
    }
    if (lowerLabels.any(
      (l) =>
          l.contains('fair trade') ||
          l.contains('fair-trade') ||
          l.contains('fairtrade'),
    )) {
      normalized.add('Fair Trade');
    }
    if (lowerLabels.any((l) => l.contains('organic'))) {
      normalized.add('Organic');
    }
    if (lowerLabels.any(
      (l) =>
          l.contains('gluten free') ||
          l.contains('gluten-free') ||
          l.contains('glutenfree'),
    )) {
      normalized.add('Gluten Free');
    }

    return normalized.map(_buildLabelChip).whereType<Widget>().toList();
  }

  Widget? _buildLabelChip(String label) {
    switch (label) {
      case 'Vegan':
        return Chip(
          avatar: const Icon(Icons.eco, size: 18, color: kGreen),
          label: const Text('Vegan'),
          backgroundColor: kGreenSurface,
        );
      case 'Vegetarian':
        return Chip(
          avatar: const Icon(Icons.grass, size: 18, color: kGreen),
          label: const Text('Vegetarian'),
          backgroundColor: kGreenSurface,
        );
      case 'Fair Trade':
        return Chip(
          avatar: const Icon(Icons.handshake, size: 18, color: Colors.brown),
          label: const Text('Fair Trade'),
          backgroundColor: Colors.brown.shade50,
        );
      case 'Organic':
        return Chip(
          avatar: const Icon(Icons.spa, size: 18, color: Colors.teal),
          label: const Text('Organic'),
          backgroundColor: Colors.teal.shade50,
        );
      case 'Gluten Free':
        return Chip(
          avatar: const Icon(
            Icons.health_and_safety,
            size: 18,
            color: Colors.orange,
          ),
          label: const Text('Gluten Free'),
          backgroundColor: Colors.orange.shade50,
        );
      default:
        return null;
    }
  }

  Widget _buildMissingIngredientActions(Product product, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Contribute ingredients card
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.contributeIngredients,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loc.contributeIngredientsHint,
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(loc.contributeIngredients),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        _showContributeIngredientsDialog(context, product, loc),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // OpenFoodFacts deep link
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.open_in_new, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.improveOnOpenFoodFacts,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  loc.improveOnOpenFoodFactsHint,
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(loc.improveOnOpenFoodFacts),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://world.openfoodfacts.org/cgi/product.pl'
                        '?type=edit&code=${product.barcode}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Picks an image outside the bottom sheet (avoids Android ActivityResult issues),
  // runs OCR, then reopens the contribution dialog with the result.
  Future<void> _pickImageAndContribute(
    BuildContext context,
    Product product,
    AppLocalizations loc,
    ImageSource source,
  ) async {
    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(source: source, imageQuality: 85);
    } catch (e) {
      debugPrint('ImagePicker error ($source): $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera ? loc.cameraError : loc.ocrFailed,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (photo == null || !context.mounted) return;

    final file = File(photo.path);

    // Show loading overlay while OCR runs.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    final text = await OcrService.extractIngredientsFromFile(file);
    debugPrint(
      'OCR result: ${text == null ? "null" : "${text.length} chars: ${text.substring(0, text.length.clamp(0, 120))}"}',
    );

    if (!context.mounted) return;
    Navigator.pop(context); // close loading overlay

    // Show snackbar before reopening the sheet so it surfaces above it.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text != null && text.isNotEmpty ? loc.ocrSuccess : loc.ocrFailed,
        ),
        duration: Duration(seconds: text != null && text.isNotEmpty ? 3 : 5),
      ),
    );

    if (!context.mounted) return;

    // Reopen the dialog pre-filled with the picked photo and OCR result.
    _showContributeIngredientsDialog(
      context,
      product,
      loc,
      initialPreviewFile: file,
      initialOcrText: text,
    );
  }

  void _showContributeIngredientsDialog(
    BuildContext context,
    Product product,
    AppLocalizations loc, {
    File? initialPreviewFile,
    String? initialOcrText,
  }) {
    final initSections = initialOcrText != null
        ? IngredientSanitizer.sanitizeByLanguage(initialOcrText)
        : <String, List<String>>{};
    var rawOcrSections = initSections;
    var selectedLangs = initSections.keys.toSet();

    List<String> chipsFromSections() => [
      for (final l in rawOcrSections.keys)
        if (selectedLangs.contains(l)) ...rawOcrSections[l]!,
    ];

    var chips = selectedLangs.isEmpty ? <String>[] : chipsFromSections();
    final addController = TextEditingController();
    var isLoading = false;
    var isExtracting = false;
    File? previewFile = initialPreviewFile;
    String? previewUrl;

    Future<void> runOcrOnUrl(
      String url,
      StateSetter setSheetState,
      BuildContext ctx,
    ) async {
      if (ctx.mounted) setSheetState(() => isExtracting = true);
      final text = await OcrService.extractIngredientsFromImage(url);
      if (!context.mounted) return;
      if (ctx.mounted) {
        setSheetState(() => isExtracting = false);
        if (text != null && text.isNotEmpty) {
          final sections = IngredientSanitizer.sanitizeByLanguage(text);
          setSheetState(() {
            rawOcrSections = sections;
            selectedLangs = sections.keys.toSet();
            chips = chipsFromSections();
            addController.clear();
          });
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text != null && text.isNotEmpty
                ? loc.ocrSuccess
                : loc.ocrNoIngredientsFound,
          ),
          duration: Duration(seconds: text != null && text.isNotEmpty ? 3 : 5),
        ),
      );
    }

    final offImages = _candidateImageUrls(product);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    loc.contributeIngredients,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                loc.contributeIngredientsHint,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // OpenFoodFacts product images — tappable thumbnails
              if (offImages.isNotEmpty) ...[
                Text(
                  loc.productImages,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: offImages.map((url) {
                      final selected = previewUrl == url && previewFile == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: isExtracting || isLoading
                              ? null
                              : () async {
                                  setSheetState(() {
                                    previewUrl = url;
                                    previewFile = null;
                                  });
                                  await runOcrOnUrl(url, setSheetState, ctx);
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 80,
                                  width: 80,
                                  color: Colors.grey.shade200,
                                ),
                                errorWidget: (context, url, e) => Container(
                                  height: 80,
                                  width: 80,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Preview — shown after any selection (OFF image, gallery, or camera)
              if (previewFile != null || previewUrl != null) ...[
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding: EdgeInsets.zero,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 6,
                        child: previewFile != null
                            ? Image.file(previewFile!, fit: BoxFit.contain)
                            : CachedNetworkImage(
                                imageUrl: previewUrl!,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: previewFile != null
                            ? Image.file(
                                previewFile!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              )
                            : CachedNetworkImage(
                                imageUrl: previewUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.zoom_in,
                          color: Colors.white.withValues(alpha: 0.8),
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Gallery picker — lets user pick an existing photo from device
              OutlinedButton.icon(
                icon: isExtracting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library, size: 18),
                label: Text(
                  isExtracting
                      ? loc.extractingIngredients
                      : loc.extractFromExistingImage,
                ),
                onPressed: isExtracting || isLoading
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _pickImageAndContribute(
                          context,
                          product,
                          loc,
                          ImageSource.gallery,
                        );
                      },
              ),
              const SizedBox(height: 8),
              // Camera capture — take photo of ingredients label
              OutlinedButton.icon(
                icon: isExtracting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt, size: 18),
                label: Text(
                  isExtracting
                      ? loc.extractingIngredients
                      : loc.takePhotoOfIngredients,
                ),
                onPressed: isExtracting || isLoading
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _pickImageAndContribute(
                          context,
                          product,
                          loc,
                          ImageSource.camera,
                        );
                      },
              ),
              const SizedBox(height: 12),
              // ── Language selector (shown after OCR with multiple sections) ──
              if (rawOcrSections.length > 1) ...[
                const SizedBox(height: 4),
                Text(
                  'Language',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: rawOcrSections.keys.map((lang) {
                    return FilterChip(
                      label: Text(IngredientSanitizer.langDisplayName(lang)),
                      selected: selectedLangs.contains(lang),
                      selectedColor: Colors.orange.shade100,
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) {
                            selectedLangs.add(lang);
                          } else {
                            selectedLangs.remove(lang);
                          }
                          chips = chipsFromSections();
                          addController.clear();
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              // ── Ingredient chips ──────────────────────────────────────
              if (chips.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No ingredients added yet.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: chips.asMap().entries.map((entry) {
                    return InputChip(
                      label: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 13),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          setSheetState(() => chips.removeAt(entry.key)),
                      // Tap opens a dialog — no scroll needed, no data lost.
                      onPressed: () {
                        final editCtrl = TextEditingController(
                          text: chips[entry.key],
                        );
                        showDialog<void>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: const Text('Edit ingredient'),
                            content: TextField(
                              controller: editCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) {
                                final v = editCtrl.text.trim();
                                setSheetState(() {
                                  if (v.isEmpty) {
                                    chips.removeAt(entry.key);
                                  } else {
                                    chips[entry.key] = v;
                                  }
                                });
                                Navigator.pop(dialogCtx);
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  final v = editCtrl.text.trim();
                                  setSheetState(() {
                                    if (v.isEmpty) {
                                      chips.removeAt(entry.key);
                                    } else {
                                      chips[entry.key] = v;
                                    }
                                  });
                                  Navigator.pop(dialogCtx);
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              // ── Add ingredient row ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: addController,
                      decoration: InputDecoration(
                        hintText: loc.ingredientTextHint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (v) {
                        final parts = v
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        if (parts.isEmpty) return;
                        setSheetState(() {
                          chips.addAll(parts);
                          addController.clear();
                        });
                      },
                      onChanged: (v) {
                        if (!v.contains(',')) return;
                        final parts = v
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        if (parts.isEmpty) return;
                        setSheetState(() {
                          chips.addAll(parts);
                          addController.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isExtracting || isLoading
                        ? null
                        : () {
                            final parts = addController.text
                                .split(',')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList();
                            if (parts.isEmpty) return;
                            setSheetState(() {
                              chips.addAll(parts);
                              addController.clear();
                            });
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(loc.submit),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading || isExtracting
                    ? null
                    : () async {
                        if (chips.isEmpty) return;
                        final text = chips.join(', ');
                        setSheetState(() => isLoading = true);
                        final ok =
                            await IngredientContributionService.submitIngredients(
                              barcode: product.barcode,
                              ingredientText: text,
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? loc.ingredientSubmitted
                                  : loc.ingredientSubmitFailed,
                            ),
                          ),
                        );
                        if (ok) _refreshProductData();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _candidateImageUrls(Product product) {
    final urls = <String>[];
    if (product.imageIngredientsUrl != null) {
      urls.add(product.imageIngredientsUrl!);
    }
    if (product.imageFrontUrl != null &&
        !urls.contains(product.imageFrontUrl)) {
      urls.add(product.imageFrontUrl!);
    }
    if (product.imageUrl != null && !urls.contains(product.imageUrl)) {
      urls.add(product.imageUrl!);
    }
    return urls;
  }

  String _halalReasonText(
    bool isHalal,
    bool isUnknown,
    List<String> suspiciousIngredients,
    AppLocalizations loc,
  ) {
    if (isUnknown) return loc.explanationUnknown;
    if (isHalal) {
      return suspiciousIngredients.isEmpty
          ? loc.explanationClean
          : loc.explanationSuspiciousOnlyWith(suspiciousIngredients);
    }
    return loc.explanationHaram;
  }

  String _formatDate(DateTime date) {
    final loc = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return loc.today;
    if (difference.inDays == 1) return loc.yesterday;
    if (difference.inDays < 7) return loc.daysAgo(difference.inDays);

    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _onFeedbackTap(BuildContext context) {
    if (AppConfig.hasSupabase && AuthService.currentUser == null) {
      _showSignInRequired(context);
      return;
    }
    _showFeedbackDialog(context);
  }

  void _showSignInRequired(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: kGreen),
            const SizedBox(height: 16),
            const Text(
              'Sign in required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You need to be signed in to submit feedback or suggestions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final success = await AuthService.signInWithGoogle();
                    if (!context.mounted) return;
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sign-in failed. Please try again.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (_) {}
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFeedbackDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final TextEditingController feedbackController = TextEditingController();
    final List<String> selectedFiles = [];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(loc.provideFeedback),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.feedbackDialogHint,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  maxLength: 500,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: loc.feedbackInputHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                          );
                          if (result != null) {
                            setDialogState(() {
                              selectedFiles.addAll(
                                result.files
                                    .map((f) => f.path)
                                    .whereType<String>(),
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: Text(loc.attachFiles),
                      ),
                    ),
                  ],
                ),
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: selectedFiles
                        .map(
                          (file) => Chip(
                            label: Text(file.split(RegExp(r'[/\\]')).last),
                            onDeleted: () => setDialogState(
                              () => selectedFiles.remove(file),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: feedbackController.text.trim().isEmpty
                  ? null
                  : () async {
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _feedbackService.addFeedback(
                          widget.barcode,
                          feedbackController.text.trim(),
                          attachments: selectedFiles,
                        );
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(content: Text(loc.thankYouFeedback)),
                        );
                        await _loadFeedbacks();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(loc.couldNotSubmitFeedback)),
                        );
                      }
                    },
              child: Text(loc.submit),
            ),
          ],
        ),
      ),
    );
    feedbackController.dispose();
  }

  Future<void> _showProducerReplyDialog(String feedbackId) async {
    final loc = AppLocalizations.of(context);

    // Warn users that producer replies are unverified before proceeding.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.producerReplyWarningTitle),
        content: Text(loc.producerReplyWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.proceedAnyway),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final TextEditingController replyController = TextEditingController();

    // Use ValueListenableBuilder instead of StatefulBuilder + addListener to
    // avoid accumulating duplicate listeners on every rebuild.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.replyAsProducer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.replyDialogHint, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: loc.replyInputHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: replyController,
            builder: (_, value, _) => ElevatedButton(
              onPressed: value.text.trim().isEmpty
                  ? null
                  : () async {
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _feedbackService.addProducerReply(
                          feedbackId,
                          replyController.text.trim(),
                        );
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(content: Text(loc.replySubmitted)),
                        );
                        await _loadFeedbacks();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(loc.couldNotSubmitReply)),
                        );
                      }
                    },
              child: Text(loc.submitReply),
            ),
          ),
        ],
      ),
    );
    replyController.dispose();
  }

  void _showReportDialog(
    BuildContext context,
    Product product, {
    String initialNote = '',
  }) {
    final String currentResult = product.isNonFood
        ? 'non_food'
        : product.isUnknown
        ? 'unknown'
        : product.isHalal
        ? 'halal'
        : 'haram';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReportSheet(
        barcode: widget.barcode,
        productName: product.name,
        currentResult: currentResult,
        initialNote: initialNote,
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  final String barcode;
  final String productName;
  final String currentResult;
  final String initialNote;

  const _ReportSheet({
    required this.barcode,
    required this.productName,
    required this.currentResult,
    this.initialNote = '',
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ExpectedResult? _selected;
  late final _noteController = TextEditingController(text: widget.initialNote);
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _currentLabel(AppLocalizations loc) {
    switch (widget.currentResult) {
      case 'halal':
        return loc.reportResultHalal;
      case 'haram':
        return loc.reportResultHaram;
      case 'non_food':
        return loc.reportResultNonFood;
      default:
        return loc.reportResultUnknown;
    }
  }

  Color _currentColor() {
    switch (widget.currentResult) {
      case 'halal':
        return kGreen;
      case 'haram':
        return Colors.red;
      case 'non_food':
        return Colors.blueGrey.shade600;
      default:
        return Colors.orange.shade700;
    }
  }

  Future<void> _submit(AppLocalizations loc) async {
    if (_selected == null) return;
    setState(() => _submitting = true);
    final result = await IssueReportService.reportWrongResult(
      barcode: widget.barcode,
      productName: widget.productName,
      currentResult: widget.currentResult,
      expectedResult: _selected!,
      note: _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? loc.reportSubmitted : loc.reportFailed),
        backgroundColor: result.success ? kGreen : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final options = [
      (ExpectedResult.halal, loc.reportResultHalal, kGreen),
      (ExpectedResult.haram, loc.reportResultHaram, Colors.red),
      (
        ExpectedResult.nonFood,
        loc.reportResultNonFood,
        Colors.blueGrey.shade600,
      ),
      (ExpectedResult.unknown, loc.reportResultUnknown, Colors.orange.shade700),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.reportWrongResultTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            loc.reportWrongResultSubtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            '${loc.currentResultLabel}:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _currentColor().withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _currentColor().withAlpha(100)),
            ),
            child: Text(
              _currentLabel(loc),
              style: TextStyle(
                color: _currentColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${loc.expectedResultLabel}:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final (value, label, color) = opt;
              final isSelected = _selected == value;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => setState(() => _selected = value),
                selectedColor: color,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: loc.optionalNote,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selected == null || _submitting)
                  ? null
                  : () => _submit(loc),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.orange.shade200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      loc.reportWrongResult,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
