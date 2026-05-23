import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../localization/format_relative_time.dart';
import '../../models/photo_submission.dart';
import '../../models/review_status.dart';
import '../../services/product_image_service.dart';

class PhotoApprovalTab extends StatefulWidget {
  final void Function(int count) onCountChanged;
  const PhotoApprovalTab({super.key, required this.onCountChanged});

  @override
  State<PhotoApprovalTab> createState() => PhotoApprovalTabState();
}

class PhotoApprovalTabState extends State<PhotoApprovalTab> {
  List<PhotoSubmission> _photos = [];
  bool _loading = false;
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await ProductImageService.getSubmissions();
    if (!mounted) return;
    setState(() {
      _photos = rows.map(PhotoSubmission.fromJson).toList();
      _loading = false;
    });
    widget.onCountChanged(_photos.length);
  }

  Future<void> _review(int id, ReviewStatus status) async {
    setState(() => _processing.add(id));
    final ok = await ProductImageService.updateSubmissionStatus(
      id,
      status.name,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _photos.removeWhere((p) => p.id == id));
      widget.onCountChanged(_photos.length);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminUpdateFailed)),
      );
    }
    setState(() => _processing.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No pending photo submissions',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _photos.length,
        itemBuilder: (_, i) {
          final item = _photos[i];
          return _PhotoSubmissionCard(
            item: item,
            isProcessing: _processing.contains(item.id),
            onApprove: () => _review(item.id, ReviewStatus.approved),
            onReject: () => _review(item.id, ReviewStatus.rejected),
          );
        },
      ),
    );
  }
}

// ── card ──────────────────────────────────────────────────────────────────────

class _PhotoSubmissionCard extends StatelessWidget {
  final PhotoSubmission item;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PhotoSubmissionCard({
    required this.item,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final typeColor = switch (item.imageType) {
      'ingredients' => Colors.orange.shade700,
      'nutrition' => Colors.purple.shade700,
      _ => Colors.blue.shade700,
    };
    final typeBg = switch (item.imageType) {
      'ingredients' => Colors.orange.shade50,
      'nutrition' => Colors.purple.shade50,
      _ => Colors.blue.shade50,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.hasReplacement)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _imagePanel(
                      context,
                      item.currentUrl!,
                      'Current',
                      Colors.grey.shade700,
                    ),
                  ),
                  Container(width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: _imagePanel(
                      context,
                      item.submittedUrl,
                      'New',
                      Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            )
          else if (item.submittedUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _showFullscreen(context, item.submittedUrl),
              child: CachedNetworkImage(
                imageUrl: item.submittedUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
                placeholder: (_, _) => const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, _, _) => const SizedBox(
                  height: 100,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        item.imageType,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.hasReplacement) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Text(
                          'replacement',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (item.createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        formatRelativeTime(loc, item.createdAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.barcode,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),
                if (isProcessing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: FilledButton.styleFrom(
                            backgroundColor: kGreen,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showFullscreen(BuildContext context, String url) {
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
          ],
        ),
      ),
    );
  }

  Widget _imagePanel(
    BuildContext context,
    String url,
    String label,
    Color labelColor,
  ) {
    return GestureDetector(
      onTap: () => _showFullscreen(context, url),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: url,
            height: 200,
            width: double.infinity,
            fit: BoxFit.contain,
            placeholder: (_, _) => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, _, _) => const SizedBox(
              height: 120,
              child: Center(
                child: Icon(Icons.broken_image, size: 36, color: Colors.grey),
              ),
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor == Colors.green.shade700
                      ? Colors.greenAccent
                      : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 6,
            right: 6,
            child: Icon(Icons.zoom_in, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }
}
