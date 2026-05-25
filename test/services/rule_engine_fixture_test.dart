// Runs the shared engine-cases.json fixture against the Dart rule engine.
// The fixture file is the canonical source — the TypeScript engine runs the
// same cases in the web CI. If both pass, behavioural drift is caught early.
//
// To update test cases: edit test/fixtures/engine_cases.json and copy it to
// halal-checker-web/test/engine-cases.json (or vice versa).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/halal_rules_engine.dart';

void main() {
  final raw = File('test/fixtures/engine_cases.json').readAsStringSync();
  final cases = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

  final engine = const HalalRulesEngine();

  for (final c in cases) {
    test(c['description'] as String, () {
      final ingredients = (c['ingredients'] as List).cast<String>();
      final wantVerdict = c['verdict'] as String;
      final wantCanonicals = ((c['matched_canonicals'] as List).cast<String>()
        ..sort());

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
        reason: 'verdict mismatch for "${c['description']}"',
      );

      final gotCanonicals = result.matches.map((m) => m.canonical).toList()
        ..sort();

      expect(
        gotCanonicals,
        equals(wantCanonicals),
        reason: 'matched_canonicals mismatch for "${c['description']}"',
      );
    });
  }
}
