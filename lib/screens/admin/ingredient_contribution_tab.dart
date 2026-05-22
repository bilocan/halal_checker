import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../models/ingredient_contribution.dart';
import '../../models/review_status.dart';
import '../../services/cache_service.dart';
import '../../services/ingredient_contribution_service.dart';
import '../../services/product_service.dart';

class IngredientContributionTab extends StatefulWidget {
  final void Function(int count) onCountChanged;
  const IngredientContributionTab({super.key, required this.onCountChanged});

  @override
  State<IngredientContributionTab> createState() =>
      IngredientContributionTabState();
}

class IngredientContributionTabState extends State<IngredientContributionTab> {
  List<IngredientContribution> _contributions = [];
  bool _loading = false;
  final Set<int> _processing = {};

  static const _failedSnackbar = SnackBar(
    content: Text('Failed to update — check Supabase logs'),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await IngredientContributionService.getContributions();
    if (!mounted) return;
    setState(() {
      _contributions = rows.map(IngredientContribution.fromJson).toList();
      _loading = false;
    });
    widget.onCountChanged(_contributions.length);
  }

  Future<void> _review(int id, ReviewStatus status) async {
    setState(() => _processing.add(id));
    final item = _contributions.firstWhere((c) => c.id == id);
    final ok = await IngredientContributionService.updateStatus(
      id,
      status.name,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _contributions.removeWhere((c) => c.id == id));
      widget.onCountChanged(_contributions.length);
      if (status == ReviewStatus.approved) {
        debugPrint(
          '[IngredientContributionTab] Triggering re-analysis for ${item.barcode} after contribution approval',
        );
        unawaited(
          CacheService().removeProduct(item.barcode).then((_) {
            debugPrint(
              '[IngredientContributionTab] Cleared local cache for ${item.barcode}',
            );
          }),
        );
        unawaited(
          ProductService().refreshProduct(item.barcode).then((product) {
            debugPrint(
              product != null
                  ? '[IngredientContributionTab] Re-analysis done for ${item.barcode}: isHalal=${product.isHalal}'
                  : '[IngredientContributionTab] Re-analysis failed for ${item.barcode}',
            );
          }),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(_failedSnackbar);
    }
    setState(() => _processing.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_contributions.isEmpty) {
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
              'No pending ingredient contributions',
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
        itemCount: _contributions.length,
        itemBuilder: (_, i) {
          final item = _contributions[i];
          return _ContributionCard(
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

class _ContributionCard extends StatelessWidget {
  final IngredientContribution item;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ContributionCard({
    required this.item,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.createdAt != null)
                  Text(
                    _formatAge(item.createdAt!),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
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
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  item.ingredientText,
                  style: const TextStyle(fontSize: 12),
                ),
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
    );
  }
}

String _formatAge(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
