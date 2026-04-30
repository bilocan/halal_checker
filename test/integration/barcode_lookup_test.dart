// Integration test: looks up every barcode in test/barcodes.txt against the
// real Open Food Facts API and prints a result table.
//
// Run with:
//   flutter test test/integration/barcode_lookup_test.dart --timeout 120s
//
// The test file (test/barcodes.txt) accepts:
//   - One barcode per line
//   - Multiple barcodes comma-separated on one line
//   - Lines starting with # are treated as comments and ignored

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/product_service.dart';
import 'package:halal_checker/services/test_product_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Barcode lookup (live API)', () {
    late List<String> barcodes;

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
      barcodes = file
          .readAsLinesSync()
          .map((line) {
            final commentIdx = line.indexOf('#');
            return commentIdx == -1 ? line : line.substring(0, commentIdx);
          })
          .expand((line) => line.split(','))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (barcodes.isEmpty) {
        fail('test/barcodes.txt contains no barcodes.');
      }

      const sep =
          '──────────────────────────────────────────────────────────────────────';
      // ignore: avoid_print
      print('\n$sep');
      // ignore: avoid_print
      print('Loaded ${barcodes.length} barcode(s): ${barcodes.join(', ')}');
      // ignore: avoid_print
      print(sep);
    });

    test('looks up all barcodes and prints results', () async {
      final service = ProductService();
      final results = <({String barcode, Product? product, String? error})>[];

      for (final barcode in barcodes) {
        try {
          final product = await service.getProduct(barcode);
          results.add((barcode: barcode, product: product, error: null));
        } catch (e) {
          results.add((barcode: barcode, product: null, error: e.toString()));
        }
      }

      _printResultTable(results);

      // Sanity assertions — each found product must have a consistent state
      for (final r in results) {
        if (r.error != null) continue;
        final p = r.product;
        if (p == null) continue;

        // A product cannot simultaneously be halal AND unknown
        expect(
          p.isHalal && p.isUnknown,
          isFalse,
          reason:
              'Barcode ${r.barcode}: isHalal and isUnknown cannot both be true',
        );

        // If ingredients exist, it must not be unknown
        if (p.ingredients.isNotEmpty) {
          expect(
            p.isUnknown,
            isFalse,
            reason: 'Barcode ${r.barcode}: has ingredients but isUnknown=true',
          );
        }

        // If haram ingredients were found, isHalal must be false
        if (p.haramIngredients.isNotEmpty) {
          expect(
            p.isHalal,
            isFalse,
            reason:
                'Barcode ${r.barcode}: haramIngredients non-empty but isHalal=true',
          );
        }
      }
    });
  });
}

void _printResultTable(
  List<({String barcode, Product? product, String? error})> results,
) {
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
    print('\nBarcode : ${r.barcode}');

    if (r.error != null) {
      // ignore: avoid_print
      print('Status  : ERROR');
      // ignore: avoid_print
      print('Detail  : ${r.error}');
    } else if (r.product == null) {
      // ignore: avoid_print
      print('Status  : NOT FOUND (not in any database)');
    } else {
      final p = r.product!;
      final status = p.isUnknown
          ? '? UNKNOWN (no ingredient data)'
          : p.isHalal
          ? '✅ HALAL'
          : '❌ NOT HALAL';
      // ignore: avoid_print
      print('Status  : $status');
      // ignore: avoid_print
      print('Name    : ${p.name}');
      // ignore: avoid_print
      print(
        'Ingredients (${p.ingredients.length}): '
        '${p.ingredients.isEmpty ? 'none' : p.ingredients.take(5).join(', ')}${p.ingredients.length > 5 ? ' …' : ''}',
      );
      if (p.haramIngredients.isNotEmpty) {
        // ignore: avoid_print
        print('HARAM   : ${p.haramIngredients.join(', ')}');
      }
      if (p.suspiciousIngredients.isNotEmpty) {
        // ignore: avoid_print
        print('Suspect : ${p.suspiciousIngredients.join(', ')}');
      }
      // ignore: avoid_print
      print('Source  : ${p.analyzedByAI ? 'AI' : 'Keyword analysis'}');
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

  // ignore: avoid_print
  print(
    '\nSUMMARY: ${results.length} barcode(s) — '
    '$found found ($halal halal, $haram haram, $unknown unknown) | '
    '$notFound not found | $errors error(s)',
  );
  // ignore: avoid_print
  print('$thick\n');
}
