// Exports built-in keyword rules to JSON for cross-project sync verification.
//
// Usage:
//   dart run tool/export_rules.dart                 # prints to stdout
//   dart run tool/export_rules.dart keyword-rules.json  # writes to file
//
// CI uploads the output to Supabase Storage; the web project downloads it
// and runs scripts/check-rules-sync.mjs to verify both engines match.

import 'dart:convert';
import 'dart:io';

import 'package:halal_checker/constants/ingredient_keywords.dart';

void main(List<String> args) {
  final output = JsonEncoder.withIndent('  ').convert({
    'haram': {
      for (final e in IngredientKeywords.haram.entries)
        e.key: {
          'reason': e.value,
          'variants': IngredientKeywords.haramVariants[e.key] ?? [e.key],
          'byLang':
              IngredientKeywords.haramByLang[e.key] ?? <String, List<String>>{},
        },
    },
    'suspicious': {
      for (final e in IngredientKeywords.suspicious.entries)
        e.key: {
          'reason': e.value,
          'variants': IngredientKeywords.suspiciousVariants[e.key] ?? [e.key],
          'byLang':
              IngredientKeywords.suspiciousByLang[e.key] ??
              <String, List<String>>{},
        },
    },
  });

  final dest = args.firstOrNull;
  if (dest == null || dest == '-') {
    stdout.writeln(output);
  } else {
    File(dest).writeAsStringSync('$output\n');
    stderr.writeln(
      'Exported ${IngredientKeywords.haram.length} haram + '
      '${IngredientKeywords.suspicious.length} suspicious rules to $dest',
    );
  }
}
