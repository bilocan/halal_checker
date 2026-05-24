import 'package:flutter/material.dart';

import '../app_colors.dart';

abstract final class ProductLabelChips {
  static List<Widget> build(List<String> rawLabels) {
    if (rawLabels.isEmpty) return [];

    final lower = rawLabels.map((l) => l.toLowerCase()).toList();
    final chips = <Widget>[];
    final usedRaw = <String>{};

    void addKnown(List<String> patterns, String label) {
      final matched = <String>[];
      for (var i = 0; i < rawLabels.length; i++) {
        if (patterns.any((p) => lower[i].contains(p))) {
          matched.add(rawLabels[i]);
        }
      }
      if (matched.isEmpty) return;
      usedRaw.addAll(matched);
      final chip = _buildKnownChip(label);
      if (chip != null) chips.add(chip);
    }

    // Vegan takes priority over Vegetarian (vegan ⊃ vegetarian)
    if (lower.any((l) => l.contains('vegan'))) {
      for (var i = 0; i < rawLabels.length; i++) {
        if (lower[i].contains('vegan') || lower[i].contains('vegetarian')) {
          usedRaw.add(rawLabels[i]);
        }
      }
      chips.add(_buildKnownChip('Vegan')!);
    } else {
      addKnown(['vegetarian'], 'Vegetarian');
    }

    addKnown(['fair trade', 'fair-trade', 'fairtrade'], 'Fair Trade');
    addKnown(['organic'], 'Organic');
    addKnown(['gluten free', 'gluten-free', 'glutenfree'], 'Gluten Free');
    addKnown(['non gmo', 'non-gmo', 'gmo free', 'gmo-free'], 'Non-GMO');
    addKnown([
      'palm oil free',
      'palm-oil-free',
      'no palm oil',
      'no-palm-oil',
    ], 'Palm Oil Free');
    addKnown([
      'rainforest alliance',
      'rainforest-alliance',
    ], 'Rainforest Alliance');
    addKnown(['kosher'], 'Kosher');
    addKnown(['lactose free', 'lactose-free'], 'Lactose Free');
    addKnown(['dairy free', 'dairy-free'], 'Dairy Free');
    addKnown(['sugar free', 'sugar-free'], 'Sugar Free');

    // Halal labels are already covered by the main verdict — skip them here
    final skipPatterns = ['halal', 'haram'];
    final seenDisplay = <String>{};

    for (final raw in rawLabels) {
      if (usedRaw.contains(raw)) continue;
      final l = raw.toLowerCase();
      if (skipPatterns.any((p) => l.contains(p))) continue;

      final display = _formatRawLabel(raw);
      if (display.length < 3) continue;
      if (!seenDisplay.add(display)) continue;

      chips.add(_buildGenericChip(display));
    }

    return chips;
  }

  static String _formatRawLabel(String raw) {
    var s = raw.replaceAll(RegExp(r'^[a-z]{2,3}:'), '');
    s = s.replaceAll(RegExp(r'[-_]'), ' ').trim();
    if (s.isEmpty) return '';
    return s
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  static Widget _buildGenericChip(String label) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
      ),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  static Widget? _buildKnownChip(String label) {
    switch (label) {
      case 'Vegan':
        return const Chip(
          avatar: Icon(Icons.eco, size: 18, color: kGreen),
          label: Text('Vegan'),
          backgroundColor: kGreenSurface,
        );
      case 'Vegetarian':
        return const Chip(
          avatar: Icon(Icons.grass, size: 18, color: kGreen),
          label: Text('Vegetarian'),
          backgroundColor: kGreenSurface,
        );
      case 'Fair Trade':
        return Chip(
          avatar: const Icon(Icons.handshake, size: 18, color: Colors.brown),
          label: const Text('Fair Trade'),
          backgroundColor: Colors.brown.shade50,
        );
      case 'Organic':
        return Chip(
          avatar: const Icon(Icons.spa, size: 18, color: Colors.teal),
          label: const Text('Organic'),
          backgroundColor: Colors.teal.shade50,
        );
      case 'Gluten Free':
        return Chip(
          avatar: const Icon(
            Icons.health_and_safety,
            size: 18,
            color: Colors.orange,
          ),
          label: const Text('Gluten Free'),
          backgroundColor: Colors.orange.shade50,
        );
      case 'Non-GMO':
        return Chip(
          avatar: const Icon(Icons.nature, size: 18, color: Colors.green),
          label: const Text('Non-GMO'),
          backgroundColor: Colors.green.shade50,
        );
      case 'Palm Oil Free':
        return Chip(
          avatar: const Icon(Icons.block, size: 18, color: Colors.deepOrange),
          label: const Text('Palm Oil Free'),
          backgroundColor: Colors.deepOrange.shade50,
        );
      case 'Rainforest Alliance':
        return Chip(
          avatar: const Icon(Icons.forest, size: 18, color: Colors.green),
          label: const Text('Rainforest Alliance'),
          backgroundColor: Colors.green.shade50,
        );
      case 'Kosher':
        return Chip(
          avatar: const Icon(Icons.verified, size: 18, color: Colors.blue),
          label: const Text('Kosher'),
          backgroundColor: Colors.blue.shade50,
        );
      case 'Lactose Free':
        return Chip(
          avatar: const Icon(
            Icons.water_drop,
            size: 18,
            color: Colors.lightBlue,
          ),
          label: const Text('Lactose Free'),
          backgroundColor: Colors.lightBlue.shade50,
        );
      case 'Dairy Free':
        return Chip(
          avatar: const Icon(Icons.water_drop, size: 18, color: Colors.cyan),
          label: const Text('Dairy Free'),
          backgroundColor: Colors.cyan.shade50,
        );
      case 'Sugar Free':
        return Chip(
          avatar: const Icon(
            Icons.remove_circle_outline,
            size: 18,
            color: Colors.pink,
          ),
          label: const Text('Sugar Free'),
          backgroundColor: Colors.pink.shade50,
        );
      default:
        return null;
    }
  }
}
