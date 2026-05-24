import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/widgets.dart' show Key;

/// Stable keys for integration / E2E tests (see `integration_test/`).
///
/// Grep `e2e-` for automatable UI touchpoints. Update [TESTING.md],
/// `test/e2e_coverage.json`, and run `./scripts/validate_e2e_coverage.sh`.
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

  /// SCN-004 — Result screen not-found body (`expected: not_found` in barcodes file).
  static const productNotFound = Key('e2e-product-not-found');

  /// SCN-001 — Result bottom nav → pop to scanner (then back to start).
  static const resultHome = Key('e2e-result-home');

  /// SCN-001 — Scanner screen AppBar → pop to start home tab.
  static const scannerBack = Key('e2e-scanner-back');

  /// SCN-001/002/003 — Result banner (`halal` / `haram` / inconclusive `unknown`).
  static Key resultStatus(String outcome) => ValueKey('e2e-result-$outcome');
}
