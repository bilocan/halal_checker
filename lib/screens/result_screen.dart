import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_colors.dart';
import '../config.dart';
import '../localization/app_localizations.dart';
import '../models/product.dart';
import '../models/product_analysis.dart';
import '../services/auth_service.dart';
import '../utils/image_crop_helper.dart';
import '../services/feedback_service.dart';
import '../services/product_image_service.dart';
import '../widgets/feedback_dialog.dart';
import '../widgets/report_sheets.dart';
import '../widgets/sign_in_sheet.dart';
import 'admin_panel_screen.dart';
import 'deep_analysis_screen.dart';
import 'discussion_screen.dart';
import 'missing_product_photo_contribution_screen.dart';
import 'result/debug/local_db_debug_dialog.dart';
import 'result/result_controller.dart';
import 'result/widgets/result_analysis_card.dart';
import 'result/widgets/result_bottom_nav.dart';
import 'result/widgets/result_community_card.dart';
import 'result/widgets/result_feedback_section.dart';
import 'result/widgets/result_footer_actions.dart';
import 'result/widgets/result_ingredients_section.dart';
import 'result/widgets/result_not_found_body.dart';
import 'result/widgets/result_note_card.dart';
import 'result/widgets/result_product_header.dart';
import 'result/widgets/result_product_images.dart';
import 'result/widgets/result_status_banner.dart';
import 'result/widgets/result_transparency_card.dart';

class ResultScreen extends StatefulWidget {
  final Product? product;
  final String barcode;
  final List<String>? adminReportedIngredients;
  final String? adminReportExplanation;

