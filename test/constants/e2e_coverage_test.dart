import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps [test/e2e_coverage.json], [test/barcodes_e2e.txt], and
/// [lib/integration_test_keys.dart] in sync. Run via CI:
/// `flutter test test/constants/`
void main() {
  late Map<String, dynamic> registry;
  late String keysFile;
  late String barcodesFile;

  setUpAll(() {
    final jsonFile = File('test/e2e_coverage.json');
    if (!jsonFile.existsSync()) {
      fail('Missing test/e2e_coverage.json');
    }
    registry = jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
    keysFile = File('lib/integration_test_keys.dart').readAsStringSync();
    barcodesFile = File('test/barcodes_e2e.txt').readAsStringSync();
  });

  group('E2E coverage registry', () {
    test('e2e_coverage.json parses and lists automated scenarios', () {
      final automated = registry['automated_ui_e2e'] as List<dynamic>;
      expect(automated.length, greaterThanOrEqualTo(3));
      final ids = automated
          .map((s) => (s as Map<String, dynamic>)['id'] as String)
          .toList();
      expect(ids, containsAll(['SCN-001', 'SCN-002', 'SCN-003']));
    });

    test('every registered e2e key appears in integration_test_keys.dart', () {
      final keys = (registry['e2e_keys'] as List<dynamic>).cast<String>();
      final hasResultStatusTemplate = keysFile.contains(
        "ValueKey('e2e-result-\$outcome')",
      );
      for (final key in keys) {
        if (key.startsWith('e2e-result-')) {
          expect(
            hasResultStatusTemplate,
            isTrue,
            reason: 'resultStatus() must build keys like $key',
          );
          continue;
        }
        expect(
          keysFile,
          contains(key),
          reason: 'Add $key to lib/integration_test_keys.dart or remove from '
              'test/e2e_coverage.json',
        );
      }
    });

    test('integration_test_keys.dart has no undocumented e2e- keys', () {
      final documented = (registry['e2e_keys'] as List<dynamic>).cast<String>();
      final documentedSet = documented.toSet();
      final keyPattern = RegExp(r"'(e2e-[^']+)'");
      final inSource = keyPattern
          .allMatches(keysFile)
          .map((m) => m.group(1)!)
          .where((k) => !k.startsWith('e2e-result-'))
          .toSet();
      inSource.add('e2e-result-halal');
      inSource.add('e2e-result-haram');
      inSource.add('e2e-result-unknown');

      for (final key in inSource) {
        expect(
          documentedSet,
          contains(key),
          reason: 'Document $key in test/e2e_coverage.json e2e_keys',
        );
      }
    });

    test('barcodes_e2e.txt includes every scenario barcode_line', () {
      final automated = registry['automated_ui_e2e'] as List<dynamic>;
      for (final raw in automated) {
        final scenario = raw as Map<String, dynamic>;
        final line = scenario['barcode_line'] as String?;
        if (line == null) continue;
        expect(
          barcodesFile,
          contains(line.trim()),
          reason:
              '${scenario['id']}: add "$line" to test/barcodes_e2e.txt',
        );
      }
    });

    test('reports UI E2E gap count (informational)', () {
      final gaps = registry['gaps'] as List<dynamic>;
      final withoutE2e = gaps.where((g) {
        final m = g as Map<String, dynamic>;
        final v = m['ui_e2e'];
        return v == false || v == 'partial';
      }).length;
      // ignore: avoid_print
      print(
        'E2E coverage: ${(registry['automated_ui_e2e'] as List).length} '
        'automated scenario(s); $withoutE2e tracked gap(s) in e2e_coverage.json',
      );
    });
  });
}
