part of '../rules_management_screen.dart';

// ── Guide links editor (built-in or custom canonical) ───────────────────

class _GuideLinksEditorSheet extends StatefulWidget {
  final String canonical;
  final List<String> initialDbSlugs;

  const _GuideLinksEditorSheet({
    required this.canonical,
    required this.initialDbSlugs,
  });

  @override
  State<_GuideLinksEditorSheet> createState() => _GuideLinksEditorSheetState();
}

class _GuideLinksEditorSheetState extends State<_GuideLinksEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _guideSlugsCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDbSlugs.isNotEmpty) {
      _guideSlugsCtrl.text = widget.initialDbSlugs.join(', ');
    }
  }

  @override
  void dispose() {
    _guideSlugsCtrl.dispose();
    super.dispose();
  }

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

    final slugs = KeywordNormalization.parseGuideSlugsText(
      _guideSlugsCtrl.text,
    );
    final ok = await IngredientGuideLinkService().upsertGuideLinks(
      canonical: widget.canonical,
      guideSlugs: slugs,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    final loc = AppLocalizations.of(context);
    if (ok) {
      await ProductService().refreshGuideLinks();
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.guideLinksUpdated), backgroundColor: kGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.guideLinksUpdateFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final builtIn = IngredientGuides.byCanonical[widget.canonical] ?? const [];

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
                      loc.editGuideLinks,
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
              const SizedBox(height: 8),
              Text(
                widget.canonical,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              if (builtIn.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${loc.guideSlugsLabel} (${loc.builtInBadge}): ${builtIn.join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _guideSlugsCtrl,
                decoration: InputDecoration(
                  labelText: loc.guideSlugsLabel,
                  hintText: loc.guideSlugsHint,
                  border: const OutlineInputBorder(),
                  helperText: loc.guideSlugsHelperText,
                  helperMaxLines: 3,
                ),
                maxLines: 3,
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
                        loc.updateRule,
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