  const ResultScreen({
    super.key,
    required this.product,
    required this.barcode,
    this.adminReportedIngredients,
    this.adminReportExplanation,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final ResultController _controller;
  final FeedbackService _feedbackService = FeedbackService();
  ProductImageType? _uploadingImageType;
  bool _showTranslated = false;
  bool _noteExpanded = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ResultController(
      barcode: widget.barcode,
      product: widget.product,
    );
    _controller.loadAll().then((_) {
      if (!mounted) return;
      _noteController.text = _controller.note;
      if (_controller.feedbackLoadFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).couldNotLoadFeedback),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).labelCopied(label)),
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

  Future<void> _saveNote() async {
    await _controller.saveNote(_noteController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).noteSaved),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleFlag() async {
    await _controller.toggleFlag(_noteController.text);
  }

  Future<void> _requestAiIngredients() async {
    if (AuthService.currentUser == null) {
      await showSignInRequiredSheet(context);
      return;
    }
    final submitted = await _controller.requestAiIngredients();
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    if (submitted == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.aiRequestSubmitFailed)));
      return;
    }
    final refreshed = _controller.aiRefreshedProduct;
    if (refreshed != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.adminAiRefetching(widget.barcode)),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(product: refreshed, barcode: widget.barcode),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          submitted ? loc.aiRequestSubmitted : loc.aiRequestAlreadyPending,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _refreshProductData() async {
    final refreshed = await _controller.refreshProduct();
    if (!mounted) return;
    if (refreshed != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(product: refreshed, barcode: widget.barcode),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).couldNotRefreshProduct),
        ),
      );
    }
  }

  Future<void> _requestAnalysis() async {
    if (AuthService.currentUser == null) {
      await showSignInRequiredSheet(context);
      return;
    }
    final loc = AppLocalizations.of(context);
    final result = await _controller.requestDeepAnalysis();
    if (!mounted) return;
    if (result != null &&
        result.status != AnalysisStatus.pending &&
        result.status != AnalysisStatus.aiAnalyzing) {
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
          content: Text(loc.analysisQueued),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.analysisFailed)));
    }
  }

  void _openDeepAnalysis() {
    final analysis = _controller.analysis;
    if (analysis == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeepAnalysisScreen(
          productName: widget.product?.name ?? widget.barcode,
          barcode: widget.barcode,
          analysis: analysis,
        ),
      ),
    );
  }

  Future<void> _openMissingProductPhotoFlow() async {
    if (!AppConfig.hasSupabase) return;
    if (AuthService.currentUser == null) {
      await showSignInRequiredSheet(context);
      if (!mounted) return;
      await AuthService.ensureInitialized();
      if (AuthService.currentUser == null) return;
    }
    if (!mounted) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) =>
            MissingProductPhotoContributionScreen(barcode: widget.barcode),
      ),
    );
    if (!mounted || ok != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).missingProductThankYou),
      ),
    );
  }

  Future<void> _uploadProductImage(ProductImageType type) async {
    if (AuthService.currentUser == null) {
      await showSignInRequiredSheet(context);
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

    photo = await maybeCropImage(context, photo);
    if (!mounted) return;
    final photoFile = File(photo.path);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(photoFile, fit: BoxFit.contain),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.submit),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _uploadingImageType = type);
    final success = await ProductImageService.uploadImage(
      barcode: widget.barcode,
      imageFile: photoFile,
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

  Future<void> _openDiscussion() async {
    if (AuthService.currentUser == null) {
      await showSignInRequiredSheet(context);
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
    await _controller.loadDiscussions();
  }

  Widget _buildBottomNav(AppLocalizations loc) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, _) => ResultBottomNav(
        loc: loc,
        isAdmin: _controller.isAdmin,
        onHome: () => Navigator.pop(context),
        onAdmin: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final product = widget.product;
    final barcode = widget.barcode;
    final languageCode = Localizations.localeOf(context).languageCode;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.resultTitle),
          backgroundColor: kGreen,
          foregroundColor: Colors.white,
        ),
        body: ResultNotFoundBody(
          barcode: barcode,
          loc: loc,
          onCopyBarcode: () => _copyToClipboard(barcode, loc.barcodeLabel),
          onScanAgain: () => Navigator.pop(context),
          onSubmitPackPhotos: AppConfig.hasSupabase
              ? _openMissingProductPhotoFlow
              : null,
        ),
        bottomNavigationBar: _buildBottomNav(loc),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.resultTitle),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => showLocalDbDebugDialog(
                context: context,
                barcode: barcode,
                productService: _controller.productService,
              ),
              tooltip: loc.localDbDebugTooltip,
            ),
          ListenableBuilder(
            listenable: _controller,
            builder: (_, _) => IconButton(
              icon: Icon(
                _controller.isFlagged ? Icons.bookmark : Icons.bookmark_border,
              ),
              onPressed: _toggleFlag,
              tooltip: loc.checkLater,
            ),
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (_, _) {
              if (_controller.isRefreshing) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshProductData,
                tooltip: loc.refreshTooltip,
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  ResultStatusBanner(product: product, loc: loc),
                  const SizedBox(height: 24),
                  ResultProductHeader(
                    product: product,
                    barcode: barcode,
                    onCopyBarcode: () =>
                        _copyToClipboard(barcode, loc.barcodeLabel),
                  ),
                  const SizedBox(height: 24),
                  ResultProductImages(
                    product: product,
                    loc: loc,
                    uploadingImageType: _uploadingImageType,
                    onUpload: _uploadProductImage,
                  ),
                  const SizedBox(height: 24),
                  ResultIngredientsSection(
                    product: product,
                    loc: loc,
                    showTranslated: _showTranslated,
                    languageCode: languageCode,
                    onToggleTranslation: () =>
                        setState(() => _showTranslated = !_showTranslated),
                    onCopyIngredients: () => _copyToClipboard(
                      product.ingredients.join(', '),
                      loc.ingredients,
                    ),
                    onReportIngredient: () =>
                        _showIngredientReportSheet(context, product),
                    adminReportedIngredients: widget.adminReportedIngredients,
                    adminReportExplanation: widget.adminReportExplanation,
                    aiRequestStatus: _controller.aiRequestStatus,
                    isFetchingAiIngredients:
                        _controller.isFetchingAiIngredients,
                    onRequestAiIngredients: _requestAiIngredients,
                    onRefreshProduct: _refreshProductData,
                  ),
                  const SizedBox(height: 16),
                  ResultTransparencyCard(product: product, loc: loc),
                  const SizedBox(height: 16),
                  ResultNoteCard(
                    loc: loc,
                    note: _controller.note,
                    isFlagged: _controller.isFlagged,
                    isExpanded: _noteExpanded,
                    noteController: _noteController,
                    onToggleExpanded: () =>
                        setState(() => _noteExpanded = !_noteExpanded),
                    onToggleFlag: _toggleFlag,
                    onSave: _saveNote,
                    onReportWithNote: _reportWithNote,
                  ),
                  const SizedBox(height: 16),
                  ResultAnalysisCard(
                    loc: loc,
                    analysis: _controller.analysis,
                    isRequesting: _controller.isRequestingAnalysis,
                    onRequest: _requestAnalysis,
                    onOpenAnalysis: _openDeepAnalysis,
                  ),
                  const SizedBox(height: 8),
                  ResultCommunityCard(
                    loc: loc,
                    discussionCount: _controller.discussions.length,
                    onTap: _openDiscussion,
                  ),
                  const SizedBox(height: 16),
                  ResultFeedbackSection(
                    loc: loc,
                    feedbacks: _controller.feedbacks,
                    isLoading: _controller.isLoadingFeedback,
                    onProducerReply: _showProducerReplyDialog,
                  ),
                  const SizedBox(height: 24),
                  ResultFooterActions(
                    loc: loc,
                    onScanAnother: () => Navigator.pop(context),
                    onFeedback: () => _onFeedbackTap(context),
                    onReport: () => _showReportDialog(context, product),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(loc),
    );
  }

  void _onFeedbackTap(BuildContext context) {
    if (AppConfig.hasSupabase && AuthService.currentUser == null) {
      showSignInRequiredSheet(context);
      return;
    }
    showFeedbackDialog(
      context: context,
      barcode: widget.barcode,
      feedbackService: _feedbackService,
      onSubmitted: _controller.loadFeedbacks,
    );
  }

  Future<void> _showProducerReplyDialog(String feedbackId) async {
    final loc = AppLocalizations.of(context);

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
                        await _controller.loadFeedbacks();
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

  void _showIngredientReportSheet(BuildContext context, Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => IngredientReportSheet(
        barcode: widget.barcode,
        productName: product.name,
        ingredients: product.ingredients,
      ),
    );
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
      builder: (ctx) => ReportSheet(
        barcode: widget.barcode,
        productName: product.name,
        currentResult: currentResult,
        initialNote: initialNote,
      ),
    );
  }
}
