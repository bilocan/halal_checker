import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../models/ai_ingredient_request.dart';
import '../../models/review_status.dart';
import '../../services/ai_ingredient_request_service.dart';
import '../../services/cache_service.dart';
import '../../services/product_service.dart';

class AiApprovalTab extends StatefulWidget {
  final void Function(int count) onCountChanged;
  const AiApprovalTab({super.key, required this.onCountChanged});

  @override
  State<AiApprovalTab> createState() => AiApprovalTabState();
}

class AiApprovalTabState extends State<AiApprovalTab> {
  List<AiIngredientRequest> _requests = [];
  bool _loading = false;
  final Set<int> _processing = {};
  ReviewStatus _filter = ReviewStatus.pending;

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
    try {
      final rows = _filter == ReviewStatus.approved
          ? await AiIngredientRequestService.getApprovedRequests()
          : await AiIngredientRequestService.getPendingRequests();
      if (!mounted) return;
      setState(() {
        _requests = rows.map(AiIngredientRequest.fromJson).toList();
      });
      widget.onCountChanged(_requests.length);
    } catch (e, stack) {
      debugPrint('[AiApprovalTab] _load error: $e\n$stack');
      if (!mounted) return;
      setState(() => _requests = []);
      widget.onCountChanged(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load AI requests — check connection'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(int id, ReviewStatus status) async {
    setState(() => _processing.add(id));
    final item = _requests.firstWhere((r) => r.id == id);
    final ok = await AiIngredientRequestService.updateStatus(id, status.name);
    if (!mounted) return;
    if (ok) {
      setState(() => _requests.removeWhere((r) => r.id == id));
      widget.onCountChanged(_requests.length);
      if (status == ReviewStatus.approved) {
        unawaited(CacheService().removeProduct(item.barcode));
        unawaited(
          ProductService().fetchIngredientsByAI(item.barcode).then((product) {
            debugPrint(
              product != null
                  ? '[AiApprovalTab] AI ingredients fetched for ${item.barcode}: ${product.ingredients.length} ingredients'
                  : '[AiApprovalTab] AI ingredient fetch failed for ${item.barcode}',
            );
          }),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(_failedSnackbar);
    }
    setState(() => _processing.remove(id));
  }

  Future<void> _reApprove(int id) async {
    setState(() => _processing.add(id));
    final item = _requests.firstWhere((r) => r.id == id);
    unawaited(CacheService().removeProduct(item.barcode));
    unawaited(
      ProductService().fetchIngredientsByAI(item.barcode).then((product) {
        debugPrint(
          product != null
              ? '[AiApprovalTab] Re-approved AI fetch for ${item.barcode}: ${product.ingredients.length} ingredients'
              : '[AiApprovalTab] Re-approved AI fetch failed for ${item.barcode}',
        );
      }),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Re-fetching AI ingredients for ${item.barcode}…'),
      ),
    );
    setState(() => _processing.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _filter == ReviewStatus.pending;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              _filterChip('Pending', ReviewStatus.pending),
              const SizedBox(width: 8),
              _filterChip('Approved', ReviewStatus.approved),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _requests.isEmpty
              ? Center(
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
                        isPending
                            ? 'No pending AI ingredient requests'
                            : 'No approved AI ingredient requests',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (_, i) {
                      final item = _requests[i];
                      return _AiRequestCard(
                        item: item,
                        isApproved: !isPending,
                        isProcessing: _processing.contains(item.id),
                        onApprove: () =>
                            _review(item.id, ReviewStatus.approved),
                        onReject: () => _review(item.id, ReviewStatus.rejected),
                        onReApprove: () => _reApprove(item.id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, ReviewStatus value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filter = value;
          _requests = [];
        });
        _load();
      },
      selectedColor: kGreen,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
      checkmarkColor: Colors.white,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ── card ──────────────────────────────────────────────────────────────────────

class _AiRequestCard extends StatelessWidget {
  final AiIngredientRequest item;
  final bool isApproved;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReApprove;

  const _AiRequestCard({
    required this.item,
    required this.isApproved,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
    required this.onReApprove,
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
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 6),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: const Text(
                'Approve to trigger AI ingredient lookup via Gemini/Claude. '
                'The product will be updated automatically.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5B21B6)),
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
            else if (isApproved)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onReApprove,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-fetch AI Ingredients'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    visualDensity: VisualDensity.compact,
                  ),
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
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Approve & Fetch'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
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
