import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/halal_rules_engine.dart';

void main() {
  final raw = File('test/fixtures/alcohol_trace_cases.json').readAsStringSync();
  final cases = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

  const engine = HalalRulesEngine();

  for (final c in cases) {
    test(c['description'] as String, () {
      final ingredients = (c['ingredients'] as List).cast<String>();
      final wantVerdict = c['verdict'] as String;
      final wantCanonicals = ((c['matched_canonicals'] as List).cast<String>()
        ..sort());

      final result = engine.analyzeIngredients(ingredients);

      final gotVerdict = switch (result.verdict) {
        HalalRuleVerdict.halal => 'halal',
        HalalRuleVerdict.haram => 'haram',
        HalalRuleVerdict.suspicious => 'suspicious',
        HalalRuleVerdict.unknown => 'unknown',
      };

      expect(gotVerdict, wantVerdict, reason: c['description']);

      final gotCanonicals = result.canonicals.values.toSet().toList()..sort();
      expect(gotCanonicals, wantCanonicals, reason: c['description']);
    });
  }
}
