import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product.dart';
import '../models/feedback.dart';
import '../services/feedback_service.dart';
import '../services/product_service.dart';

const _green = Color(0xFF2E7D32);
const _greenMid = Color(0xFF388E3C);
const _greenLight = Color(0xFFA5D6A7);
const _greenSurface = Color(0xFFE8F5E9);

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

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoadingFeedback = true);
    try {
      final feedbacks = await _feedbackService.getFeedbacksForBarcode(widget.barcode);
      if (mounted) {
        setState(() => _feedbacks = feedbacks);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load feedback. Please try again.')),
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
      final refreshedProduct = await _productService.getProduct(widget.barcode);
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
          const SnackBar(content: Text('Could not refresh product data.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh product data.')),
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
    final product = widget.product;
    final barcode = widget.barcode;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Result'),
          backgroundColor: _green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Product not found', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text('Barcode: $barcode', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Scan Again'),
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
        title: const Text('Result'),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshProductData,
              tooltip: 'Refresh product data',
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
                  color: isHalal ? _green : Colors.red,
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
                          : _halalReasonText(isHalal, suspiciousIngredients),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                ? 'AI Analysis'
                                : 'Keyword Analysis',
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
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Barcode: $barcode', style: const TextStyle(color: Colors.grey)),
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
                    child: _buildProductImage(product),
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
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No product image available', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (product.imageIngredientsUrl != null || product.imageNutritionUrl != null) ...[
                Text(
                  'Additional Images',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                if (product.imageIngredientsUrl != null)
                  _buildLabelledImage(product.imageIngredientsUrl!, 'Ingredients'),
                if (product.imageNutritionUrl != null)
                  _buildLabelledImage(product.imageNutritionUrl!, 'Nutrition'),
                const SizedBox(height: 24),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (ingredients.isEmpty)
                const Text('No ingredient data available.', style: TextStyle(color: Colors.grey))
              else
                ...ingredients.map((ingredient) {
                  final warning = product.ingredientWarnings[ingredient];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        warning == null ? Icons.check_circle_outline : Icons.warning,
                        color: warning == null ? _green : Colors.red,
                      ),
                      title: Text(ingredient),
                      subtitle: warning == null ? null : Text(warning),
                      dense: true,
                    ),
                  );
                }),
              if (!isHalal) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Flagged Ingredients',
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
                    subtitle: warning == null ? const Text('Found in product ingredients.') : Text(warning),
                    dense: true,
                  );
                }),
              ],
              if (suspiciousIngredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'May Be Animal-Derived',
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
                    subtitle: warning == null ? const Text('May be animal-derived.') : Text(warning),
                    dense: true,
                  );
                }),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Community Feedback',
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
                const Text(
                  'No feedback yet. Be the first to share your thoughts!',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ..._feedbacks.map((feedback) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'User Feedback',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(feedback.submittedAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(feedback.userFeedback),
                        if (feedback.attachments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: feedback.attachments.map((attachment) => Chip(
                              label: Text('📎 ${attachment.split(RegExp(r'[/\\]')).last}'),
                              backgroundColor: Colors.blue.shade50,
                            )).toList(),
                          ),
                        ],
                        if (feedback.producerReply != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _greenSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _greenLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.business, size: 16, color: _green),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Producer Reply',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _greenMid,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      feedback.repliedAt != null ? _formatDate(feedback.repliedAt!) : '',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                              onPressed: () => _showProducerReplyDialog(feedback.id),
                              icon: const Icon(Icons.reply, size: 16),
                              label: const Text('Reply as Producer'),
                              style: TextButton.styleFrom(
                                foregroundColor: _greenMid,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Scan Another Product', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _green),
                    foregroundColor: _green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _showFeedbackDialog(context),
                  child: const Text('Provide Feedback', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
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
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Widget _buildProductImage(Product product) {
    final imageUrls = [
      product.imageFrontUrl,
      product.imageUrl,
    ].where((url) => url != null && url.isNotEmpty).cast<String>().toList();

    if (imageUrls.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image not available', style: TextStyle(color: Colors.grey)),
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
                    errorBuilder: (_, _, _) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Image not available', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Image not available', style: TextStyle(color: Colors.grey)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    if (lowerLabels.any((l) => l.contains('fair trade') || l.contains('fair-trade') || l.contains('fairtrade'))) {
      normalized.add('Fair Trade');
    }
    if (lowerLabels.any((l) => l.contains('organic'))) {
      normalized.add('Organic');
    }
    if (lowerLabels.any((l) => l.contains('gluten free') || l.contains('gluten-free') || l.contains('glutenfree'))) {
      normalized.add('Gluten Free');
    }

    return normalized.map(_buildLabelChip).whereType<Widget>().toList();
  }

  Widget? _buildLabelChip(String label) {
    switch (label) {
      case 'Vegan':
        return Chip(
          avatar: const Icon(Icons.eco, size: 18, color: _green),
          label: const Text('Vegan'),
          backgroundColor: _greenSurface,
        );
      case 'Vegetarian':
        return Chip(
          avatar: const Icon(Icons.grass, size: 18, color: _green),
          label: const Text('Vegetarian'),
          backgroundColor: _greenSurface,
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
          avatar: const Icon(Icons.health_and_safety, size: 18, color: Colors.orange),
          label: const Text('Gluten Free'),
          backgroundColor: Colors.orange.shade50,
        );
      default:
        return null;
    }
  }

  String _halalReasonText(bool isHalal, List<String> suspiciousIngredients) {
    if (isHalal) {
      if (suspiciousIngredients.isEmpty) {
        return 'No ingredients matched known animal-derived or alcohol-related keywords. This is an automated assessment based on ingredient text.';
      }
      return 'No definitely haram ingredients found, but some ingredients may be animal-derived. This is an automated assessment based on ingredient text.';
    }
    return 'This product contains one or more ingredients that may be animal-derived or alcohol-related. Review the flagged ingredients below for details.';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';

    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _showFeedbackDialog(BuildContext context) async {
    final TextEditingController feedbackController = TextEditingController();
    final List<String> selectedFiles = [];

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Provide Feedback'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Help improve our halal assessment by providing feedback about this product.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Your feedback...',
                    border: OutlineInputBorder(),
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
                                result.files.map((f) => f.path!),
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach Files'),
                      ),
                    ),
                  ],
                ),
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: selectedFiles.map((file) => Chip(
                      label: Text(file.split(RegExp(r'[/\\]')).last),
                      onDeleted: () => setDialogState(() => selectedFiles.remove(file)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: feedbackController.text.trim().isEmpty
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _feedbackService.addFeedback(
                          widget.barcode,
                          feedbackController.text.trim(),
                          attachments: selectedFiles,
                        );
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Feedback submitted successfully!')),
                        );
                        await _loadFeedbacks();
                      } catch (e) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Could not submit feedback. Please try again.')),
                        );
                      }
                    },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProducerReplyDialog(String feedbackId) async {
    final TextEditingController replyController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          replyController.addListener(() => setDialogState(() {}));
          return AlertDialog(
            title: const Text('Reply as Producer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Provide an official response to this feedback.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: replyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Your reply...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: replyController.text.trim().isEmpty
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await _feedbackService.addProducerReply(
                            feedbackId,
                            replyController.text.trim(),
                          );
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Reply submitted successfully!')),
                          );
                          await _loadFeedbacks();
                        } catch (e) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Could not submit reply. Please try again.')),
                          );
                        }
                      },
                child: const Text('Submit Reply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
