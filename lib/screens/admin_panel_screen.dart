import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../models/product_analysis.dart';
import '../services/analysis_service.dart';
import '../services/cache_service.dart';
import '../services/ingredient_contribution_service.dart';
import '../services/ingredient_report_service.dart';
import '../services/product_image_service.dart';
import '../services/product_service.dart';
import 'result_screen.dart';
import 'rules_management_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _service = AnalysisService();
  int _tabIndex = 0;

  // ── analysis tab ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _analyses = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _running = false;
  String _filter = 'all';

  // ── photos tab ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _photos = [];
  bool _photosLoading = false;
  final Set<int> _processingPhotoIds = {};

  // ── ingredients tab ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> _contributions = [];
  bool _contributionsLoading = false;
  final Set<int> _processingContributionIds = {};

  // ── reports tab ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _reports = [];
  bool _reportsLoading = false;
  final Set<int> _processingReportIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _loadPhotos();
    _loadContributions();
    _loadReports();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _selected.clear();
    });
    final list = await _service.getAnalysisList();
    if (!mounted) return;
    setState(() {
      _analyses = list ?? [];
      _loading = false;
    });
  }

  Future<void> _loadPhotos() async {
    setState(() => _photosLoading = true);
    final list = await ProductImageService.getSubmissions();
    if (!mounted) return;
    setState(() {
      _photos = list;
      _photosLoading = false;
    });
  }

  Future<void> _reviewPhoto(int id, String status) async {
    setState(() => _processingPhotoIds.add(id));
    final ok = await ProductImageService.updateSubmissionStatus(id, status);
    if (!mounted) return;
    if (ok) {
      setState(
        () => _photos.removeWhere((p) => (p['id'] as num).toInt() == id),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update — check Supabase logs')),
      );
    }
    setState(() => _processingPhotoIds.remove(id));
  }

  Future<void> _loadContributions() async {
    setState(() => _contributionsLoading = true);
    final list = await IngredientContributionService.getContributions();
    if (!mounted) return;
    setState(() {
      _contributions = list;
      _contributionsLoading = false;
    });
  }

  Future<void> _reviewContribution(int id, String status) async {
    setState(() => _processingContributionIds.add(id));

    // Get the barcode before updating (needed for re-analysis on approval)
    final contribution = _contributions.firstWhere(
      (c) => (c['id'] as num).toInt() == id,
      orElse: () => <String, dynamic>{},
    );
    final barcode = contribution['barcode'] as String?;

    final ok = await IngredientContributionService.updateStatus(id, status);
    if (!mounted) return;
    if (ok) {
      setState(
        () => _contributions.removeWhere((c) => (c['id'] as num).toInt() == id),
      );

      // Trigger rule-based re-analysis of the product when contribution is approved
      if (status == 'approved' && barcode != null && barcode.isNotEmpty) {
        debugPrint(
          '[AdminPanel] Triggering rule-based re-analysis for barcode: $barcode '
          'after ingredient contribution approval',
        );
        // Clear the local cache immediately to ensure the next lookup
        // fetches the updated product from the remote database
        unawaited(
          CacheService().removeProduct(barcode).then((_) {
            debugPrint('[AdminPanel] Cleared local cache for $barcode');
          }),
        );
        // Also trigger a background refresh to pre-populate the cache
        // with the updated product data
        unawaited(
          ProductService().refreshProduct(barcode).then((product) {
            if (product != null) {
              debugPrint(
                '[AdminPanel] Rule-based re-analysis completed for $barcode: '
                'isHalal=${product.isHalal}',
              );
            } else {
              debugPrint(
                '[AdminPanel] Rule-based re-analysis failed for $barcode',
              );
            }
          }),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update — check Supabase logs')),
      );
    }
    setState(() => _processingContributionIds.remove(id));
  }

  Future<void> _loadReports() async {
    setState(() => _reportsLoading = true);
    final list = await IngredientReportService.getReports();
    if (!mounted) return;
    setState(() {
      _reports = list;
      _reportsLoading = false;
    });
  }

  Future<void> _reviewReport(int id, String status) async {
    setState(() => _processingReportIds.add(id));
    final ok = await IngredientReportService.updateStatus(id, status);
    if (!mounted) return;
    if (ok) {
      setState(
        () => _reports.removeWhere((r) => (r['id'] as num).toInt() == id),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update — check Supabase logs')),
      );
    }
    setState(() => _processingReportIds.remove(id));
  }

  Future<void> _run({List<String>? ids}) async {
    setState(() => _running = true);
    final result = ids != null
        ? await _service.runBatch(ids: ids, limit: ids.length)
        : await _service.runBatch(limit: 50);
    if (!mounted) return;
    setState(() {
      _running = false;
      _selected.clear();
    });
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch request failed — check Supabase logs'),
        ),
      );
      return;
    }
    final done = result['results']?['done'] ?? 0;
    final skipped = result['results']?['skipped'] ?? 0;
    final errors = result['results']?['error'] ?? 0;
    final errorDetails = result['errorDetails'] as List? ?? [];
    for (final e in errorDetails) {
      debugPrint('[batch-analyze] ${e['barcode']}: ${e['reason']}');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errors > 0
              ? 'Done: $done, skipped: $skipped, failed: $errors — see logs'
              : 'Done: $done, skipped: $skipped',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
    _load();
  }

  List<Map<String, dynamic>> get _filtered => switch (_filter) {
    'pending' =>
      _analyses
          .where(
            (a) => a['status'] == 'pending' || a['status'] == 'ai_analyzing',
          )
          .toList(),
    'done' =>
      _analyses
          .where(
            (a) =>
                a['status'] == 'ai_done' ||
                a['status'] == 'community_review' ||
                a['status'] == 'consulting' ||
                a['status'] == 'resolved',
          )
          .toList(),
    _ => _analyses,
  };

  int get _pendingCount =>
      _analyses.where((a) => a['status'] == 'pending').length;

  void _toggleSelect(String id) => setState(
    () => _selected.contains(id) ? _selected.remove(id) : _selected.add(id),
  );

  void _selectAllPending() => setState(() {
    final pendingIds = _analyses
        .where((a) => a['status'] == 'pending')
        .map((a) => a['id'] as String)
        .toSet();
    if (pendingIds.every(_selected.contains)) {
      _selected.removeAll(pendingIds);
    } else {
      _selected.addAll(pendingIds);
    }
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.adminPanel),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_tabIndex == 0 && _selected.isNotEmpty)
            TextButton.icon(
              onPressed: _running ? null : () => _run(ids: _selected.toList()),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                'Run ${_selected.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (_tabIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
          if (_tabIndex == 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _photosLoading ? null : _loadPhotos,
            ),
          if (_tabIndex == 3)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _contributionsLoading ? null : _loadContributions,
            ),
          if (_tabIndex == 4)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reportsLoading ? null : _loadReports,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(loc),
          Expanded(
            child: switch (_tabIndex) {
              0 => _buildAnalysisBody(),
              1 => const RulesManagementScreen(),
              2 => _buildPhotosBody(loc),
              3 => _buildIngredientsBody(loc),
              _ => _buildReportsBody(loc),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations loc) {
    return Container(
      color: Colors.green.shade50,
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: loc.analysisTab,
              icon: Icons.analytics_outlined,
              index: 0,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: loc.rulesEngineTab,
              icon: Icons.rule_outlined,
              index: 1,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: loc.photosTab,
              icon: Icons.photo_library_outlined,
              index: 2,
              badge: _photos.isNotEmpty ? _photos.length : null,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: loc.ingredientsTab,
              icon: Icons.list_alt_outlined,
              index: 3,
              badge: _contributions.isNotEmpty ? _contributions.length : null,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: loc.reportsTab,
              icon: Icons.flag_outlined,
              index: 4,
              badge: _reports.isNotEmpty ? _reports.length : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required IconData icon,
    required int index,
    int? badge,
  }) {
    final selected = _tabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _tabIndex = index);
        if (index == 3) _loadContributions();
        if (index == 4) _loadReports();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? kGreen : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? kGreen : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? kGreen : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null && badge > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── analysis tab ──────────────────────────────────────────────────────────

  Widget _buildAnalysisBody() {
    return Column(
      children: [
        _buildHeader(),
        _buildFilterRow(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildHeader() {
    final hasPending = _pendingCount > 0;
    final allPendingSelected =
        _pendingCount > 0 &&
        _analyses
            .where((a) => a['status'] == 'pending')
            .every((a) => _selected.contains(a['id'] as String));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: Colors.green.shade50,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_pendingCount pending',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: hasPending
                        ? Colors.orange.shade700
                        : Colors.grey.shade500,
                  ),
                ),
                Text(
                  '${_analyses.length} total  •  ${_selected.length} selected',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasPending)
            TextButton(
              onPressed: _selectAllPending,
              style: TextButton.styleFrom(
                foregroundColor: kGreen,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                allPendingSelected ? 'Deselect all' : 'Select all pending',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: (!hasPending || _running) ? null : () => _run(),
            icon: _running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_running ? 'Running…' : 'Run all'),
            style: FilledButton.styleFrom(
              backgroundColor: kGreen,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('All', 'all'),
          const SizedBox(width: 8),
          _filterChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _filterChip('Done', 'done'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: kGreen,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
      checkmarkColor: Colors.white,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(
          _filter == 'all' ? 'No analyses yet' : 'Nothing here',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final row = items[i];
          final id = row['id'] as String;
          final isPending = row['status'] == 'pending';
          return _AnalysisRow(
            row: row,
            selected: _selected.contains(id),
            selectable: isPending,
            onToggle: isPending ? () => _toggleSelect(id) : null,
          );
        },
      ),
    );
  }

  // ── photos tab ────────────────────────────────────────────────────────────

  Widget _buildPhotosBody(AppLocalizations loc) {
    if (_photosLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
      onRefresh: _loadPhotos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _photos.length,
        itemBuilder: (_, i) {
          final row = _photos[i];
          final id = (row['id'] as num).toInt();
          return _PhotoSubmissionCard(
            row: row,
            isProcessing: _processingPhotoIds.contains(id),
            onApprove: () => _reviewPhoto(id, 'approved'),
            onReject: () => _reviewPhoto(id, 'rejected'),
          );
        },
      ),
    );
  }

  // ── reports tab ───────────────────────────────────────────────────────────

  Widget _buildReportsBody(AppLocalizations loc) {
    if (_reportsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (_, i) {
          final row = _reports[i];
          final id = (row['id'] as num).toInt();
          return _IngredientReportCard(
            row: row,
            isProcessing: _processingReportIds.contains(id),
            onResolve: () => _reviewReport(id, 'resolved'),
            onDismiss: () => _reviewReport(id, 'dismissed'),
            onOpenProduct: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ResultScreen(
                  product: null,
                  barcode: row['barcode'] as String,
                  adminReportedIngredients: List<String>.from(
                    row['reported_ingredients'] as List,
                  ),
                  adminReportExplanation: row['explanation'] as String?,
                ),
              ),
            ),
            loc: loc,
          );
        },
      ),
    );
  }

  // ── ingredients tab ───────────────────────────────────────────────────────

  Widget _buildIngredientsBody(AppLocalizations loc) {
    if (_contributionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
      onRefresh: _loadContributions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contributions.length,
        itemBuilder: (_, i) {
          final row = _contributions[i];
          final id = (row['id'] as num).toInt();
          return _ContributionCard(
            row: row,
            isProcessing: _processingContributionIds.contains(id),
            onApprove: () => _reviewContribution(id, 'approved'),
            onReject: () => _reviewContribution(id, 'rejected'),
          );
        },
      ),
    );
  }
}

