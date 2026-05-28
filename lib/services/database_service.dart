import 'dart:io';
import 'dart:math' show max;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'scan_history_diagnostics.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  // Set to ':memory:' in tests to avoid parallel-isolate file contention.
  static String? testDatabasePath;

  Database? _db;
  Future<Database>? _opening;
  String? _openedPath;
  String? _lastError;
  DateTime? _lastSuccessAt;

  /// Last error from open/load/save (shown in About → version tap).
  ScanHistoryDiagnostics get diagnostics => ScanHistoryDiagnostics(
    databasePath: _openedPath ?? testDatabasePath,
    scanCount: _lastScanCount,
    lastError: _lastError,
    lastSuccessAt: _lastSuccessAt,
  );

  int _lastScanCount = 0;

  void _recordSuccess(String path, {int? scanCount}) {
    _openedPath = path;
    _lastError = null;
    _lastSuccessAt = DateTime.now();
    if (scanCount != null) _lastScanCount = scanCount;
  }

  void _recordError(Object error, [StackTrace? stack]) {
    _lastError = stack != null ? '$error\n$stack' : error.toString();
    debugPrint('[DatabaseService] $error');
    if (stack != null) debugPrint(stack.toString());
  }

  /// Closes the open database so the next access uses [testDatabasePath] again.
  static Future<void> resetForTesting() async {
    await instance._db?.close();
    instance._db = null;
    instance._opening = null;
    instance._openedPath = null;
  }

  /// Closes and reopens (e.g. after iOS migration copied a richer file).
  Future<void> resetConnection() async {
    await _db?.close();
    _db = null;
    _opening = null;
    _openedPath = null;
  }

  /// Opens the DB once at startup so the home tab does not race on first access.
  Future<void> ensureInitialized() async {
    await database;
    await _refreshScanCount();
  }

  Future<void> _refreshScanCount() async {
    try {
      if (_db == null) return;
      final rows = await _db!.rawQuery('SELECT COUNT(*) AS cnt FROM scans');
      _lastScanCount = _readIntColumn(rows.first['cnt']);
    } catch (_) {}
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _opening ??= _open().then((db) {
      _db = db;
      return db;
    });
    try {
      return await _opening!;
    } catch (e, stack) {
      _opening = null;
      _recordError(e, stack);
      rethrow;
    }
  }

  /// iOS subfolder with [NSFileProtectionNone] (see sqflite Darwin troubleshooting).
  static const String iosDatabaseFolder = 'history_db';

  Future<String> _databaseFilePath() async {
    if (testDatabasePath != null) return testDatabasePath!;

    final databasesPath = await getDatabasesPath();
    final legacyPath = join(databasesPath, 'halal_scan.db');

    if (!Platform.isIOS) return legacyPath;

    // iOS file protection can block writes in the default Documents folder.
    // Always call the native helper so the folder gets NSFileProtectionNone.
    // (A prior build may have created `unprotected/` without that attribute.)
    await SqfliteDarwin.createUnprotectedFolder(
      databasesPath,
      iosDatabaseFolder,
    );
    final path = join(databasesPath, iosDatabaseFolder, 'halal_scan.db');

    await migrateBestIosDatabaseCopy(
      targetPath: path,
      sourcePaths: [
        join(databasesPath, 'unprotected', 'halal_scan.db'),
        legacyPath,
      ],
    );
    return path;
  }

  /// Copies the richest existing iOS scan DB into [targetPath].
  @visibleForTesting
  static Future<void> migrateBestIosDatabaseCopy({
    required String targetPath,
    required List<String> sourcePaths,
  }) async {
    var bestCount = await scanCountAtPath(targetPath);
    String? bestSourcePath;
    for (final sourcePath in sourcePaths) {
      if (sourcePath == targetPath) continue;
      final count = await scanCountAtPath(sourcePath);
      if (count > bestCount) {
        bestCount = count;
        bestSourcePath = sourcePath;
      }
    }
    if (bestSourcePath == null) return;

    try {
      await copySqliteDatabaseFiles(bestSourcePath, targetPath);
      debugPrint(
        '[DatabaseService] migrated $bestCount scans from $bestSourcePath',
      );
    } catch (e, stack) {
      debugPrint('[DatabaseService] iOS DB migrate failed: $e\n$stack');
    }
  }

  /// Copies main DB plus WAL sidecars after checkpoint (WAL-only data is common).
  @visibleForTesting
  static Future<void> copySqliteDatabaseFiles(
    String sourcePath,
    String targetPath,
  ) async {
    await checkpointWal(sourcePath);
    final target = File(targetPath);
    if (await target.exists()) {
      await target.delete();
    }
    for (final suffix in ['', '-wal', '-shm']) {
      final sidecar = File('$sourcePath$suffix');
      if (!await sidecar.exists()) continue;
      await sidecar.copy('$targetPath$suffix');
    }
  }

  @visibleForTesting
  static Future<void> checkpointWal(String path) async {
    if (!await File(path).exists()) return;
    final db = await openDatabase(path);
    try {
      await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    } finally {
      await db.close();
    }
  }

  @visibleForTesting
  static Future<int> scanCountAtPath(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    try {
      final db = await openDatabase(path, readOnly: true);
      try {
        final rows = await db.rawQuery('SELECT COUNT(*) AS cnt FROM scans');
        return _readIntColumn(rows.first['cnt']);
      } on DatabaseException {
        return 0;
      } finally {
        await db.close();
      }
    } catch (_) {
      return 0;
    }
  }

  Future<Database> _open() async {
    final path = await _databaseFilePath();
    if (_db != null && _openedPath != null && _openedPath != path) {
      await resetConnection();
    }
    var db = await _openDatabaseAt(path);
    _recordSuccess(path);
    await _refreshScanCount();

    if (testDatabasePath == null && Platform.isIOS && _lastScanCount == 0) {
      final databasesPath = await getDatabasesPath();
      final sources = [
        join(databasesPath, 'unprotected', 'halal_scan.db'),
        join(databasesPath, 'halal_scan.db'),
      ];
      var bestCount = 0;
      for (final source in sources) {
        if (source == path) continue;
        bestCount = max(bestCount, await scanCountAtPath(source));
      }
      if (bestCount > 0) {
        await migrateBestIosDatabaseCopy(
          targetPath: path,
          sourcePaths: sources,
        );
        await db.close();
        db = await _openDatabaseAt(path);
        _recordSuccess(path);
        await _refreshScanCount();
      }
    }
    return db;
  }

  Future<Database> _openDatabaseAt(String path) async {
    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        try {
          // WAL + file copy breaks iOS migration; DELETE is reliable for small DBs.
          final mode = Platform.isIOS ? 'DELETE' : 'WAL';
          await db.execute('PRAGMA journal_mode=$mode');
        } catch (e) {
          debugPrint('[DatabaseService] journal_mode not set: $e');
        }
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
        await db.execute(
          'CREATE INDEX idx_scans_timestamp ON scans(timestamp DESC)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE scans ADD COLUMN notes TEXT');
          await db.execute(
            'ALTER TABLE scans ADD COLUMN is_flagged INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE scans ADD COLUMN verdict TEXT');
        }
      },
    );
  }

  Future<void> insertScan({
    required String barcode,
    required String productName,
    required bool isHalal,
    String? verdict,
    String? notes,
    bool? isFlagged,
  }) async {
    final db = await database;
    // Preserve existing notes/flag unless explicitly provided
    String? existingNotes = notes;
    int existingFlagged = isFlagged != null ? (isFlagged ? 1 : 0) : 0;
    if (notes == null && isFlagged == null) {
      final existing = await db.query(
        'scans',
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
      if (existing.isNotEmpty) {
        existingNotes = existing.first['notes'] as String?;
        existingFlagged = _readIntColumn(existing.first['is_flagged']);
      }
    }
    try {
      await db.transaction((txn) async {
        await txn.delete('scans', where: 'barcode = ?', whereArgs: [barcode]);
        await txn.insert('scans', {
          'barcode': barcode,
          'product_name': productName,
          'is_halal': isHalal ? 1 : 0,
          'verdict': verdict,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'notes': existingNotes,
          'is_flagged': existingFlagged,
        });
        final countRow = await txn.rawQuery(
          'SELECT COUNT(*) AS cnt FROM scans',
        );
        final count = _readIntColumn(countRow.first['cnt']);
        if (count > 50) {
          await txn.rawDelete(
            'DELETE FROM scans WHERE id IN ('
            'SELECT id FROM scans ORDER BY timestamp ASC LIMIT ?'
            ')',
            [count - 50],
          );
        }
      });
      await _refreshScanCount();
      if (_openedPath != null)
        _recordSuccess(_openedPath!, scanCount: _lastScanCount);
    } catch (e, stack) {
      _recordError(e, stack);
      rethrow;
    }
  }

  /// Maps a SQLite row to the scan map used by the UI (tolerant of platform types).
  @visibleForTesting
  static Map<String, dynamic> scanRowFromDb(Map<String, Object?> row) {
    return {
      'barcode': row['barcode'] as String,
      'productName': row['product_name'] as String,
      'isHalal': _readIntColumn(row['is_halal']) == 1,
      'verdict': row['verdict'] as String?,
      'timestamp': _readIntColumn(row['timestamp']),
      'notes': row['notes'] as String?,
      'isFlagged': _readIntColumn(row['is_flagged']) == 1,
    };
  }

  static int _readIntColumn(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> updateScanNote(
    String barcode, {
    String? note,
    required bool isFlagged,
  }) async {
    final db = await database;
    final trimmed = note?.trim();
    await db.update(
      'scans',
      {
        'notes': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        'is_flagged': isFlagged ? 1 : 0,
      },
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
  }

  Future<Map<String, dynamic>?> getScanNote(String barcode) async {
    final db = await database;
    final rows = await db.query(
      'scans',
      columns: ['notes', 'is_flagged'],
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (rows.isEmpty) return null;
    return {
      'notes': rows.first['notes'] as String?,
      'isFlagged': (rows.first['is_flagged'] as int?) == 1,
    };
  }

  Future<void> deleteScan(String barcode) async {
    final db = await database;
    await db.delete('scans', where: 'barcode = ?', whereArgs: [barcode]);
  }

  Future<List<Map<String, dynamic>>> getRecentScans({int limit = 50}) async {
    try {
      final db = await database;
      final rows = await db.query(
        'scans',
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      final scans = rows.map(scanRowFromDb).toList();
      _lastScanCount = scans.length;
      if (_openedPath != null) {
        _recordSuccess(_openedPath!, scanCount: _lastScanCount);
      }
      return scans;
    } catch (e, stack) {
      _recordError(e, stack);
      rethrow;
    }
  }
}
