import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../localization/format_relative_time.dart';
import '../models/photo_submission.dart';
import '../models/review_status.dart';
import '../services/product_image_service.dart';
import '../services/product_service.dart';
import 'result/widgets/result_product_images.dart';
import 'result_screen.dart';

enum _ContributionFilter { all, pending, approved, rejected }

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  List<PhotoSubmission> _items = [];
  bool _loading = true;
  _ContributionFilter _filter = _ContributionFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await ProductImageService.getMySubmissions();
    if (!mounted) return;
    setState(() {
      _items = rows.map(PhotoSubmission.fromJson).toList();
      _loading = false;
    });
  }

  List<PhotoSubmission> get _filtered => switch (_filter) {
    _ContributionFilter.pending =>
      _items.where((i) => i.status == ReviewStatus.pending).toList(),
    _ContributionFilter.approved =>
      _items.where((i) => i.status == ReviewStatus.approved).toList(),
    _ContributionFilter.rejected =>
      _items.where((i) => i.status == ReviewStatus.rejected).toList(),
    _ => _items,
  };

  Future<void> _openProduct(PhotoSubmission item) async {
    final product = await ProductService().getProduct(item.barcode);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(product: product, barcode: item.barcode),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.myContributions),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: loc.filterAll,
                  selected: _filter == _ContributionFilter.all,
                  onTap: () =>
                      setState(() => _filter = _ContributionFilter.all),
                ),
                _FilterChip(
                  label: loc.filterPending,
                  selected: _filter == _ContributionFilter.pending,
                  onTap: () =>
                      setState(() => _filter = _ContributionFilter.pending),
                ),
                _FilterChip(
                  label: loc.filterApproved,
                  selected: _filter == _ContributionFilter.approved,
                  onTap: () =>
                      setState(() => _filter = _ContributionFilter.approved),
                ),
                _FilterChip(
                  label: loc.filterRejected,
                  selected: _filter == _ContributionFilter.rejected,
                  onTap: () =>
                      setState(() => _filter = _ContributionFilter.rejected),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.4,
                                child: Center(
                                  child: Text(
                                    loc.noPhotoContributions,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (_, index) {
                              final item = filtered[index];
                              return _ContributionCard(
                                item: item,
                                loc: loc,
                                onTap: () => _openProduct(item),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: kGreen.withValues(alpha: 0.15),
        checkmarkColor: kGreenDark,
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.item,
    required this.loc,
    required this.onTap,
  });

  final PhotoSubmission item;
  final AppLocalizations loc;
  final VoidCallback onTap;

  Color _statusColor(ReviewStatus status) => switch (status) {
    ReviewStatus.pending => Colors.orange.shade800,
    ReviewStatus.approved => kGreenDark,
    ReviewStatus.rejected => Colors.red.shade700,
  };

  String _statusLabel(ReviewStatus status) => switch (status) {
    ReviewStatus.pending => loc.filterPending,
    ReviewStatus.approved => loc.filterApproved,
    ReviewStatus.rejected => loc.filterRejected,
  };

  String _typeLabel(String imageType) => switch (imageType) {
    'ingredients' => loc.ingredients,
    'nutrition' => loc.nutritionLabel,
    _ => loc.productImages,
  };

  @override
  Widget build(BuildContext context) {
    final created = item.createdAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.submittedUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: ResultProductImages.thumbnailUrl(
                      item.submittedUrl,
                    ),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_not_supported),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.barcode,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MetaChip(label: _typeLabel(item.imageType)),
                        _MetaChip(
                          label: _statusLabel(item.status),
                          color: _statusColor(item.status),
                        ),
                      ],
                    ),
                    if (created != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        formatRelativeTime(loc, created),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
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
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.blue.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
