import 'dart:io';

import 'package:flutter/services.dart';

/// One barcode scenario from a barcodes file (same format as `test/barcodes.txt`).
typedef E2eBarcodeEntry = ({String barcode, String? expected});

/// Reads barcodes from [path] (default `test/barcodes_e2e.txt`).
///
/// UI integration tests run on a device/emulator, so the file must be listed in
/// [pubspec.yaml] assets. On the host VM, falls back to [File] if the asset is
/// missing (e.g. a custom path not bundled).
Future<List<E2eBarcodeEntry>> loadE2eBarcodes({
  String path = 'test/barcodes_e2e.txt',
}) async {
  final contents = await _readBarcodeFile(path);
  return _parseBarcodeContents(contents);
}

Future<String> _readBarcodeFile(String path) async {
  try {
    return await rootBundle.loadString(path);
  } catch (_) {
    final file = File(path);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
    throw StateError(
      '$path not found (add it under flutter.assets in pubspec.yaml for device E2E)',
    );
  }
}

List<E2eBarcodeEntry> _parseBarcodeContents(String contents) {
  return contents
      .split('\n')
      .map((line) {
        final commentIdx = line.indexOf('#');
        return commentIdx == -1 ? line : line.substring(0, commentIdx);
      })
      .expand((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return <E2eBarcodeEntry>[];

        final parts = trimmed.split(',');
        if (parts.length > 1) {
          return parts
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .map((b) => (barcode: b, expected: null as String?));
        }

        final tokens = trimmed.split(RegExp(r'\s+'));
        if (tokens.isEmpty || tokens.first.isEmpty) return <E2eBarcodeEntry>[];
        final barcode = tokens[0];
        final expected = tokens.length > 1
            ? _validateExpected(tokens[1])
            : null;
        return [(barcode: barcode, expected: expected)];
      })
      .toList();
}

String? _validateExpected(String token) {
  const valid = {'halal', 'haram', 'unknown'};
  final lower = token.toLowerCase();
  return valid.contains(lower) ? lower : null;
}
