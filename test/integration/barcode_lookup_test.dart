// Integration test: looks up every barcode in test/barcodes.txt against the
// live API (Supabase Edge Function if credentials are available, otherwise
// direct OpenFoodFacts) and prints a result table.
//
// Run with credentials (recommended — mirrors the app exactly):
//   .\run_integration_test.ps1
//
// Run without credentials (keyword-only fallback):
//   flutter test test/integration/barcode_lookup_test.dart --timeout 120s
//
// Barcodes file format (test/barcodes.txt):
//   <barcode> [expected: halal|haram|unknown]  # optional comment
//   - expected outcome is optional; omit for a lookup-only run
//   - comma-separated barcodes on one line cannot have an expected outcome
//   - # starts a comment (inline or full-line)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/product_service.dart';
import 'package:halal_checker/services/test_product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// A parsed entry from barcodes.txt
typedef _Entry = ({String barcode, String? expected});

// A completed lookup result
typedef _Result = ({
  String barcode,
  String? expected,
  Product? product,
  String? error,
});

void main() {
  group('Barcode lookup (live API)', () {
    late List<_Entry> entries;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      TestProductRepository.dbPathOverride = inMemoryDatabasePath;
      SharedPreferences.setMockInitialValues({});

      final file = File('test/barcodes.txt');
      if (!file.existsSync()) {
        fail(
          'test/barcodes.txt not found. Create it with one barcode per line.',
        );
      }

      entries = file
          .readAsLinesSync()
          .map((line) {
            final commentIdx = line.indexOf('#');
            return commentIdx == -1 ? line : line.substring(0, commentIdx);
          })
          .expand((line) {
            final parts = line.split(',');
            // Comma-separated lines: no expected outcome supported
            if (parts.length > 1) {
              return parts
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .map((b) => (barcode: b, expected: null as String?));
            }
            // Single entry: may have optional expected outcome as second token
            final tokens = line.trim().split(RegExp(r'\s+'));
            if (tokens.isEmpty || tokens.first.isEmpty) return <_Entry>[];
            final barcode = tokens[0];
            final expected = tokens.length > 1
                ? _validateExpected(tokens[1])
                : null;
            return [(barcode: barcode, expected: expected)];
          })
          .toList();

      if (entries.isEmpty) {
        fail('test/barcodes.txt contains no barcodes.');
      }

      const sep =
          '──────────────────────────────────────────────────────────────────────';
      // ignore: avoid_print
      print('\n$sep');
      // ignore: avoid_print
      print(
        'Loaded ${entries.length} barcode(s): ${entries.map((e) => e.barcode).join(', ')}',
      );
      // ignore: avoid_print
      print(sep);
    });

    test('looks up all barcodes and asserts expected outcomes', () async {
      final service = ProductService();
      final results = <_Result>[];

      for (final entry in entries) {
        try {
          final product = await service.refreshProduct(entry.barcode);
          results.add((
            barcode: entry.barcode,
            expected: entry.expected,
            product: product,
            error: null,
          ));
        } catch (e) {
          results.add((
            barcode: entry.barcode,
            expected: entry.expected,
            product: null,
            error: e.toString(),
          ));
        }
      }

      _printResultTable(results);

      for (final r in results) {
        if (r.error != null) continue;
        final p = r.product;
        if (p == null) continue;

        // Consistency assertions
        expect(
          p.isHalal && p.isUnknown,
          isFalse,
          reason:
              'Barcode ${r.barcode}: isHalal and isUnknown cannot both be true',
        );
        if (p.ingredients.isNotEmpty) {
          expect(
            p.isUnknown,
            isFalse,
            reason: 'Barcode ${r.barcode}: has ingredients but isUnknown=true',
          );
        }
        if (p.haramIngredients.isNotEmpty) {
          expect(
            p.isHalal,
            isFalse,
            reason:
                'Barcode ${r.barcode}: haramIngredients non-empty but isHalal=true',
          );
        }

        // Expected outcome assertion
        if (r.expected != null) {
          final actual = _actualOutcome(p);
          expect(
            actual,
            r.expected,
            reason:
                'Barcode ${r.barcode} (${p.name}): '
                'expected ${r.expected} but got $actual',
          );
        }
      }
    });
  });
}

