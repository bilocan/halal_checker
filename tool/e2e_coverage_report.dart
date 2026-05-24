// ignore_for_file: avoid_print
//
// Prints a developer-friendly view of test/e2e_coverage.json.
//
//   dart run tool/e2e_coverage_report.dart
//   ./scripts/preview_e2e_coverage.sh

import 'dart:convert';
import 'dart:io';

void main() {
  const path = 'test/e2e_coverage.json';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path');
    exit(1);
  }

  final registry = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final automated = registry['automated_ui_e2e'] as List<dynamic>;
  final gaps = registry['gaps'] as List<dynamic>;
  final manual = registry['manual_device_tests'] as List<dynamic>? ?? [];
  final keys = (registry['e2e_keys'] as List<dynamic>).cast<String>();

  final automatedWithBarcode = automated.where((s) {
    final line = (s as Map<String, dynamic>)['barcode_line'];
    return line != null && line.toString().isNotEmpty;
  }).length;
  final gapNoE2e = gaps.where((g) {
    final v = (g as Map<String, dynamic>)['ui_e2e'];
    return v == false;
  }).length;
  final gapPartial = gaps.where((g) {
    final v = (g as Map<String, dynamic>)['ui_e2e'];
    return v == 'partial';
  }).length;

  print('');
  print('HalalScan UI E2E coverage (from $path)');
  print('${"=" * 60}');
  print('');
  print('Summary');
  print('  Automated scenarios (device): ${automated.length} '
      '($automatedWithBarcode with barcodes in barcodes_e2e.txt)');
  print('  E2E widget keys registered:  ${keys.length}');
  print('  Documented gaps:             ${gaps.length} '
      '($gapNoE2e not covered, $gapPartial partial)');
  print('  Manual device tests:         ${manual.length}');
  print('');
  print('How this file is used');
  print('  • You edit it when adding flows, keys, or gaps.');
  print('  • CI runs test/constants/e2e_coverage_test.dart — fails if JSON,');
  print('    integration_test_keys.dart, and barcodes_e2e.txt disagree.');
  print('  • Device test ui_barcode_flow_test.dart does NOT read this file;');
  print('    it runs barcodes from test/barcodes_e2e.txt only.');
  print('');
  print('${"─" * 60}');
  print('Automated UI E2E (./run_ui_e2e_test.sh)');
  print('${"─" * 60}');
  for (final raw in automated) {
    final s = raw as Map<String, dynamic>;
    final id = s['id'];
    final flow = s['flow'];
    final line = s['barcode_line'];
    final barcode = line == null ? '(no barcode yet)' : line;
    final status = line == null ? 'PLANNED' : 'ACTIVE';
    print('');
    print('  [$status] $id — $flow');
    print('          barcode: $barcode');
    if (s['test_file'] != null) {
      print('          test:    ${s['test_file']}');
    }
    if (s['screens'] != null) {
      print('          screens: ${(s['screens'] as List).join(', ')}');
    }
    if (s['keys'] != null) {
      print('          keys:    ${(s['keys'] as List).join(', ')}');
    }
    if (s['notes'] != null) {
      print('          note:    ${s['notes']}');
    }
  }
  print('');
  print('${"─" * 60}');
  print('Gaps (not fully covered by automated UI E2E)');
  print('${"─" * 60}');
  for (final raw in gaps) {
    final g = raw as Map<String, dynamic>;
    final ui = _flag(g['ui_e2e']);
    final widget = _flag(g['widget']);
    final pipe = _flag(g['pipeline']);
    print('');
    print('  ${g['area']}');
    if ((g['screens'] as List?)?.isNotEmpty ?? false) {
      print('    screens:  ${(g['screens'] as List).join(', ')}');
    }
    print('    ui_e2e: $ui  widget: $widget  pipeline: $pipe');
    if (g['notes'] != null) print('    note: ${g['notes']}');
  }
  if (manual.isNotEmpty) {
    print('');
    print('${"─" * 60}');
    print('Manual device tests (not in run_ui_e2e_test.sh)');
    print('${"─" * 60}');
    for (final raw in manual) {
      final m = raw as Map<String, dynamic>;
      print('  ${m['id']} — ${m['file']}');
      print('         ${m['covers']}');
    }
  }
  print('');
  print('Commands');
  print('  dart run tool/e2e_coverage_report.dart   # this report');
  print('  ./scripts/validate_e2e_coverage.sh       # CI sync check');
  print('  ./run_ui_e2e_test.sh                     # run on emulator');
  print('');
}

String _flag(Object? v) {
  if (v == true) return 'yes';
  if (v == false) return 'no ';
  if (v == 'partial') return 'part';
  return '${v ?? '?'}';
}
