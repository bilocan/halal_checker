import 'dart:io';

/// One barcode scenario from a barcodes file (same format as `test/barcodes.txt`).
typedef E2eBarcodeEntry = ({String barcode, String? expected});

/// Reads barcodes from [path] (default `test/barcodes_e2e.txt`).
List<E2eBarcodeEntry> loadE2eBarcodes({String path = 'test/barcodes_e2e.txt'}) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('$path not found');
  }

  return file
      .readAsLinesSync()
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
