import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product.dart';
import '../../../services/product_image_service.dart';

part 'result_product_image_widgets.dart';

class ResultProductImages extends StatelessWidget {
  const ResultProductImages({
    super.key,
    required this.product,
    required this.loc,
    required this.uploadingImageType,
    required this.onUpload,
  });

  final Product product;
  final AppLocalizations loc;
  final ProductImageType? uploadingImageType;
  final void Function(ProductImageType type) onUpload;

  static String thumbnailUrl(String url) => url.replaceAll('.400.', '.200.');

  static void showFullscreen(
    BuildContext context, {
    required String url,
    String? label,
  }) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (product.imageFrontUrl != null || product.imageUrl != null)
          _FrontImage(
            product: product,
            loc: loc,
            uploading: uploadingImageType == ProductImageType.front,
            onUpload: () => onUpload(ProductImageType.front),
          )
        else
          _FrontPlaceholder(
            loc: loc,
            uploading: uploadingImageType == ProductImageType.front,
            onUpload: () => onUpload(ProductImageType.front),
          ),
        if (!product.isNonFood) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ImageSlot(
                  url: product.imageIngredientsUrl,
                  label: loc.ingredients,
                  type: ProductImageType.ingredients,
                  uploadingImageType: uploadingImageType,
                  onUpload: onUpload,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ImageSlot(
                  url: product.imageNutritionUrl,
                  label: loc.nutritionLabel,
                  type: ProductImageType.nutrition,
                  uploadingImageType: uploadingImageType,
                  onUpload: onUpload,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
