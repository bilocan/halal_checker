import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../app_colors.dart';
import '../config.dart';
import '../localization/app_localizations.dart';
import '../models/community.dart';
import '../models/feedback.dart';
import '../models/product.dart';
import '../models/review_status.dart';
import '../services/ai_ingredient_request_service.dart';
import '../services/analysis_service.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../services/database_service.dart';
import '../services/feedback_service.dart';
import '../services/product_image_service.dart';
import '../services/product_service.dart';
import '../widgets/feedback_dialog.dart';
import '../widgets/report_sheets.dart';
import 'admin_panel_screen.dart';
import 'discussion_screen.dart';
import 'result/debug/local_db_debug_dialog.dart';
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
  final FeedbackService _feedbackService = FeedbackService();
  final ProductService _productService = ProductService();
  final AnalysisService _analysisService = AnalysisService();
  List<FeedbackItem> _feedbacks = [];
  bool _isLoadingFeedback = false;
  bool _isRefreshing = false;
  bool _isFetchingAiIngredients = false;
  ReviewStatus? _aiRequestStatus;
  ProductImageType? _uploadingImageType;
  bool _showTranslated = false;
  String _note = '';
  bool _isFlagged = false;
  bool _noteExpanded = false;
  final _noteController = TextEditingController();

  List<Discussion> _discussions = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadFeedbacks(),
      _loadNote(),
      _loadDiscussions(),
      _loadAiRequestStatus(),
      _loadAdminStatus(),
    ]);
  }

  Future<void> _loadAdminStatus() async {
    final admin = await _analysisService.isAdmin();
    if (mounted) setState(() => _isAdmin = admin);
  }

  Future<void> _loadAiRequestStatus() async {
    if (AuthService.currentUser == null) return;
    final req = await AiIngredientRequestService.getRequestForBarcode(
      widget.barcode,
    );
    if (req != null && mounted) {
      setState(
        () => _aiRequestStatus = ReviewStatus.fromString(
          req['status'] as String?,
        ),
      );
    }
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

  Future<void> _loadDiscussions() async {
    final d = await CommunityService.getDiscussions(widget.barcode);
    if (mounted) setState(() => _discussions = d);
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

  Future<void> _requestAiIngredients() async {
    if (_isFetchingAiIngredients) return;
    if (AuthService.currentUser == null) {
      _showSignInRequired(context);
      return;
    }
    setState(() => _isFetchingAiIngredients = true);
    try {
      final submitted = await AiIngredientRequestService.submitRequest(
        widget.barcode,
        productName: widget.product?.name,
      );
      if (!mounted) return;
      if (submitted) {
        setState(() => _aiRequestStatus = ReviewStatus.pending);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI request submitted — pending admin review.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() => _aiRequestStatus = ReviewStatus.pending);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An AI request for this product is already pending.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit AI request.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingAiIngredients = false);
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

  Future<void> _openDiscussion() async {
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
  }

  Widget _buildBottomNav(AppLocalizations loc) {
    return ResultBottomNav(
      loc: loc,
      isAdmin: _isAdmin,
      onHome: () => Navigator.pop(context),
      onAdmin: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
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
          onCopyBarcode: () => _copyToClipboard(barcode, 'Barcode'),
          onScanAgain: () => Navigator.pop(context),
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
                productService: _productService,
              ),
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
              ResultStatusBanner(product: product, loc: loc),
              const SizedBox(height: 24),
              ResultProductHeader(
                product: product,
                barcode: barcode,
                onCopyBarcode: () => _copyToClipboard(barcode, 'Barcode'),
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
                  'Ingredients',
                ),
                onReportIngredient: () =>
                    _showIngredientReportSheet(context, product),
                adminReportedIngredients: widget.adminReportedIngredients,
                adminReportExplanation: widget.adminReportExplanation,
                aiRequestStatus: _aiRequestStatus,
                isFetchingAiIngredients: _isFetchingAiIngredients,
                onRequestAiIngredients: _requestAiIngredients,
                onRefreshProduct: _refreshProductData,
              ),
              const SizedBox(height: 16),
              ResultTransparencyCard(product: product, loc: loc),
              const SizedBox(height: 16),
              ResultNoteCard(
                loc: loc,
                note: _note,
                isFlagged: _isFlagged,
                isExpanded: _noteExpanded,
                noteController: _noteController,
                onToggleExpanded: () =>
                    setState(() => _noteExpanded = !_noteExpanded),
                onToggleFlag: _toggleFlag,
                onSave: _saveNote,
                onReportWithNote: _reportWithNote,
              ),
              const SizedBox(height: 16),
              ResultCommunityCard(
                loc: loc,
                discussionCount: _discussions.length,
                onTap: _openDiscussion,
              ),
              const SizedBox(height: 16),
              ResultFeedbackSection(
                loc: loc,
                feedbacks: _feedbacks,
                isLoading: _isLoadingFeedback,
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
      ),
      bottomNavigationBar: _buildBottomNav(loc),
    );
  }

  void _onFeedbackTap(BuildContext context) {
    if (AppConfig.hasSupabase && AuthService.currentUser == null) {
      _showSignInRequired(context);
      return;
    }
    showFeedbackDialog(
      context: context,
      barcode: widget.barcode,
      feedbackService: _feedbackService,
      onSubmitted: _loadFeedbacks,
    );
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
