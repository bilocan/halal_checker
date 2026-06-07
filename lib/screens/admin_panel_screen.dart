import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../localization/format_relative_time.dart';
import '../models/product_analysis.dart';
import '../services/analysis_service.dart';
import '../services/deep_analysis_feature_service.dart';
import 'admin/ai_approval_tab.dart';
import 'admin/ingredient_contribution_tab.dart';
import 'admin/ingredient_report_tab.dart';
import 'admin/photo_approval_tab.dart';
import 'admin/system_settings_tab.dart';
import 'rules_management_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _service = AnalysisService();
  int _tabIndex = 0;
  int _approvalsSubTabIndex = 0;

  static const int _tabApprovals = 0;
  static const int _tabRules = 1;
  static const int _tabReports = 2;
  static const int _tabSettings = 3;

  static const int _subAnalysis = 0;
  static const int _subPhotos = 1;
  static const int _subContributions = 2;
  static const int _subAiLookup = 3;

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
  bool _isSuperAdmin = false;
  bool _deepAnalysisEnabled = false;

  // ── GlobalKeys for imperative refresh from AppBar ─────────────────────────
  final _photosKey = GlobalKey<PhotoApprovalTabState>();
  final _ingredientsKey = GlobalKey<IngredientContributionTabState>();
  final _reportsKey = GlobalKey<IngredientReportTabState>();
  final _aiRequestsKey = GlobalKey<AiApprovalTabState>();
  final _settingsKey = GlobalKey<SystemSettingsTabState>();

  int get _settingsTabIndex => _tabSettings;

  int get _approvalsBadge {
    var total = _photoBadge + _contributionBadge + _aiRequestBadge;
    if (_deepAnalysisEnabled && _pendingCount > 0) total += _pendingCount;
    return total;
  }

  List<int> get _visibleApprovalSubTabs => _deepAnalysisEnabled
      ? [_subAnalysis, _subPhotos, _subContributions, _subAiLookup]
      : [_subPhotos, _subContributions, _subAiLookup];

  int get _currentLogicalSubTab {
    final tabs = _visibleApprovalSubTabs;
    if (tabs.isEmpty) return _subPhotos;
    final idx = _approvalsSubTabIndex.clamp(0, tabs.length - 1);
    return tabs[idx];
  }

  @override
  void initState() {
    super.initState();
    _initApprovals();
    _loadSuperAdmin();
  }

  Future<void> _initApprovals() async {
    final enabled = await DeepAnalysisFeatureService().isEnabled();
    if (!mounted) return;
    setState(() {
      _deepAnalysisEnabled = enabled;
      if (!enabled) {
        _approvalsSubTabIndex = 0;
        _analyses = [];
        _loading = false;
      }
    });
    if (enabled) {
      await _load();
    }
  }

  Future<void> _loadSuperAdmin() async {
    final isSuper = await _service.isSuperAdmin();
    if (!mounted) return;
    setState(() {
      _isSuperAdmin = isSuper;
      if (!_isSuperAdmin && _tabIndex == _settingsTabIndex) {
        _tabIndex = 0;
      }
    });
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
        SnackBar(
          content: Text(AppLocalizations.of(context).adminBatchRequestFailed),
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
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          errors > 0
              ? loc.adminBatchDoneWithErrors(done, skipped, errors)
              : loc.adminBatchDoneSummary(done, skipped),
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
          if (_tabIndex == _tabApprovals &&
              _currentLogicalSubTab == _subAnalysis &&
              _selected.isNotEmpty)
            TextButton.icon(
              onPressed: _running ? null : () => _run(ids: _selected.toList()),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                loc.runSelectedCount(_selected.length),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (_tabIndex == _tabApprovals &&
              _currentLogicalSubTab == _subAnalysis)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _load,
            ),
          if (_tabIndex == _tabApprovals && _currentLogicalSubTab == _subPhotos)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _photosKey.currentState?.refresh(),
            ),
          if (_tabIndex == _tabApprovals &&
              _currentLogicalSubTab == _subContributions)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _ingredientsKey.currentState?.refresh(),
            ),
          if (_tabIndex == _tabApprovals &&
              _currentLogicalSubTab == _subAiLookup)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _aiRequestsKey.currentState?.refresh(),
            ),
          if (_tabIndex == _tabReports)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _reportsKey.currentState?.refresh(),
            ),
          if (_isSuperAdmin && _tabIndex == _settingsTabIndex)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _settingsKey.currentState?.refresh(),
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
                _buildApprovalsBody(),
                const RulesManagementScreen(),
                IngredientReportTab(
                  key: _reportsKey,
                  onCountChanged: (n) => setState(() => _reportBadge = n),
                ),
                if (_isSuperAdmin) SystemSettingsTab(key: _settingsKey),
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
              label: loc.approvalsTab,
              icon: Icons.fact_check_outlined,
              index: _tabApprovals,
              badge: _approvalsBadge > 0 ? _approvalsBadge : null,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: loc.rulesEngineTab,
              icon: Icons.rule_outlined,
              index: _tabRules,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: loc.reportsTab,
              icon: Icons.flag_outlined,
              index: _tabReports,
              badge: _reportBadge > 0 ? _reportBadge : null,
            ),
          ),
          if (_isSuperAdmin)
            Expanded(
              child: _tabButton(
                label: loc.systemSettingsTab,
                icon: Icons.settings_outlined,
                index: _settingsTabIndex,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalsBody() {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        _buildApprovalsSubTabBar(loc),
        Expanded(
          child: switch (_currentLogicalSubTab) {
            _subAnalysis => _buildAnalysisBody(),
            _subPhotos => PhotoApprovalTab(
              key: _photosKey,
              onCountChanged: (n) => setState(() => _photoBadge = n),
            ),
            _subContributions => IngredientContributionTab(
              key: _ingredientsKey,
              onCountChanged: (n) => setState(() => _contributionBadge = n),
            ),
            _ => AiApprovalTab(
              key: _aiRequestsKey,
              onCountChanged: (n) => setState(() => _aiRequestBadge = n),
            ),
          },
        ),
      ],
    );
  }

  Widget _buildApprovalsSubTabBar(AppLocalizations loc) {
    final tabs = <({String label, int? badge})>[
      if (_deepAnalysisEnabled)
        (
          label: loc.analysisTab,
          badge: _pendingCount > 0 ? _pendingCount : null,
        ),
      (label: loc.photosTab, badge: _photoBadge > 0 ? _photoBadge : null),
      (
        label: loc.ingredientContributionsTab,
        badge: _contributionBadge > 0 ? _contributionBadge : null,
      ),
      (
        label: loc.aiIngredientsLookupTab,
        badge: _aiRequestBadge > 0 ? _aiRequestBadge : null,
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              _subTabButton(
                label: tabs[i].label,
                visibleIndex: i,
                badge: tabs[i].badge,
              ),
          ],
        ),
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
            if (badge != null) ...[const SizedBox(width: 4), _badgeChip(badge)],
          ],
        ),
      ),
    );
  }

  Widget _subTabButton({
    required String label,
    required int visibleIndex,
    int? badge,
  }) {
    final selected = _approvalsSubTabIndex == visibleIndex;
    return InkWell(
      onTap: () => setState(() => _approvalsSubTabIndex = visibleIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? kGreen : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? kGreen : Colors.grey.shade600,
              ),
            ),
            if (badge != null) ...[const SizedBox(width: 4), _badgeChip(badge)],
          ],
        ),
      ),
    );
  }

  Widget _badgeChip(int badge) {
    return Container(
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
    );
  }

  // ── analysis tab ──────────────────────────────────────────────────────────

  Widget _buildAnalysisBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                allPendingSelected
                    ? AppLocalizations.of(context).deselectAllPending
                    : AppLocalizations.of(context).selectAllPending,
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
            label: Text(
              _running
                  ? AppLocalizations.of(context).runningLabel
                  : AppLocalizations.of(context).runAll,
            ),
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
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip(loc.filterAll, 'all'),
          const SizedBox(width: 8),
          _filterChip(loc.filterPending, 'pending'),
          const SizedBox(width: 8),
          _filterChip(loc.filterDone, 'done'),
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
      final loc = AppLocalizations.of(context);
      return Center(
        child: Text(
          _filter == 'all' ? loc.noAnalysesYet : loc.filterNothingHere,
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
        (row['products'] as Map?)?['name'] as String? ?? loc.unknownProduct;
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
