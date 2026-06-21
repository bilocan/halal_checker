part of '../rules_management_screen.dart';

// ── Rule editor bottom sheet ──────────────────────────────────────────────

class _RuleEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? rule;

  const _RuleEditorSheet({this.rule});

  @override
  State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<_RuleEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _canonicalCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _variantsCtrl = TextEditingController();
  final _translationsCtrl = TextEditingController();
  final _guideSlugsCtrl = TextEditingController();
  String _category = 'haram';
  bool _submitting = false;

  bool get _isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      _canonicalCtrl.text = widget.rule!['canonical'] as String;
      _reasonCtrl.text = widget.rule!['reason'] as String;
      _category = widget.rule!['category'] as String;
      final variants = widget.rule!['variants'] as List?;
      if (variants != null) {
        _variantsCtrl.text = variants.join(', ');
      }
      final translations = KeywordNormalization.parseTranslations(
        widget.rule!['translations'],
      );
      if (translations.isNotEmpty) {
        _translationsCtrl.text = KeywordNormalization.formatTranslations(
          translations,
        );
      }
      final guideSlugs = KeywordNormalization.parseGuideSlugs(
        widget.rule!['guide_slugs'],
      );
      if (guideSlugs.isNotEmpty) {
        _guideSlugsCtrl.text = guideSlugs.join(', ');
      }
    }
  }

  @override
  void dispose() {
    _canonicalCtrl.dispose();
    _reasonCtrl.dispose();
    _variantsCtrl.dispose();
    _translationsCtrl.dispose();
    _guideSlugsCtrl.dispose();
    super.dispose();
  }

  List<String> _parseVariants() {
    final raw = _variantsCtrl.text.trim();
    if (raw.isEmpty) return [];
    return raw
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _parseGuideSlugs() =>
      KeywordNormalization.parseGuideSlugsText(_guideSlugsCtrl.text);

  String? _validateGuideSlugs(String? _) {
    final raw = _guideSlugsCtrl.text.trim();
    if (raw.isEmpty) return null;
    for (final part in raw.split(RegExp(r'[,\n]'))) {
      final slug = part.trim();
      if (slug.isEmpty) continue;
      if (!KeywordNormalization.isValidGuideSlug(slug)) {
        return AppLocalizations.of(context).guideSlugInvalid;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final service = KeywordService();
    final guideLinkService = IngredientGuideLinkService();
    final variants = _parseVariants();
    final translations = KeywordNormalization.parseTranslationsText(
      _translationsCtrl.text,
    );
    final guideSlugs = _parseGuideSlugs();
    final canonical = _canonicalCtrl.text.trim().toLowerCase();
    bool ok;

    if (_isEditing) {
      ok = await service.updateRule(
        id: widget.rule!['id'] as String,
        canonical: _canonicalCtrl.text,
        category: _category,
        reason: _reasonCtrl.text,
        variants: variants,
        translations: translations,
      );
    } else {
      ok = await service.createRule(
        canonical: _canonicalCtrl.text,
        category: _category,
        reason: _reasonCtrl.text,
        variants: variants.isNotEmpty ? variants : null,
        translations: translations.isNotEmpty ? translations : null,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    final loc = AppLocalizations.of(context);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? loc.ruleUpdateFailed : loc.ruleCreateFailed,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final guidesOk = await guideLinkService.upsertGuideLinks(
      canonical: canonical,
      guideSlugs: guideSlugs,
    );
    if (guidesOk) {
      await ProductService().refreshGuideLinks();
    }

    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          guidesOk
              ? (_isEditing ? loc.ruleUpdated : loc.ruleCreated)
              : loc.guideLinksUpdateFailed,
        ),
        backgroundColor: guidesOk ? kGreen : Colors.orange,
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? loc.editRule : loc.addRule,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _canonicalCtrl,
                enabled: !_isEditing,
                decoration: InputDecoration(
                  labelText: loc.keywordLabel,
                  hintText: loc.keywordHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.keywordRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: loc.categoryLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'haram',
                    child: Text(loc.haramCategory),
                  ),
                  DropdownMenuItem(
                    value: 'suspicious',
                    child: Text(loc.suspiciousCategory),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonCtrl,
                decoration: InputDecoration(
                  labelText: loc.reasonLabel,
                  hintText: loc.reasonHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? loc.reasonRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _variantsCtrl,
                decoration: InputDecoration(
                  labelText: loc.variantsLabel,
                  hintText: loc.variantsHint,
                  border: const OutlineInputBorder(),
                  helperText: loc.variantsHelperText,
                  helperMaxLines: 2,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _translationsCtrl,
                decoration: InputDecoration(
                  labelText: loc.translationsLabel,
                  hintText: loc.translationsHint,
                  border: const OutlineInputBorder(),
                  helperText: loc.translationsHelperText,
                  helperMaxLines: 3,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _guideSlugsCtrl,
                decoration: InputDecoration(
                  labelText: loc.guideSlugsLabel,
                  hintText: loc.guideSlugsHint,
                  border: const OutlineInputBorder(),
                  helperText: loc.guideSlugsHelperText,
                  helperMaxLines: 3,
                ),
                maxLines: 2,
                validator: _validateGuideSlugs,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? loc.updateRule : loc.createRule,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
