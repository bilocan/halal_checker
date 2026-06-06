// Table-driven negation coverage — shared fixture with Deno (negation_cases.json).
// Covers pre-negation (before keyword), post-negation (after keyword), suspicious
// keywords, and negative controls (real pork must still flag).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/halal_rules_engine.dart';

void main() {
  final raw = File('test/fixtures/negation_cases.json').readAsStringSync();
  final cases = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

  const engine = HalalRulesEngine();

  group('negation suppression fixture', () {
    for (final c in cases) {
      test(c['description'] as String, () {
        final ingredients = (c['ingredients'] as List).cast<String>();
        final wantVerdict = c['verdict'] as String;
        final wantCanonicals =
            ((c['matched_canonicals'] as List?) ?? const []).cast<String>()
              ..sort();

        final result = engine.analyzeIngredients(ingredients);

        final gotVerdict = switch (result.verdict) {
          HalalRuleVerdict.haram => 'haram',
          HalalRuleVerdict.suspicious => 'suspicious',
          HalalRuleVerdict.halal => 'halal',
          HalalRuleVerdict.unknown => 'halal',
        };

        expect(
          gotVerdict,
          equals(wantVerdict),
          reason: 'verdict for "${c['description']}"',
        );

        final gotCanonicals = result.matches.map((m) => m.canonical).toList()
          ..sort();

        expect(
          gotCanonicals,
          equals(wantCanonicals),
          reason: 'matched_canonicals for "${c['description']}"',
        );
      });
    }
  });
}
