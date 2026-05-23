import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/database_service.dart';
import '../helpers/database_test_setup.dart';

/// Scan history is rendered by [StartScreen]'s home tab. Listing is covered here
/// at the DB layer; [start_home_tab_test] covers populated list UI with
/// [StartHomeTab.enableSwipeToDelete] disabled (Dismissible timers hang in tests).
void main() {
  setUpAll(initTestDatabase);

  setUp(clearTestScans);

  test('getRecentScans returns inserted scan for home tab display', () async {
    await DatabaseService.instance.insertScan(
      barcode: '1234567890123',
      productName: 'Test Halal Snack',
      isHalal: true,
    );

    final scans = await DatabaseService.instance.getRecentScans();
    expect(scans.length, 1);
    expect(scans.first['productName'], 'Test Halal Snack');
    expect(scans.first['isHalal'], isTrue);
  });
}
