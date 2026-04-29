import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../services/keyword_service.dart';
import '../services/product_service.dart';

const _green = Color(0xFF2E7D32);
const _amber = Color(0xFFF57F17);

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  List<Map<String, dynamic>> _custom = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final result = await KeywordService().fetchCustomKeywords();
    if (mounted)
      setState(() {
        _custom = result;
        _loading = false;
      });
  }

  Map<String, String> get _customHaram => {
    for (final e in _custom)
      if (e['category'] == 'haram')
        e['canonical'] as String: e['reason'] as String,
  };

  Map<String, String> get _customSuspicious => {
    for (final e in _custom)
      if (e['category'] == 'suspicious')
        e['canonical'] as String: e['reason'] as String,
  };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.keywords),
          backgroundColor: _green,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: loc.haramTab),
              Tab(text: loc.suspiciousTab),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _KeywordList(
                    builtIn: ProductService.haramKeywords,
                    custom: _customHaram,
                    color: Colors.red.shade700,
                    icon: Icons.block,
                  ),
                  _KeywordList(
                    builtIn: ProductService.suspiciousKeywords,
                    custom: _customSuspicious,
                    color: _amber,
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: Text(loc.suggestKeyword),
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const _SuggestKeywordSheet(),
            );
            // Reload in case the suggestion was approved in same session
            _loadCustom();
          },
        ),
      ),
    );
  }
}

class _KeywordList extends StatelessWidget {
  final Map<String, String> builtIn;
  final Map<String, String> custom;
  final Color color;
  final IconData icon;

  const _KeywordList({
    required this.builtIn,
    required this.custom,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final allEntries = [...builtIn.entries, ...custom.entries];

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: allEntries.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
      itemBuilder: (_, i) {
        final e = allEntries[i];
        final isCustom = i >= builtIn.length;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(25),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Row(
            children: [
              Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (isCustom) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _green.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    loc.customBadge,
                    style: TextStyle(
                      fontSize: 10,
                      color: _green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(e.value),
        );
      },
    );
  }
}

class _SuggestKeywordSheet extends StatefulWidget {
  const _SuggestKeywordSheet();

  @override
  State<_SuggestKeywordSheet> createState() => _SuggestKeywordSheetState();
}

class _SuggestKeywordSheetState extends State<_SuggestKeywordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _keywordCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _category = 'haram';
  bool _submitting = false;

  @override
  void dispose() {
    _keywordCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final ok = await KeywordService().suggestKeyword(
      keyword: _keywordCtrl.text,
      category: _category,
      reason: _reasonCtrl.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? loc.suggestionSubmitted : loc.suggestionError),
        backgroundColor: ok ? _green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.suggestKeyword,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              loc.suggestKeywordHint,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _keywordCtrl,
              decoration: InputDecoration(
                labelText: loc.keywordLabel,
                hintText: loc.keywordHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.none,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? loc.keywordRequired : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: loc.categoryLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'haram',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(loc.haramCategory),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'suspicious',
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _amber,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(loc.suspiciousCategory),
                    ],
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                labelText: loc.reasonLabel,
                hintText: loc.reasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? loc.reasonRequired : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(loc.submit),
            ),
          ],
        ),
      ),
    );
  }
}
