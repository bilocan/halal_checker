import 'package:flutter/foundation.dart';

import '../../models/community.dart';
import '../../models/feedback.dart';
import '../../models/product.dart';
import '../../models/product_analysis.dart';
import '../../models/review_status.dart';
import '../../services/ai_ingredient_request_service.dart';
import '../../services/analysis_service.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/database_service.dart';
import '../../services/feedback_service.dart';
import '../../services/product_service.dart';
import '../../services/product_verdict.dart';

/// Async state and actions for [ResultScreen].
class ResultController extends ChangeNotifier {
  ResultController({
    required this.barcode,
    this.product,
    FeedbackService? feedbackService,
    ProductService? productService,
    AnalysisService? analysisService,
  }) : _feedbackService = feedbackService ?? FeedbackService(),
       _productService = productService ?? ProductService(),
       _analysisService = analysisService ?? AnalysisService();

  final String barcode;
  final Product? product;

  final FeedbackService _feedbackService;
  final ProductService _productService;
  final AnalysisService _analysisService;

  ProductService get productService => _productService;

  List<FeedbackItem> feedbacks = [];
  bool feedbackLoadFailed = false;
  bool isLoadingFeedback = false;
  bool isRefreshing = false;
  bool isFetchingAiIngredients = false;
  ReviewStatus? aiRequestStatus;
  String note = '';
  bool isFlagged = false;
  List<Discussion> discussions = [];
  bool isAdmin = false;
  ProductAnalysis? analysis;
  bool isRequestingAnalysis = false;

  Future<void> loadAll() async {
    try {
      await Future.wait([
        loadFeedbacks(),
        loadNote(),
        loadDiscussions(),
        loadAiRequestStatus(),
        loadAdminStatus(),
        loadAnalysis(),
      ]);
    } on Object catch (e, stack) {
      debugPrint('[ResultController] loadAll error: $e\n$stack');
    }
  }

  Future<void> loadAdminStatus() async {
    final admin = await _analysisService.isAdmin();
    isAdmin = admin;
    notifyListeners();
  }

  Future<void> loadAiRequestStatus() async {
    if (AuthService.currentUser == null) return;
    try {
      final req = await AiIngredientRequestService.getRequestForBarcode(
        barcode,
      );
      aiRequestStatus = req == null
          ? null
          : ReviewStatus.fromString(req['status'] as String?);
    } catch (_) {
      aiRequestStatus = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadNote() async {
    final data = await DatabaseService.instance.getScanNote(barcode);
    if (data != null) {
      note = data['notes'] as String? ?? '';
      isFlagged = data['isFlagged'] as bool;
      notifyListeners();
    }
  }

  Future<void> saveNote(String rawNote) async {
    final trimmed = rawNote.trim();
    await DatabaseService.instance.updateScanNote(
      barcode,
      note: trimmed.isEmpty ? null : trimmed,
      isFlagged: isFlagged,
    );
    note = trimmed;
    notifyListeners();
  }

  Future<void> toggleFlag(String rawNote) async {
    isFlagged = !isFlagged;
    final trimmed = rawNote.trim();
    await DatabaseService.instance.updateScanNote(
      barcode,
      note: trimmed.isEmpty ? null : trimmed,
      isFlagged: isFlagged,
    );
    notifyListeners();
  }

  Future<void> loadAnalysis() async {
    analysis = await _analysisService.getAnalysis(barcode);
    notifyListeners();
  }

  Future<void> loadDiscussions() async {
    discussions = await CommunityService.getDiscussions(barcode);
    notifyListeners();
  }

  Future<void> loadFeedbacks() async {
    isLoadingFeedback = true;
    notifyListeners();
    try {
      feedbacks = await _feedbackService.getFeedbacksForBarcode(barcode);
      feedbackLoadFailed = false;
    } catch (_) {
      feedbackLoadFailed = true;
    } finally {
      isLoadingFeedback = false;
      notifyListeners();
    }
  }

  /// Returns updated analysis, or null on failure. Caller handles auth UI.
  Future<ProductAnalysis?> requestDeepAnalysis() async {
    if (AuthService.currentUser == null) return null;
    isRequestingAnalysis = true;
    notifyListeners();
    try {
      final result = await _analysisService.requestDeepAnalysis(
        barcode,
        product: product,
      );
      if (result != null) analysis = result;
      return result;
    } finally {
      isRequestingAnalysis = false;
      notifyListeners();
    }
  }

  /// Refreshed product on success, or null if lookup failed.
  Future<Product?> refreshProduct() async {
    if (isRefreshing) return null;
    isRefreshing = true;
    notifyListeners();
    try {
      final refreshed = await _productService.refreshProduct(barcode);
      if (refreshed != null) {
        await DatabaseService.instance.insertScan(
          barcode: barcode,
          productName: refreshed.name,
          isHalal: refreshed.isHalal,
          verdict: ProductVerdict.storageKey(refreshed),
        );
      }
      return refreshed;
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  /// True when a new request was submitted; false if already pending.
  Future<bool?> requestAiIngredients() async {
    if (isFetchingAiIngredients) return null;
    if (AuthService.currentUser == null) return null;
    isFetchingAiIngredients = true;
    notifyListeners();
    try {
      final submitted = await AiIngredientRequestService.submitRequest(
        barcode,
        productName: product?.name,
      );
      if (submitted) {
        aiRequestStatus = ReviewStatus.pending;
      }
      return submitted;
    } catch (_) {
      return null;
    } finally {
      isFetchingAiIngredients = false;
      notifyListeners();
    }
  }
}
