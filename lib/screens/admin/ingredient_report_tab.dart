import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../localization/app_localizations.dart';
import '../../localization/format_relative_time.dart';
import '../../models/ingredient_report.dart';
import '../../services/ingredient_report_service.dart';
import '../result_screen.dart';

class IngredientReportTab extends StatefulWidget {
  final void Function(int count) onCountChanged;
  const IngredientReportTab({super.key, required this.onCountChanged});

  @override
  State<IngredientReportTab> createState() => IngredientReportTabState();
}

class IngredientReportTabState extends State<IngredientReportTab> {
  List<IngredientReport> _reports = [];
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
    final rows = await IngredientReportService.getReports();
    if (!mounted) return;
    setState(() {
      _reports = rows.map(IngredientReport.fromJson).toList();
      _loading = false;
    });
    widget.onCountChanged(_reports.length);
  }

  Future<void> _review(int id, String status) async {
    setState(() => _processing.add(id));
    final ok = await IngredientReportService.updateStatus(id, status);
    if (!mounted) return;
    if (ok) {
      setState(() => _reports.removeWhere((r) => r.id == id));
      widget.onCountChanged(_reports.length);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).adminUpdateFailed)),
      );
    }
    setState(() => _processing.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_reports.isEmpty) {
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
            Text(loc.noReports, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (_, i) {
          final item = _reports[i];
          return _IngredientReportCard(
            item: item,
            isProcessing: _processing.contains(item.id),
            onResolve: () => _review(item.id, 'resolved'),
            onDismiss: () => _review(item.id, 'dismissed'),
            onOpenProduct: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ResultScreen(
                  product: null,
                  barcode: item.barcode,
                  adminReportedIngredients: item.reportedIngredients,
                  adminReportExplanation: item.explanation,
                ),
              ),
            ),
            loc: loc,
          );
        },
      ),
    );
  }
}

// ── card ──────────────────────────────────────────────────────────────────────

class _IngredientReportCard extends StatelessWidget {
  final IngredientReport item;
  final bool isProcessing;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;
  final VoidCallback onOpenProduct;
  final AppLocalizations loc;

  const _IngredientReportCard({
    required this.item,
    required this.isProcessing,
    required this.onResolve,
    required this.onDismiss,
    required this.onOpenProduct,
    required this.loc,
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
                    formatRelativeTime(loc, item.createdAt!),
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
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.reportedIngredients
                  .map(
                    (ing) => Chip(
                      label: Text(ing, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.orange.shade50,
                      side: BorderSide(color: Colors.orange.shade300),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            if (item.explanation != null && item.explanation!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.explanation!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
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
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(loc.dismissReport),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenProduct,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(loc.openProduct),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kGreen,
                        side: const BorderSide(color: kGreen),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(loc.resolveReport),
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
