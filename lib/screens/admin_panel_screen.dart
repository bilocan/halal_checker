import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../models/product_analysis.dart';
import '../services/analysis_service.dart';
import '../services/product_image_service.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
    _loadPhotos();
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
    await ProductImageService.updateSubmissionStatus(id, status);
    if (!mounted) return;
    setState(() {
      _processingPhotoIds.remove(id);
      _photos.removeWhere((p) => (p['id'] as num).toInt() == id);
    });
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
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(loc),
          Expanded(
            child: switch (_tabIndex) {
              0 => _buildAnalysisBody(),
              1 => const RulesManagementScreen(),
              _ => _buildPhotosBody(loc),
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
      onTap: () => setState(() => _tabIndex = index),
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
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? kGreen : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? kGreen : Colors.grey.shade600,
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
    final publicUrl = row['public_url'] as String? ?? '';
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
          if (publicUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: publicUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder: (_, url) => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, url, err) => const SizedBox(
                height: 100,
                child: Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
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

  String _formatAge(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