// ── analysis row ─────────────────────────────────────────────────────────────

class _AnalysisRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool selected;
  final bool selectable;
  final VoidCallback? onToggle;

  const _AnalysisRow({
    required this.row,
    required this.selected,
    required this.selectable,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final status = AnalysisStatus.fromString(row['status'] as String? ?? '');
    final productName =
        (row['products'] as Map?)?['name'] as String? ?? 'Unknown product';
    final barcode = row['barcode'] as String? ?? '';
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');

    final (statusColor, statusBg) = switch (status) {
      AnalysisStatus.resolved => (Colors.green.shade700, Colors.green.shade50),
      AnalysisStatus.aiDone ||
      AnalysisStatus.communityReview ||
      AnalysisStatus.consulting => (Colors.blue.shade700, Colors.blue.shade50),
      AnalysisStatus.aiAnalyzing => (
        Colors.orange.shade700,
        Colors.orange.shade50,
      ),
      AnalysisStatus.pending => (Colors.grey.shade600, Colors.grey.shade100),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: selected ? kGreenSurface : null,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (selectable) ...[
                Checkbox(
                  value: selected,
                  onChanged: (_) => onToggle?.call(),
                  activeColor: kGreen,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
              ] else
                const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      barcode,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatAge(createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAge(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── photo submission card ─────────────────────────────────────────────────────

class _PhotoSubmissionCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PhotoSubmissionCard({
    required this.row,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final barcode = row['barcode'] as String? ?? '';
    final productName = row['product_name'] as String? ?? barcode;
    final imageType = row['image_type'] as String? ?? 'front';
    final submittedUrl = row['public_url'] as String? ?? '';
    final currentUrl = row['current_image_url'] as String?;
    final hasReplacement = currentUrl != null && currentUrl.isNotEmpty;
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');

    final typeColor = switch (imageType) {
      'ingredients' => Colors.orange.shade700,
      'nutrition' => Colors.purple.shade700,
      _ => Colors.blue.shade700,
    };
    final typeBg = switch (imageType) {
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
          // Image comparison: old on left, new on right (or just new if no old)
          if (hasReplacement)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _imagePanel(
                      context,
                      currentUrl,
                      'Current',
                      Colors.grey.shade700,
                    ),
                  ),
                  Container(width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: _imagePanel(
                      context,
                      submittedUrl,
                      'New',
                      Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            )
          else if (submittedUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _showFullscreen(context, submittedUrl),
              child: CachedNetworkImage(
                imageUrl: submittedUrl,
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
                        imageType,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (hasReplacement) ...[
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
                    if (createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatAge(createdAt),
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
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  barcode,
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

  String _formatAge(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── ingredient contribution card ─────────────────────────────────────────────

class _ContributionCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ContributionCard({
    required this.row,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final barcode = row['barcode'] as String? ?? '';
    final productName =
        (row['products'] as Map?)?['name'] as String? ?? barcode;
    final ingredientText = row['ingredient_text'] as String? ?? '';
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');

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
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    _formatAge(createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              barcode,
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
                  ingredientText,
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

  String _formatAge(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── ingredient report card ────────────────────────────────────────────────────

class _IngredientReportCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isProcessing;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;
  final VoidCallback onOpenProduct;
  final AppLocalizations loc;

  const _IngredientReportCard({
    required this.row,
    required this.isProcessing,
    required this.onResolve,
    required this.onDismiss,
    required this.onOpenProduct,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final barcode = row['barcode'] as String? ?? '';
    final productName = row['product_name'] as String? ?? barcode;
    final reported = List<String>.from(
      row['reported_ingredients'] as List? ?? [],
    );
    final explanation = row['explanation'] as String?;
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');

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
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    _formatAge(createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              barcode,
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
              children: reported
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
            if (explanation != null && explanation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                explanation,
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

  String _formatAge(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
