import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:halal_checker/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Clear all rows before each test — the singleton reuses the same DB.
    final db = await DatabaseService.instance.database;
    await db.delete('scans');
  });

  group('DatabaseService.insertScan', () {
    test('inserted record is returned by getRecentScans', () async {
      await DatabaseService.instance.insertScan(
        barcode: '1234567890',
        productName: 'Halal Chips',
        isHalal: true,
      );
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans.length, equals(1));
      expect(scans.first['barcode'], equals('1234567890'));
      expect(scans.first['productName'], equals('Halal Chips'));
      expect(scans.first['isHalal'], isTrue);
    });

    test('deduplicates same barcode — keeps only the latest entry', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'dup_bc',
        productName: 'Version 1',
        isHalal: true,
      );
      await DatabaseService.instance.insertScan(
        barcode: 'dup_bc',
        productName: 'Version 2',
        isHalal: false,
      );
      final scans = await DatabaseService.instance.getRecentScans();
      final matches = scans.where((s) => s['barcode'] == 'dup_bc').toList();
      expect(matches.length, equals(1));
      expect(matches.first['productName'], equals('Version 2'));
      expect(matches.first['isHalal'], isFalse);
    });

    test('stores isHalal false correctly', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'haram_bc',
        productName: 'Haram Product',
        isHalal: false,
      );
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans.first['isHalal'], isFalse);
    });

    test('keeps only 50 most recent records', () async {
      for (var i = 0; i < 55; i++) {
        await DatabaseService.instance.insertScan(
          barcode: 'bc_$i',
          productName: 'Product $i',
          isHalal: i.isEven,
        );
      }
      final scans = await DatabaseService.instance.getRecentScans(limit: 100);
      expect(scans.length, lessThanOrEqualTo(50));
    });
  });

  group('DatabaseService.deleteScan', () {
    test('removes the matching barcode', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'del_bc',
        productName: 'Delete Me',
        isHalal: true,
      );
      await DatabaseService.instance.deleteScan('del_bc');
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans.where((s) => s['barcode'] == 'del_bc'), isEmpty);
    });

    test('does not remove other records', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'keep_bc',
        productName: 'Keep Me',
        isHalal: true,
      );
      await DatabaseService.instance.insertScan(
        barcode: 'remove_bc',
        productName: 'Remove Me',
        isHalal: true,
      );
      await DatabaseService.instance.deleteScan('remove_bc');
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans.where((s) => s['barcode'] == 'keep_bc').length, equals(1));
    });

    test('no-ops gracefully when barcode does not exist', () async {
      await expectLater(
        DatabaseService.instance.deleteScan('nonexistent'),
        completes,
      );
    });
  });

  group('DatabaseService.getRecentScans', () {
    test('returns records ordered by timestamp descending', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'first_bc',
        productName: 'First',
        isHalal: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await DatabaseService.instance.insertScan(
        barcode: 'second_bc',
        productName: 'Second',
        isHalal: true,
      );
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans.first['barcode'], equals('second_bc'));
      expect(scans.last['barcode'], equals('first_bc'));
    });

    test('respects the limit parameter', () async {
      for (var i = 0; i < 5; i++) {
        await DatabaseService.instance.insertScan(
          barcode: 'limit_$i',
          productName: 'Product $i',
          isHalal: true,
        );
      }
      final scans = await DatabaseService.instance.getRecentScans(limit: 3);
      expect(scans.length, equals(3));
    });

    test('returns empty list when no scans exist', () async {
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans, isEmpty);
    });

    test('timestamp field is a positive integer', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'ts_bc',
        productName: 'Timestamp Test',
        isHalal: true,
      );
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans.first['timestamp'], isA<int>());
      expect(scans.first['timestamp'] as int, greaterThan(0));
    });
  });
}
