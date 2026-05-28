import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:halal_checker/services/database_service.dart';

// Coverage note (flutter test --coverage on database_service*.dart):
// Most logic is covered here and in database_service_notes_test.dart (~85%+).
// Remaining gaps are mostly iOS-only paths in database_service.dart:
//   - _databaseFilePath: SqfliteDarwin unprotected folder + legacy path list
//   - _open: empty target DB → migrateBestIosDatabaseCopy from legacy locations
//   - _open: resetConnection when _openedPath != new path (rare in production)
//   - onConfigure: journal_mode PRAGMA failure (caught and logged)
// These need a real iOS run or platform injection; ffi/desktop tests use
// testDatabasePath / non-iOS legacy path only.

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.testDatabasePath = ':memory:';
  });

  setUp(() async {
    await DatabaseService.resetForTesting();
    final db = await DatabaseService.instance.database;
    await db.delete('scans');
  });

  test('resetForTesting closes database so next access reopens', () async {
    final first = await DatabaseService.instance.database;
    await DatabaseService.resetForTesting();
    final second = await DatabaseService.instance.database;
    expect(identical(first, second), isFalse);
  });

  test('resetConnection closes database so next access reopens', () async {
    final first = await DatabaseService.instance.database;
    await DatabaseService.instance.resetConnection();
    final second = await DatabaseService.instance.database;
    expect(identical(first, second), isFalse);
  });

  test('database open failure clears in-flight open for retry', () async {
    await DatabaseService.resetForTesting();
    final blocker = File(
      p.join(
        Directory.systemTemp.path,
        'halal_blocker_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await blocker.writeAsString('not a directory');
    DatabaseService.testDatabasePath = p.join(blocker.path, 'nested.db');
    await expectLater(DatabaseService.instance.database, throwsA(anything));
    DatabaseService.testDatabasePath = ':memory:';
    await DatabaseService.resetForTesting();
    final scans = await DatabaseService.instance.getRecentScans();
    expect(scans, isEmpty);
    await blocker.delete();
  });

  test('ensureInitialized opens the database', () async {
    await DatabaseService.resetForTesting();
    await DatabaseService.instance.ensureInitialized();
    final scans = await DatabaseService.instance.getRecentScans();
    expect(scans, isEmpty);
  });

  test('opens default filesystem path when test override is null on non-iOS', () async {
    if (Platform.isIOS) return;

    final savedPath = DatabaseService.testDatabasePath;
    DatabaseService.testDatabasePath = null;
    addTearDown(() async {
      DatabaseService.testDatabasePath = savedPath;
      await DatabaseService.resetForTesting();
    });
    await DatabaseService.resetForTesting();

    await DatabaseService.instance.insertScan(
      barcode: 'default_path_bc',
      productName: 'Default path',
      isHalal: true,
    );
    final scans = await DatabaseService.instance.getRecentScans();
    expect(
      scans.any((s) => s['barcode'] == 'default_path_bc'),
      isTrue,
    );
    await DatabaseService.instance.deleteScan('default_path_bc');
  });

  test('concurrent access reuses a single in-flight open', () async {
    final results = await Future.wait([
      DatabaseService.instance.database,
      DatabaseService.instance.database,
      DatabaseService.instance.getRecentScans(),
    ]);
    expect(identical(results[0], results[1]), isTrue);
    expect(results[2], isEmpty);
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

    test('stores verdict when provided', () async {
      await DatabaseService.instance.insertScan(
        barcode: 'verdict_bc',
        productName: 'Cert Gap Snack',
        isHalal: false,
        verdict: 'nocert',
      );
      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans.first['verdict'], 'nocert');
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

  group('DatabaseService.scanRowFromDb', () {
    test('coerces bool and num integer columns from SQLite', () {
      final row = DatabaseService.scanRowFromDb({
        'barcode': '123',
        'product_name': 'Snack',
        'is_halal': true,
        'verdict': 'halal',
        'timestamp': 1.0,
        'notes': null,
        'is_flagged': 0,
      });
      expect(row['isHalal'], isTrue);
      expect(row['timestamp'], 1);
      expect(row['isFlagged'], isFalse);
    });

    test('coerces string integer columns from SQLite', () {
      final row = DatabaseService.scanRowFromDb({
        'barcode': '456',
        'product_name': 'Snack',
        'is_halal': '1',
        'verdict': null,
        'timestamp': '1700000000',
        'notes': null,
        'is_flagged': '0',
      });
      expect(row['isHalal'], isTrue);
      expect(row['timestamp'], 1700000000);
      expect(row['isFlagged'], isFalse);
    });

    test('treats null and unparseable integers as zero', () {
      final row = DatabaseService.scanRowFromDb({
        'barcode': '789',
        'product_name': 'Snack',
        'is_halal': null,
        'verdict': null,
        'timestamp': 'not-a-number',
        'notes': null,
        'is_flagged': null,
      });
      expect(row['isHalal'], isFalse);
      expect(row['timestamp'], 0);
      expect(row['isFlagged'], isFalse);
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

  group('DatabaseService.migrateBestIosDatabaseCopy', () {
    Future<String> _createScanDb(String path, {required String barcode}) async {
      final db = await openDatabase(
        path,
        version: 3,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE scans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              barcode TEXT NOT NULL,
              product_name TEXT NOT NULL,
              is_halal INTEGER NOT NULL DEFAULT 0,
              verdict TEXT,
              timestamp INTEGER NOT NULL,
              notes TEXT,
              is_flagged INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      );
      await db.insert('scans', {
        'barcode': barcode,
        'product_name': 'Product $barcode',
        'is_halal': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_flagged': 0,
      });
      await db.close();
      return path;
    }

    test('copies legacy file when target is missing', () async {
      final dir = await Directory.systemTemp.createTemp('halal_ios_migrate');
      final legacy = p.join(dir.path, 'legacy.db');
      final target = p.join(dir.path, 'target.db');
      await _createScanDb(legacy, barcode: 'legacy_bc');

      await DatabaseService.migrateBestIosDatabaseCopy(
        targetPath: target,
        sourcePaths: [legacy],
      );

      expect(await DatabaseService.scanCountAtPath(target), 1);
      expect(await DatabaseService.scanCountAtPath(legacy), 1);
      await deleteDatabase(target);
      await deleteDatabase(legacy);
      await dir.delete(recursive: true);
    });

    test('replaces empty target with richer source', () async {
      final dir = await Directory.systemTemp.createTemp('halal_ios_migrate');
      final source = p.join(dir.path, 'source.db');
      final target = p.join(dir.path, 'target.db');
      await _createScanDb(source, barcode: 'rich_bc');
      final empty = await openDatabase(
        target,
        version: 3,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE scans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              barcode TEXT NOT NULL,
              product_name TEXT NOT NULL,
              is_halal INTEGER NOT NULL DEFAULT 0,
              verdict TEXT,
              timestamp INTEGER NOT NULL,
              notes TEXT,
              is_flagged INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      );
      await empty.close();

      await DatabaseService.migrateBestIosDatabaseCopy(
        targetPath: target,
        sourcePaths: [source],
      );

      expect(await DatabaseService.scanCountAtPath(target), 1);
      await deleteDatabase(target);
      await deleteDatabase(source);
      await dir.delete(recursive: true);
    });

    test('skips when target already has more scans than sources', () async {
      final dir = await Directory.systemTemp.createTemp('halal_ios_migrate');
      final source = p.join(dir.path, 'source.db');
      final target = p.join(dir.path, 'target.db');
      await _createScanDb(source, barcode: 'only_one');
      await _createScanDb(target, barcode: 'target_a');
      final extra = await openDatabase(target);
      await extra.insert('scans', {
        'barcode': 'target_b',
        'product_name': 'Second',
        'is_halal': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_flagged': 0,
      });
      await extra.close();

      await DatabaseService.migrateBestIosDatabaseCopy(
        targetPath: target,
        sourcePaths: [source, target],
      );

      expect(await DatabaseService.scanCountAtPath(target), 2);
      expect(await DatabaseService.scanCountAtPath(source), 1);
      await deleteDatabase(target);
      await deleteDatabase(source);
      await dir.delete(recursive: true);
    });

    test('ignores copy failure without throwing', () async {
      final dir = await Directory.systemTemp.createTemp('halal_ios_migrate');
      final source = p.join(dir.path, 'source.db');
      await _createScanDb(source, barcode: 'fail_bc');

      await DatabaseService.migrateBestIosDatabaseCopy(
        targetPath: dir.path,
        sourcePaths: [source],
      );

      expect(await DatabaseService.scanCountAtPath(dir.path), 0);
      await deleteDatabase(source);
      await dir.delete(recursive: true);
    });
  });

  group('DatabaseService.scanCountAtPath', () {
    test('returns 0 for missing path', () async {
      expect(
        await DatabaseService.scanCountAtPath(
          p.join(
            Directory.systemTemp.path,
            'missing_${DateTime.now().microsecondsSinceEpoch}.db',
          ),
        ),
        0,
      );
    });

    test('returns 0 for non-database file', () async {
      final dir = await Directory.systemTemp.createTemp('halal_bad_db');
      final path = p.join(dir.path, 'not_sqlite.db');
      await File(path).writeAsString('not a database');
      expect(await DatabaseService.scanCountAtPath(path), 0);
      await dir.delete(recursive: true);
    });

    test('returns 0 when scans table is missing', () async {
      final dir = await Directory.systemTemp.createTemp('halal_no_scans');
      final path = p.join(dir.path, 'empty.db');
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('CREATE TABLE other (id INTEGER PRIMARY KEY)');
        },
      );
      await db.close();
      expect(await DatabaseService.scanCountAtPath(path), 0);
      await deleteDatabase(path);
      await dir.delete(recursive: true);
    });
  });

  group('DatabaseService.copySqliteDatabaseFiles', () {
    Future<String> _createWalDb(String path, String barcode) async {
      final db = await openDatabase(
        path,
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA journal_mode=WAL');
        },
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE scans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              barcode TEXT NOT NULL,
              product_name TEXT NOT NULL,
              is_halal INTEGER NOT NULL DEFAULT 0,
              verdict TEXT,
              timestamp INTEGER NOT NULL,
              notes TEXT,
              is_flagged INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      );
      await db.insert('scans', {
        'barcode': barcode,
        'product_name': 'WAL product',
        'is_halal': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_flagged': 0,
      });
      await db.close();
      return path;
    }

    test('copies main database and WAL sidecars', () async {
      final dir = await Directory.systemTemp.createTemp('halal_wal_copy');
      final source = p.join(dir.path, 'wal_source.db');
      final target = p.join(dir.path, 'wal_target.db');
      await _createWalDb(source, 'wal_bc');

      await DatabaseService.copySqliteDatabaseFiles(source, target);

      expect(await DatabaseService.scanCountAtPath(target), 1);
      await deleteDatabase(target);
      await deleteDatabase(source);
      await dir.delete(recursive: true);
    });
  });

  group('DatabaseService.checkpointWal', () {
    test('no-ops when database file is missing', () async {
      await expectLater(
        DatabaseService.checkpointWal(
          p.join(
            Directory.systemTemp.path,
            'missing_wal_${DateTime.now().microsecondsSinceEpoch}.db',
          ),
        ),
        completes,
      );
    });
  });

  group('DatabaseService — schema upgrade', () {
    test('migrates v1 database to v3 with notes and verdict columns', () async {
      final dir = await getDatabasesPath();
      final legacyPath = p.join(
        dir,
        'halal_scan_legacy_${DateTime.now().microsecondsSinceEpoch}.db',
      );

      final legacy = await openDatabase(
        legacyPath,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE scans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              barcode TEXT NOT NULL,
              product_name TEXT NOT NULL,
              is_halal INTEGER NOT NULL DEFAULT 0,
              timestamp INTEGER NOT NULL
            )
          ''');
        },
      );
      await legacy.insert('scans', {
        'barcode': 'legacy_bc',
        'product_name': 'Legacy Product',
        'is_halal': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await legacy.close();

      DatabaseService.testDatabasePath = legacyPath;
      await DatabaseService.resetForTesting();

      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans, hasLength(1));
      expect(scans.first['barcode'], 'legacy_bc');
      expect(scans.first['notes'], isNull);
      expect(scans.first['verdict'], isNull);

      await DatabaseService.instance.insertScan(
        barcode: 'legacy_bc',
        productName: 'Legacy Product',
        isHalal: true,
        verdict: 'halal',
        notes: 'Upgraded',
      );
      final updated = await DatabaseService.instance.getRecentScans();
      expect(updated.first['verdict'], 'halal');
      expect(updated.first['notes'], 'Upgraded');

      await DatabaseService.resetForTesting();
      await deleteDatabase(legacyPath);
      DatabaseService.testDatabasePath = ':memory:';
    });

    test('migrates v2 database to v3 with verdict column', () async {
      final dir = await getDatabasesPath();
      final legacyPath = p.join(
        dir,
        'halal_scan_v2_${DateTime.now().microsecondsSinceEpoch}.db',
      );

      final legacy = await openDatabase(
        legacyPath,
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE scans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              barcode TEXT NOT NULL,
              product_name TEXT NOT NULL,
              is_halal INTEGER NOT NULL DEFAULT 0,
              timestamp INTEGER NOT NULL,
              notes TEXT,
              is_flagged INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      );
      await legacy.insert('scans', {
        'barcode': 'v2_bc',
        'product_name': 'V2 Product',
        'is_halal': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'notes': 'Existing note',
        'is_flagged': 1,
      });
      await legacy.close();

      DatabaseService.testDatabasePath = legacyPath;
      await DatabaseService.resetForTesting();

      final scans = await DatabaseService.instance.getRecentScans();
      expect(scans, hasLength(1));
      expect(scans.first['verdict'], isNull);
      expect(scans.first['notes'], 'Existing note');
      expect(scans.first['isFlagged'], isTrue);

      await DatabaseService.resetForTesting();
      await deleteDatabase(legacyPath);
      DatabaseService.testDatabasePath = ':memory:';
    });
  });
}
