import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../localization/format_relative_time.dart';
import '../models/product_analysis.dart';
import '../services/analysis_service.dart';
import 'admin/ai_approval_tab.dart';
import 'admin/ingredient_contribution_tab.dart';
import 'admin/ingredient_report_tab.dart';
import 'admin/photo_approval_tab.dart';
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

  // ── tab badge counts (updated by each tab via onCountChanged) ─────────────
  int _photoBadge = 0;
  int _contributionBadge = 0;
  int _reportBadge = 0;
  int _aiRequestBadge = 0;

  // ── GlobalKeys for imperative refresh from AppBar ─────────────────────────
  final _photosKey = GlobalKey<PhotoApprovalTabState>();
  final _ingredientsKey = GlobalKey<IngredientContributionTabState>();
  final _reportsKey = GlobalKey<IngredientReportTabState>();
  final _aiRequestsKey = GlobalKey<AiApprovalTabState>();

  @override
  void initState() {
    super.initState();
    _load();
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
              onPressed: () => _photosKey.currentState?.refresh(),
            ),
          if (_tabIndex == 3)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _ingredientsKey.currentState?.refresh(),
            ),
          if (_tabIndex == 4)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _reportsKey.currentState?.refresh(),
            ),
          if (_tabIndex == 5)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _aiRequestsKey.currentState?.refresh(),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(loc),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _buildAnalysisBody(),
                const RulesManagementScreen(),
                PhotoApprovalTab(
                  key: _photosKey,
                  onCountChanged: (n) => setState(() => _photoBadge = n),
                ),
                IngredientContributionTab(
                  key: _ingredientsKey,
                  onCountChanged: (n) => setState(() => _contributionBadge = n),
                ),
                IngredientReportTab(
                  key: _reportsKey,
                  onCountChanged: (n) => setState(() => _reportBadge = n),
                ),
                AiApprovalTab(
                  key: _aiRequestsKey,
                  onCountChanged: (n) => setState(() => _aiRequestBadge = n),
                ),
              ],
            ),
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
              badge: _photoBadge > 0 ? _photoBadge : null,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: loc.ingredientsTab,
              icon: Icons.list_alt_outlined,
              index: 3,
              badge: _contributionBadge > 0 ? _contributionBadge : null,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: loc.reportsTab,
              icon: Icons.flag_outlined,
              index: 4,
              badge: _reportBadge > 0 ? _reportBadge : null,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: 'AI Req.',
              icon: Icons.auto_awesome_outlined,
              index: 5,
              badge: _aiRequestBadge > 0 ? _aiRequestBadge : null,
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
            if (badge != null) ...[
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
    final loc = AppLocalizations.of(context);
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
                        formatRelativeTime(loc, createdAt),
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
}
