import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../models/product.dart';
import '../models/feedback.dart';
import '../services/feedback_service.dart';
import '../services/product_service.dart';

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
  List<FeedbackItem> _feedbacks = [];
  bool _isLoadingFeedback = false;
  bool _isRefreshing = false;

  // Pre-computed once in initState to avoid regex work during build.
  Set<String> _foundInText = {};
  Set<String> _flaggedByAnalysis = {};

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
    _computeTransparency();
  }

  void _computeTransparency() {
    final product = widget.product;
    if (product == null) return;

    final foundInText = <String>{};
    final flaggedByAnalysis = <String>{};

    for (final ingredient in product.ingredients) {
      final lower = ingredient.toLowerCase();
      for (final kw in ProductService.haramKeywords.keys) {
        if (ProductService.matchesKeyword(lower, kw)) foundInText.add(kw);
      }
      for (final kw in ProductService.suspiciousKeywords.keys) {
        if (ProductService.matchesKeyword(lower, kw)) foundInText.add(kw);
      }
    }
    for (final flagged in [
      ...product.haramIngredients,
      ...product.suspiciousIngredients,
    ]) {
      final lower = flagged.toLowerCase();
      for (final kw in ProductService.haramKeywords.keys) {
        if (ProductService.matchesKeyword(lower, kw)) flaggedByAnalysis.add(kw);
      }
      for (final kw in ProductService.suspiciousKeywords.keys) {
        if (ProductService.matchesKeyword(lower, kw)) flaggedByAnalysis.add(kw);
      }
    }

    _foundInText = foundInText;
    _flaggedByAnalysis = flaggedByAnalysis;
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
              Text(
                'Barcode: $barcode',
                style: const TextStyle(color: Colors.grey),
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
    final ingredients = product.ingredients;
    final suspiciousIngredients = product.suspiciousIngredients;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.resultTitle),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        actions: [
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
                  color: isHalal ? kGreen : Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      isHalal ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isHalal ? '✅ HALAL' : '❌ NOT HALAL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.explanation.isNotEmpty
                          ? product.explanation
                          : _halalReasonText(
                              isHalal,
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Barcode: $barcode',
                style: const TextStyle(color: Colors.grey),
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
                )
              else
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          loc.noProductImageAvailable,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (product.imageIngredientsUrl != null ||
                  product.imageNutritionUrl != null) ...[
                Text(
                  loc.additionalImages,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                if (product.imageIngredientsUrl != null)
                  _buildLabelledImage(
                    product.imageIngredientsUrl!,
                    loc.ingredients,
                  ),
                if (product.imageNutritionUrl != null)
                  _buildLabelledImage(
                    product.imageNutritionUrl!,
                    loc.nutritionLabel,
                  ),
                const SizedBox(height: 24),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.ingredients,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (ingredients.isEmpty)
                Text(
                  loc.noIngredientData,
                  style: const TextStyle(color: Colors.grey),
                )
              else
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
                      title: Text(ingredient),
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
                    title: Text(e),
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
                    title: Text(e),
                    subtitle: Text(warning ?? loc.mayBeAnimalDerivedNote),
                    dense: true,
                  );
                }),
              ],
              const SizedBox(height: 16),
              _buildTransparencySection(product, loc),
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
                  onPressed: () => _showFeedbackDialog(context),
                  child: Text(
                    loc.provideFeedback,
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

  Widget _buildTransparencySection(Product product, AppLocalizations loc) {
    // 3 states: flagged (red/orange) | found but cleared (amber) | not found (grey)
    // _foundInText and _flaggedByAnalysis are pre-computed in initState.
    Widget keywordChip(
      String kw,
      String reason,
      Color flaggedColor,
      IconData flaggedIcon,
    ) {
      final isFlagged = _flaggedByAnalysis.contains(kw);
      final isFoundOnly = !isFlagged && _foundInText.contains(kw);

      final Color bg = isFlagged
          ? flaggedColor
          : isFoundOnly
          ? Colors.amber.shade600
          : Colors.grey.shade200;
      final Color textColor = (isFlagged || isFoundOnly)
          ? Colors.white
          : Colors.grey.shade700;
      final String tooltip = isFlagged
          ? reason
          : isFoundOnly
          ? loc.foundNotFlagged
          : reason;
      final IconData? icon = isFlagged
          ? flaggedIcon
          : isFoundOnly
          ? Icons.help_outline
          : null;

      return Tooltip(
        message: tooltip,
        child: Chip(
          label: Text(kw, style: TextStyle(fontSize: 11, color: textColor)),
          backgroundColor: bg,
          avatar: icon != null
              ? Icon(icon, size: 14, color: Colors.white)
              : null,
          padding: EdgeInsets.zero,
        ),
      );
    }

    final hasAnyAmber = _foundInText.any(
      (kw) => !_flaggedByAnalysis.contains(kw),
    );

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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loc.haramKeywordsChecked,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ProductService.haramKeywords.entries
                .map(
                  (e) => keywordChip(
                    e.key,
                    e.value,
                    Colors.red.shade600,
                    Icons.close,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loc.suspiciousKeywordsChecked,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ProductService.suspiciousKeywords.entries
                .map(
                  (e) => keywordChip(
                    e.key,
                    e.value,
                    Colors.orange.shade600,
                    Icons.warning_amber,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          if (hasAnyAmber) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.foundNotFlagged,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
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
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
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
          Image.network(
            imageUrls.first,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              if (imageUrls.length > 1) {
                return GestureDetector(
                  onTap: () => _showFullscreenImage(imageUrls[1]),
                  child: Image.network(
                    imageUrls[1],
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Center(
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
              Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
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

  String _halalReasonText(
    bool isHalal,
    List<String> suspiciousIngredients,
    AppLocalizations loc,
  ) {
    if (isHalal) {
      return suspiciousIngredients.isEmpty
          ? loc.explanationClean
          : loc.explanationSuspiciousOnly;
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
}
