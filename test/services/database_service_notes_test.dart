import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:halal_checker/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.testDatabasePath = ':memory:';
  });

  setUp(() async {
    final db = await DatabaseService.instance.database;
    await db.delete('scans');
  });

  // ── insertScan with notes and isFlagged ─────────────────────────────────

  group('DatabaseService.insertScan — notes and flags', () {
    test('stores note when provided', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'note_bc',
        productName: 'Product With Note',
        isHalal: true,
        notes: 'Contains palm oil',
      );
      final noteData = await DatabaseService.instance.getScanNote('note_bc');
      expect(noteData, isNotNull);
      expect(noteData!['notes'], 'Contains palm oil');
    });

    test('stores isFlagged when provided', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'flag_bc',
        productName: 'Flagged Product',
        isHalal: true,
        isFlagged: true,
      );
      final noteData = await DatabaseService.instance.getScanNote('flag_bc');
      expect(noteData, isNotNull);
      expect(noteData!['isFlagged'], isTrue);
    });

    test('preserves existing note on re-insert without note param', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'preserve_bc',
        productName: 'Product 1',
        isHalal: true,
        notes: 'Original note',
        isFlagged: true,
      );
      // Re-insert same barcode without notes/isFlagged
      await DatabaseService.instance.insertScan(
        barcode: 'preserve_bc',
        productName: 'Product 1 Updated',
        isHalal: false,
      );
      final noteData = await DatabaseService.instance.getScanNote(
        'preserve_bc',
      );
      expect(noteData, isNotNull);
      expect(noteData!['notes'], 'Original note');
      expect(noteData['isFlagged'], isTrue);
    });
  });

  // ── updateScanNote ──────────────────────────────────────────────────────

  group('DatabaseService.updateScanNote', () {
    test('updates note text', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'upd_bc',
        productName: 'To Update',
        isHalal: true,
      );
      await DatabaseService.instance.updateScanNote(
        'upd_bc',
        note: 'New note',
        isFlagged: false,
      );
      final noteData = await DatabaseService.instance.getScanNote('upd_bc');
      expect(noteData!['notes'], 'New note');
      expect(noteData['isFlagged'], isFalse);
    });

    test('sets isFlagged to true', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'flag_upd_bc',
        productName: 'Flag Me',
        isHalal: true,
      );
      await DatabaseService.instance.updateScanNote(
        'flag_upd_bc',
        note: 'Flagged',
        isFlagged: true,
      );
      final noteData = await DatabaseService.instance.getScanNote(
        'flag_upd_bc',
      );
      expect(noteData!['isFlagged'], isTrue);
    });

    test('clears note when set to null', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'clear_bc',
        productName: 'Clear Me',
        isHalal: true,
        notes: 'Will be removed',
      );
      await DatabaseService.instance.updateScanNote(
        'clear_bc',
        note: null,
        isFlagged: false,
      );
      final noteData = await DatabaseService.instance.getScanNote('clear_bc');
      expect(noteData!['notes'], isNull);
    });

    test('trims whitespace-only note to null', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'trim_bc',
        productName: 'Trim Me',
        isHalal: true,
      );
      await DatabaseService.instance.updateScanNote(
        'trim_bc',
        note: '   ',
        isFlagged: false,
      );
      final noteData = await DatabaseService.instance.getScanNote('trim_bc');
      expect(noteData!['notes'], isNull);
    });
  });

  // ── getScanNote ──────────────────────────────────────────────────────────

  group('DatabaseService.getScanNote', () {
    test('returns null when no scan exists for barcode', () async {
      final result = await DatabaseService.instance.getScanNote('nonexistent');
      expect(result, isNull);
    });

    test('returns notes and isFlagged for existing scan', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'get_note_bc',
        productName: 'Note Product',
        isHalal: true,
        notes: 'Some notes',
        isFlagged: true,
      );
      final result = await DatabaseService.instance.getScanNote('get_note_bc');
      expect(result, isNotNull);
      expect(result!['notes'], 'Some notes');
      expect(result['isFlagged'], isTrue);
    });

    test('returns isFlagged false when not flagged', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'no_flag_bc',
        productName: 'Not Flagged',
        isHalal: true,
      );
      final result = await DatabaseService.instance.getScanNote('no_flag_bc');
      expect(result, isNotNull);
      expect(result!['isFlagged'], isFalse);
    });
  });

  // ── getRecentScans — notes and isFlagged in output ──────────────────────

  group('DatabaseService.getRecentScans — notes and flags fields', () {
    test('includes notes field in scan result', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'scan_note_bc',
        productName: 'Noted Scan',
        isHalal: true,
        notes: 'Check source',
      );
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans.first['notes'], 'Check source');
    });

    test('includes isFlagged field in scan result', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'scan_flag_bc',
        productName: 'Flagged Scan',
        isHalal: true,
        isFlagged: true,
      );
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans.first['isFlagged'], isTrue);
    });
  });
}
