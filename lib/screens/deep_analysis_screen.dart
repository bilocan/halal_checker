import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../localization/app_localizations.dart';
import '../models/product_analysis.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import 'discussion_screen.dart';

class DeepAnalysisScreen extends StatefulWidget {
  final String productName;
  final String barcode;
  final ProductAnalysis analysis;

  const DeepAnalysisScreen({
    super.key,
    required this.productName,
    required this.barcode,
    required this.analysis,
  });

  @override
  State<DeepAnalysisScreen> createState() => _DeepAnalysisScreenState();
}

class _DeepAnalysisScreenState extends State<DeepAnalysisScreen> {
  late ProductAnalysis _analysis;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _analysis = widget.analysis;
  }

  Color _verdictColor(String verdict) => switch (verdict) {
    'halal' => kGreen,
    'haram' => Colors.red.shade700,
    'suspicious' => kAmber,
    _ => Colors.grey.shade600,
  };

  IconData _verdictIcon(String verdict) => switch (verdict) {
    'halal' => Icons.check_circle,
    'haram' => Icons.cancel,
    'suspicious' => Icons.warning_amber_rounded,
    _ => Icons.help_outline,
  };

  Color _confidenceBadgeColor(String confidence) => switch (confidence) {
    'high' => Colors.green.shade100,
    'medium' => Colors.orange.shade100,
    _ => Colors.grey.shade200,
  };

  Color _confidenceTextColor(String confidence) => switch (confidence) {
    'high' => Colors.green.shade800,
    'medium' => Colors.orange.shade800,
    _ => Colors.grey.shade700,
  };

  void _showChallengeSheet(IngredientAnalysis ingredient) {
    if (AuthService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signInToChallenge)),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _ChallengeSheet(barcode: widget.barcode, ingredient: ingredient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiResult = _analysis.aiAnalysis;
    final statusColor = switch (_analysis.status) {
      AnalysisStatus.resolved => kGreen,
      AnalysisStatus.aiDone ||
      AnalysisStatus.communityReview ||
      AnalysisStatus.consulting => Colors.blue.shade700,
      _ => Colors.orange.shade700,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Analysis'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Community discussion',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiscussionScreen(
                  barcode: widget.barcode,
                  productName: widget.productName,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product + status header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _analysis.status.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (_analysis.status == AnalysisStatus.resolved &&
                            _analysis.finalVerdict != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _verdictColor(
                                _analysis.finalVerdict!,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _analysis.finalVerdict!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _verdictColor(_analysis.finalVerdict!),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_analysis.finalVerdictReason != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _analysis.finalVerdictReason!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (aiResult != null) ...[
              const SizedBox(height: 12),
              // AI summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.purple.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aiResult.summary,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Ingredients (${aiResult.ingredients.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),

              // Per-ingredient cards
              ...aiResult.ingredients.asMap().entries.map((entry) {
                final idx = entry.key;
                final ing = entry.value;
                final isExpanded = _expanded.contains(idx);
                final color = _verdictColor(ing.verdict);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        onTap: () => setState(
                          () => isExpanded
                              ? _expanded.remove(idx)
                              : _expanded.add(idx),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                _verdictIcon(ing.verdict),
                                color: color,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ing.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ing.reason,
                                      maxLines: isExpanded ? null : 2,
                                      overflow: isExpanded
                                          ? null
                                          : TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _confidenceBadgeColor(
                                        ing.confidence,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      ing.confidence,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _confidenceTextColor(
                                          ing.confidence,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded) ...[
                        Divider(height: 1, color: color.withValues(alpha: 0.2)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ing.islamicBasis.isNotEmpty) ...[
                                _detailRow(
                                  icon: Icons.menu_book_outlined,
                                  label: 'Islamic basis',
                                  value: ing.islamicBasis,
                                  iconColor: Colors.teal.shade700,
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (ing.alternativeNames.isNotEmpty) ...[
                                _detailRow(
                                  icon: Icons.label_outline,
                                  label: 'Also known as',
                                  value: ing.alternativeNames.join(', '),
                                  iconColor: Colors.indigo.shade400,
                                ),
                                const SizedBox(height: 8),
                              ],
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _showChallengeSheet(ing),
                                  icon: const Icon(
                                    Icons.flag_outlined,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Challenge verdict',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ] else ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Analysis in progress…',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Open Community Discussion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade700),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiscussionScreen(
                      barcode: widget.barcode,
                      productName: widget.productName,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Challenge sheet ───────────────────────────────────────────────────────────

class _ChallengeSheet extends StatefulWidget {
  final String barcode;
  final IngredientAnalysis ingredient;

  const _ChallengeSheet({required this.barcode, required this.ingredient});

  @override
  State<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<_ChallengeSheet> {
  String? _claimedVerdict;
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final claimed = _claimedVerdict;
    final reason = _reasonController.text.trim();
    if (claimed == null || reason.isEmpty) return;

    setState(() => _submitting = true);
    final result = await CommunityService.submitChallenge(
      barcode: widget.barcode,
      ingredient: widget.ingredient.name,
      currentVerdict: widget.ingredient.verdict,
      claimedVerdict: claimed,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge submitted — thank you!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final verdicts = ['halal', 'haram', 'suspicious'];
    final colors = {
      'halal': kGreen,
      'haram': Colors.red.shade700,
      'suspicious': kAmber,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge: ${widget.ingredient.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            'Current verdict: ${widget.ingredient.verdict}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'What should the verdict be?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: verdicts.map((v) {
              final selected = _claimedVerdict == v;
              return ChoiceChip(
                label: Text(v),
                selected: selected,
                selectedColor: colors[v]?.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? colors[v] : null,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
                onSelected: (_) => setState(() => _claimedVerdict = v),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your reasoning',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText:
                  'Explain why you believe the verdict should change. Cite sources if possible.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed:
                  _submitting ||
                      _claimedVerdict == null ||
                      _reasonController.text.trim().isEmpty
                  ? null
                  : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Challenge'),
            ),
          ),
        ],
      ),
    );
  }
}
