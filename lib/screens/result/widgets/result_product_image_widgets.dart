part of 'result_product_images.dart';

class _FrontImage extends StatelessWidget {
  const _FrontImage({
    required this.product,
    required this.loc,
    required this.uploading,
    required this.onUpload,
  });

  final Product product;
  final AppLocalizations loc;
  final bool uploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            child: _ProductImageView(product: product, loc: loc),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: uploading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : _ReplaceChip(onTap: onUpload),
        ),
      ],
    );
  }
}

class _FrontPlaceholder extends StatelessWidget {
  const _FrontPlaceholder({
    required this.loc,
    required this.uploading,
    required this.onUpload,
  });

  final AppLocalizations loc;
  final bool uploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade100,
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: uploading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 40, color: Colors.grey),
                  const SizedBox(height: 6),
                  Text(
                    loc.noProductImageAvailable,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onUpload,
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
    );
  }
}

class _ProductImageView extends StatelessWidget {
  const _ProductImageView({required this.product, required this.loc});

  final Product product;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
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
      onTap: () =>
          ResultProductImages.showFullscreen(context, url: imageUrls.first),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: ResultProductImages.thumbnailUrl(imageUrls.first),
            fit: BoxFit.contain,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) {
              if (imageUrls.length > 1) {
                return GestureDetector(
                  onTap: () => ResultProductImages.showFullscreen(
                    context,
                    url: imageUrls[1],
                  ),
                  child: CachedNetworkImage(
                    imageUrl: ResultProductImages.thumbnailUrl(imageUrls[1]),
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
}

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({
    required this.url,
    required this.label,
    required this.type,
    required this.uploadingImageType,
    required this.onUpload,
  });

  final String? url;
  final String label;
  final ProductImageType type;
  final ProductImageType? uploadingImageType;
  final void Function(ProductImageType type) onUpload;

  @override
  Widget build(BuildContext context) {
    debugPrint('[ImageSlot] $label → url=$url');
    if (url != null) {
      return Stack(
        children: [
          _LabelledImage(url: url!, label: label),
          Positioned(
            bottom: 18,
            right: 8,
            child: uploadingImageType == type
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : _ReplaceChip(onTap: () => onUpload(type)),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () => onUpload(type),
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
          child: uploadingImageType == type
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
}

class _LabelledImage extends StatelessWidget {
  const _LabelledImage({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          ResultProductImages.showFullscreen(context, url: url, label: label),
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
                imageUrl: ResultProductImages.thumbnailUrl(url),
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
}

class _ReplaceChip extends StatelessWidget {
  const _ReplaceChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit, color: Colors.white, size: 13),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).replacePhoto,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
