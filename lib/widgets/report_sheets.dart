import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../services/ingredient_report_service.dart';
import '../services/issue_report_service.dart';

class ReportSheet extends StatefulWidget {
  final String barcode;
  final String productName;
  final String currentResult;
  final String initialNote;

  const ReportSheet({
    super.key,
    required this.barcode,
    required this.productName,
    required this.currentResult,
    this.initialNote = '',
  });

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  ExpectedResult? _selected;
  late final _noteController = TextEditingController(text: widget.initialNote);
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _currentLabel(AppLocalizations loc) {
    switch (widget.currentResult) {
      case 'halal':
        return loc.reportResultHalal;
      case 'haram':
        return loc.reportResultHaram;
      case 'non_food':
        return loc.reportResultNonFood;
      default:
        return loc.reportResultUnknown;
    }
  }

  Color _currentColor() {
    switch (widget.currentResult) {
      case 'halal':
        return kGreen;
      case 'haram':
        return Colors.red;
      case 'non_food':
        return Colors.blueGrey.shade600;
      default:
        return Colors.orange.shade700;
    }
  }

  Future<void> _submit(AppLocalizations loc) async {
    if (_selected == null) return;
    setState(() => _submitting = true);
    final result = await IssueReportService.reportWrongResult(
      barcode: widget.barcode,
      productName: widget.productName,
      currentResult: widget.currentResult,
      expectedResult: _selected!,
      note: _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? loc.reportSubmitted : loc.reportFailed),
        backgroundColor: result.success ? kGreen : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final options = [
      (ExpectedResult.halal, loc.reportResultHalal, kGreen),
      (ExpectedResult.haram, loc.reportResultHaram, Colors.red),
      (
        ExpectedResult.nonFood,
        loc.reportResultNonFood,
        Colors.blueGrey.shade600,
      ),
      (ExpectedResult.unknown, loc.reportResultUnknown, Colors.orange.shade700),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.reportWrongResultTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            loc.reportWrongResultSubtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            '${loc.currentResultLabel}:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _currentColor().withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _currentColor().withAlpha(100)),
            ),
            child: Text(
              _currentLabel(loc),
              style: TextStyle(
                color: _currentColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${loc.expectedResultLabel}:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final (value, label, color) = opt;
              final isSelected = _selected == value;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => setState(() => _selected = value),
                selectedColor: color,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: loc.optionalNote,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selected == null || _submitting)
                  ? null
                  : () => _submit(loc),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.orange.shade200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      loc.reportWrongResult,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class IngredientReportSheet extends StatefulWidget {
  final String barcode;
  final String productName;
  final List<String> ingredients;

  const IngredientReportSheet({
    super.key,
    required this.barcode,
    required this.productName,
    required this.ingredients,
  });

  @override
  State<IngredientReportSheet> createState() => _IngredientReportSheetState();
}

class _IngredientReportSheetState extends State<IngredientReportSheet> {
  final Set<String> _selected = {};
  final _explanationController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations loc) async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.reportWrongIngredientNoSelection)),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await IngredientReportService.submitReport(
      barcode: widget.barcode,
      productName: widget.productName,
      ingredients: _selected.toList(),
      explanation: _explanationController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? loc.reportWrongIngredientSubmitted
              : loc.reportWrongIngredientFailed,
        ),
        backgroundColor: ok ? kGreen : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.reportWrongIngredientTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            loc.reportWrongIngredientSubtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35,
            ),
            child: ListView(
              shrinkWrap: true,
              children: widget.ingredients.map((ingredient) {
                final checked = _selected.contains(ingredient);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (_) => setState(() {
                    if (checked) {
                      _selected.remove(ingredient);
                    } else {
                      _selected.add(ingredient);
                    }
                  }),
                  title: Text(ingredient, style: const TextStyle(fontSize: 13)),
                  activeColor: Colors.orange.shade700,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _explanationController,
            maxLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: loc.reportWrongIngredientExplanation,
              hintText: loc.reportWrongIngredientExplanationHint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : () => _submit(loc),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.orange.shade200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      loc.reportWrongIngredient,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