String? _validateExpected(String token) {
  const valid = {'halal', 'haram', 'unknown'};
  final lower = token.toLowerCase();
  return valid.contains(lower) ? lower : null;
}

String _actualOutcome(Product p) {
  if (p.isUnknown) return 'unknown';
  if (p.isHalal) return 'halal';
  return 'haram';
}

void _printResultTable(List<_Result> results) {
  const thick =
      '══════════════════════════════════════════════════════════════════════';
  const thin =
      '──────────────────────────────────────────────────────────────────────';
  // ignore: avoid_print
  print('\n$thick');
  // ignore: avoid_print
  print(' BARCODE LOOKUP RESULTS');
  // ignore: avoid_print
  print(thick);

  for (final r in results) {
    // ignore: avoid_print
    print('\nBarcode  : ${r.barcode}');
    if (r.expected != null) {
      // ignore: avoid_print
      print('Expected : ${r.expected}');
    }

    if (r.error != null) {
      // ignore: avoid_print
      print('Status   : ERROR');
      // ignore: avoid_print
      print('Detail   : ${r.error}');
    } else if (r.product == null) {
      // ignore: avoid_print
      print('Status   : NOT FOUND (not in any database)');
    } else {
      final p = r.product!;
      final outcome = _actualOutcome(p);
      final statusIcon = outcome == 'halal'
          ? '✅ HALAL'
          : outcome == 'haram'
          ? '❌ NOT HALAL'
          : '? UNKNOWN (no ingredient data)';
      final match = r.expected == null
          ? ''
          : outcome == r.expected
          ? '  ✓'
          : '  ✗ FAIL';
      // ignore: avoid_print
      print('Status   : $statusIcon$match');
      // ignore: avoid_print
      print('Name     : ${p.name}');
      // ignore: avoid_print
      print(
        'Ingredients (${p.ingredients.length}): '
        '${p.ingredients.isEmpty ? 'none' : p.ingredients.take(5).join(', ')}'
        '${p.ingredients.length > 5 ? ' …' : ''}',
      );
      if (p.haramIngredients.isNotEmpty) {
        // ignore: avoid_print
        print('HARAM    : ${p.haramIngredients.join(', ')}');
      }
      if (p.suspiciousIngredients.isNotEmpty) {
        // ignore: avoid_print
        print('Suspect  : ${p.suspiciousIngredients.join(', ')}');
      }
      // ignore: avoid_print
      print('Source   : ${p.analyzedByAI ? 'AI' : 'Keyword analysis'}');
    }

    // ignore: avoid_print
    print(thin);
  }

  final found = results
      .where((r) => r.product != null && r.error == null)
      .length;
  final notFound = results
      .where((r) => r.product == null && r.error == null)
      .length;
  final errors = results.where((r) => r.error != null).length;
  final unknown = results.where((r) => r.product?.isUnknown == true).length;
  final halal = results.where((r) => r.product?.isHalal == true).length;
  final haram = results
      .where(
        (r) =>
            r.product != null && !r.product!.isHalal && !r.product!.isUnknown,
      )
      .length;
  final passed = results.where((r) {
    if (r.expected == null || r.product == null) return false;
    return _actualOutcome(r.product!) == r.expected;
  }).length;
  final asserted = results
      .where((r) => r.expected != null && r.product != null)
      .length;

  // ignore: avoid_print
  print(
    '\nSUMMARY: ${results.length} barcode(s) — '
    '$found found ($halal halal, $haram haram, $unknown unknown) | '
    '$notFound not found | $errors error(s)'
    '${asserted > 0 ? ' | assertions $passed/$asserted passed' : ''}',
  );
  // ignore: avoid_print
  print('$thick\n');
}
