import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/widgets.dart' show Key;

/// Stable keys for integration / E2E tests (see `integration_test/`).
///
/// Grep `e2e-` for automatable UI touchpoints. Update [TESTING.md] UI E2E
/// coverage table when adding keys or barcode scenarios.
class IntegrationTestKeys {
  IntegrationTestKeys._();

  /// SCN-001 — Start home tab → open scanner.
  static const startScan = Key('e2e-start-scan');

  /// SCN-001 — Scanner / camera-unavailable fallback → manual barcode dialog.
  static const homeManualEntry = Key('e2e-home-manual-entry');

  /// SCN-001 — Manual entry dialog field.
  static const barcodeField = Key('e2e-barcode-field');

  /// SCN-001 — Manual entry dialog submit.
  static const barcodeSubmit = Key('e2e-barcode-submit');

  /// SCN-003 — Result screen not-found body (`expected: unknown` in barcodes file).
  static const productNotFound = Key('e2e-product-not-found');

  /// SCN-001 — Result bottom nav → pop to scanner (then back to start).
  static const resultHome = Key('e2e-result-home');

  /// SCN-001/002 — Result status banner (`halal` / `haram` / inconclusive `unknown`).
  static Key resultStatus(String outcome) => ValueKey('e2e-result-$outcome');
}
