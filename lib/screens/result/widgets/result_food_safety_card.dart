import 'package:flutter/material.dart';

import '../../../localization/app_localizations.dart';

class ResultFoodSafetyCard extends StatelessWidget {
  const ResultFoodSafetyCard({
    super.key,
    required this.allergensTags,
    required this.tracesTags,
    required this.additivesTags,
    required this.haramIngredients,
    required this.suspiciousIngredients,
    required this.haramAdditives,
    required this.suspiciousAdditives,
    required this.loc,
    this.initiallyExpanded = false,
  });

  final List<String> allergensTags;
  final List<String> tracesTags;
  final List<String> additivesTags;
  final List<String> haramIngredients;
  final List<String> suspiciousIngredients;
  final List<String> haramAdditives;
  final List<String> suspiciousAdditives;
  final AppLocalizations loc;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (allergensTags.isEmpty && tracesTags.isEmpty && additivesTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final parts = <String>[];
    if (allergensTags.isNotEmpty) {
      parts.add('${allergensTags.length} ${loc.allergens.toLowerCase()}');
    }
    if (additivesTags.isNotEmpty) {
      parts.add('${additivesTags.length} ${loc.additives.toLowerCase()}');
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: const Icon(Icons.health_and_safety_outlined),
        title: Text(
          '${loc.allergens} & ${loc.additives}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: parts.isEmpty
            ? null
            : Text(
                parts.join(' · '),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allergensTags.isNotEmpty) ...[
                _ChipSection(
                  label: loc.allergens,
                  tags: allergensTags,
                  labelFn: _parseSimpleTag,
                  colorFn: (tag) => _resolveColor(tag, _parseSimpleTag),
                ),
                const SizedBox(height: 12),
              ],
              if (tracesTags.isNotEmpty) ...[
                _ChipSection(
                  label: loc.mayContain,
                  tags: tracesTags,
                  labelFn: _parseSimpleTag,
                  colorFn: (tag) => _resolveColor(tag, _parseSimpleTag),
                ),
                const SizedBox(height: 12),
              ],
              if (additivesTags.isNotEmpty)
                _ChipSection(
                  label: loc.additives,
                  tags: additivesTags,
                  labelFn: _parseAdditiveTag,
                  colorFn: (tag) => _resolveAdditivesColor(tag),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static const _neutral = (
    chipColor: Color(0xFFF5F5F5),
    chipBorder: Color(0xFFBDBDBD),
    textColor: Color(0xFF424242),
  );

  static const _haram = (
    chipColor: Color(0xFFFFEBEE),
    chipBorder: Color(0xFFEF9A9A),
    textColor: Color(0xFFC62828),
  );

  static const _suspicious = (
    chipColor: Color(0xFFFFF3E0),
    chipBorder: Color(0xFFFFCC80),
    textColor: Color(0xFFE65100),
  );

  ({Color chipColor, Color chipBorder, Color textColor}) _resolveColor(
    String tag,
    String Function(String) labelFn,
  ) {
    final name = labelFn(tag).toLowerCase();
    final haramMatch = haramIngredients.any(
      (i) => i.toLowerCase().contains(name) || name.contains(i.toLowerCase()),
    );
    if (haramMatch) return _haram;
    final suspiciousMatch = suspiciousIngredients.any(
      (i) => i.toLowerCase().contains(name) || name.contains(i.toLowerCase()),
    );
    if (suspiciousMatch) return _suspicious;
    return _neutral;
  }

  ({Color chipColor, Color chipBorder, Color textColor}) _resolveAdditivesColor(
    String tag,
  ) {
    final slug = (tag.contains(':') ? tag.split(':').last : tag).toLowerCase();
    bool slugMatches(String entry) {
      final e = entry.toLowerCase();
      return e == slug || slug.startsWith('$e-') || e.startsWith('$slug-');
    }

    if (haramAdditives.any(slugMatches)) return _haram;
    if (suspiciousAdditives.any(slugMatches)) return _suspicious;
    return _neutral;
  }

  static String _parseSimpleTag(String tag) {
    final slug = tag.contains(':') ? tag.split(':').last : tag;
    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _parseAdditiveTag(String tag) {
    final slug = tag.contains(':') ? tag.split(':').last : tag;
    final match = RegExp(
      r'^(e\d+[a-z]?)-(.+)$',
      caseSensitive: false,
    ).firstMatch(slug);
    if (match == null) return _parseSimpleTag(tag);
    final eNum = match.group(1)!.toUpperCase();
    final name = match
        .group(2)!
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    return '$eNum · $name';
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.label,
    required this.tags,
    required this.labelFn,
    required this.colorFn,
  });

  final String label;
  final List<String> tags;
  final String Function(String) labelFn;
  final ({Color chipColor, Color chipBorder, Color textColor}) Function(String)
  colorFn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags.map((tag) {
            final colors = colorFn(tag);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.chipColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.chipBorder),
              ),
              child: Text(
                labelFn(tag),
                style: TextStyle(fontSize: 12, color: colors.textColor),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
