import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/widgets.dart' show Key;

/// Stable keys for integration / E2E tests (see `integration_test/`).
class IntegrationTestKeys {
  IntegrationTestKeys._();

  static const startScan = Key('e2e-start-scan');
  static const homeManualEntry = Key('e2e-home-manual-entry');
  static const barcodeField = Key('e2e-barcode-field');
  static const barcodeSubmit = Key('e2e-barcode-submit');
  static const productNotFound = Key('e2e-product-not-found');

  /// [outcome] is `halal`, `haram`, or `unknown` (matches `test/barcodes.txt`).
  static Key resultStatus(String outcome) => ValueKey('e2e-result-$outcome');
}
