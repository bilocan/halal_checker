import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../constants/ingredient_keywords.dart';
import '../localization/app_localizations.dart';
import '../localization/format_relative_time.dart';
import '../services/keyword_normalization.dart';
import '../services/keyword_service.dart';

part 'rules/rules_editor_sheet.dart';

class RulesManagementScreen extends StatefulWidget {
  const RulesManagementScreen({super.key});

  @override
  State<RulesManagementScreen> createState() => _RulesManagementScreenState();
}

class _RulesManagementScreenState extends State<RulesManagementScreen>
    with SingleTickerProviderStateMixin {
  final _service = KeywordService();
  late final TabController _tabCtrl;

  List<Map<String, dynamic>> _customRules = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingRules = true;
  bool _loadingSuggestions = true;
  String _ruleFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadRules();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    setState(() => _loadingRules = true);
    final rules = await _service.fetchAllRules();
    if (!mounted) return;
    setState(() {
      _customRules = rules;
      _loadingRules = false;
    });
  }

  Future<void> _loadSuggestions() async {
    setState(() => _loadingSuggestions = true);
    final suggestions = await _service.fetchSuggestions();
    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
      _loadingSuggestions = false;
    });
  }

  // ── Built-in rules helpers ──────────────────────────────────────────────

  List<MapEntry<String, String>> get _builtInHaram =>
      IngredientKeywords.haram.entries.toList();

  List<MapEntry<String, String>> get _builtInSuspicious =>
      IngredientKeywords.suspicious.entries.toList();

  List<MapEntry<String, String>> get _filteredBuiltIn {
    final all = [..._builtInHaram, ..._builtInSuspicious];
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where(
          (e) =>
              e.key.toLowerCase().contains(q) ||
              e.value.toLowerCase().contains(q),
        )
        .toList();
  }

  // ── Custom rules helpers ────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredCustom {
    var list = _customRules;
    if (_ruleFilter != 'all') {
      list = list.where((r) => r['category'] == _ruleFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (r) =>
                (r['canonical'] as String).toLowerCase().contains(q) ||
                (r['reason'] as String).toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  // ── CRUD actions ────────────────────────────────────────────────────────

  Future<void> _deleteRule(Map<String, dynamic> rule) async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteRuleTitle),
        content: Text(loc.deleteRuleConfirm(rule['canonical'] as String)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _service.deleteRule(rule['id'] as String);
    if (!mounted) return;
    _showSnack(ok ? loc.ruleDeleted : loc.ruleDeleteFailed, ok);
    if (ok) _loadRules();
  }

  Future<void> _approveSuggestion(Map<String, dynamic> suggestion) async {
    final loc = AppLocalizations.of(context);
    final keyword = suggestion['keyword'] as String;
    final existing = await _service.findRuleByAlias(keyword);

    Map<String, dynamic>? mergeTarget;
    if (existing != null &&
        (existing['canonical'] as String).toLowerCase() !=
            keyword.trim().toLowerCase()) {
      if (!mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.mergeKeywordTitle),
          content: Text(
            loc.mergeKeywordMessage(keyword, existing['canonical'] as String),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'new'),
              child: Text(loc.approveAsNewRule),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'merge'),
              style: FilledButton.styleFrom(backgroundColor: kGreen),
              child: Text(loc.mergeKeywordConfirm),
            ),
          ],
        ),
      );
      if (choice == null) return;
      if (choice == 'merge') mergeTarget = existing;
    } else if (existing != null) {
      mergeTarget = existing;
    }

    final ok = await _service.approveSuggestion(
      suggestion,
      mergeIntoExisting: mergeTarget,
    );
    if (!mounted) return;
    final msg = ok
        ? (mergeTarget != null ? loc.suggestionMerged : loc.suggestionApproved)
        : loc.suggestionApproveFailed;
    _showSnack(msg, ok);
    if (ok) {
      _loadRules();
      _loadSuggestions();
    }
  }

  Future<void> _rejectSuggestion(Map<String, dynamic> suggestion) async {
    final loc = AppLocalizations.of(context);
    final ok = await _service.deleteSuggestion(suggestion['id'] as String);
    if (!mounted) return;
    _showSnack(ok ? loc.suggestionRejected : loc.suggestionRejectFailed, ok);
    if (ok) _loadSuggestions();
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? kGreen : Colors.red),
    );
  }

  void _openRuleEditor({Map<String, dynamic>? rule}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RuleEditorSheet(rule: rule),
    );
    if (result == true) _loadRules();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        _buildSearchBar(),
        TabBar(
          controller: _tabCtrl,
          labelColor: kGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kGreen,
          tabs: [
            Tab(text: loc.customRulesTab),
            Tab(text: loc.builtInRulesTab),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.suggestionsTab),
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_suggestions.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildCustomRulesTab(loc),
              _buildBuiltInTab(loc),
              _buildSuggestionsTab(loc),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: loc.searchRules,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  // ── Custom rules tab ────────────────────────────────────────────────────

  Widget _buildCustomRulesTab(AppLocalizations loc) {
    return Column(
      children: [
        _buildRuleFilterRow(),
        Expanded(
          child: _loadingRules
              ? const Center(child: CircularProgressIndicator())
              : _filteredCustom.isEmpty
              ? Center(
                  child: Text(
                    loc.noCustomRules,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRules,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _filteredCustom.length,
                    itemBuilder: (_, i) =>
                        _buildCustomRuleTile(_filteredCustom[i], loc),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openRuleEditor(),
              icon: const Icon(Icons.add),
              label: Text(loc.addRule),
              style: FilledButton.styleFrom(
                backgroundColor: kGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ruleChip('All', 'all'),
          const SizedBox(width: 8),
          _ruleChip('Haram', 'haram'),
          const SizedBox(width: 8),
          _ruleChip('Suspicious', 'suspicious'),
        ],
      ),
    );
  }

  Widget _ruleChip(String label, String value) {
    final selected = _ruleFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _ruleFilter = value),
      selectedColor: kGreen,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
      checkmarkColor: Colors.white,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildCustomRuleTile(Map<String, dynamic> rule, AppLocalizations loc) {
    final canonical = rule['canonical'] as String;
    final category = rule['category'] as String;
    final reason = rule['reason'] as String;
    final variants = rule['variants'] as List?;
    final translations = KeywordNormalization.parseTranslations(
      rule['translations'],
    );
    final isHaram = category == 'haram';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isHaram ? Colors.red.shade50 : Colors.amber.shade50,
          child: Icon(
            isHaram ? Icons.block : Icons.warning_amber_rounded,
            color: isHaram ? Colors.red.shade700 : kAmber,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                canonical,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isHaram ? Colors.red.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isHaram ? Colors.red.shade700 : kAmber,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (variants != null && variants.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '${loc.variantsLabel}: ${variants.join(', ')}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (translations.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '${loc.translationsLabel}: ${KeywordNormalization.formatTranslations(translations)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') {
              _openRuleEditor(rule: rule);
            } else if (action == 'delete') {
              _deleteRule(rule);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 18),
                  const SizedBox(width: 8),
                  Text(loc.editRule),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Text(
                    loc.delete,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: variants != null && variants.isNotEmpty,
      ),
    );
  }

  // ── Built-in rules tab ──────────────────────────────────────────────────

  Widget _buildBuiltInTab(AppLocalizations loc) {
    final items = _filteredBuiltIn;
    if (items.isEmpty) {
      return Center(
        child: Text(
          loc.noMatchingRules,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
      itemBuilder: (_, i) {
        final e = items[i];
        final isHaram = IngredientKeywords.haram.containsKey(e.key);
        final variants = isHaram
            ? IngredientKeywords.haramVariants[e.key]
            : IngredientKeywords.suspiciousVariants[e.key];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isHaram
                ? Colors.red.shade50
                : Colors.amber.shade50,
            child: Icon(
              isHaram ? Icons.block : Icons.warning_amber_rounded,
              color: isHaram ? Colors.red.shade700 : kAmber,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  e.key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  loc.builtInBadge,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.value),
              if (variants != null && variants.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${loc.variantsLabel}: ${variants.join(', ')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          isThreeLine: variants != null && variants.isNotEmpty,
        );
      },
    );
  }

  // ── Suggestions tab ─────────────────────────────────────────────────────

  Widget _buildSuggestionsTab(AppLocalizations loc) {
    if (_loadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          loc.noSuggestions,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSuggestions,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _suggestions.length,
        itemBuilder: (_, i) => _buildSuggestionTile(_suggestions[i], loc),
      ),
    );
  }

  Widget _buildSuggestionTile(
    Map<String, dynamic> suggestion,
    AppLocalizations loc,
  ) {
    final keyword = suggestion['keyword'] as String;
    final category = suggestion['category'] as String;
    final reason = suggestion['reason'] as String;
    final variants = suggestion['variants'] as List?;
    final createdAt = DateTime.tryParse(
      suggestion['submitted_at'] as String? ?? '',
    );
    final isHaram = category == 'haram';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHaram ? Icons.block : Icons.warning_amber_rounded,
                  color: isHaram ? Colors.red.shade700 : kAmber,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    keyword,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isHaram ? Colors.red.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isHaram ? Colors.red.shade700 : kAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reason,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            if (variants != null && variants.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${loc.variantsLabel}: ${variants.join(', ')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                formatRelativeTime(loc, createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejectSuggestion(suggestion),
                  icon: Icon(Icons.close, size: 16, color: Colors.red.shade600),
                  label: Text(
                    loc.reject,
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _approveSuggestion(suggestion),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(loc.approve),
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    visualDensity: VisualDensity.compact,
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
