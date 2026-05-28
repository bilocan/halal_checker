import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  // Set to ':memory:' in tests to avoid parallel-isolate file contention.
  static String? testDatabasePath;

  Database? _db;
  Future<Database>? _opening;

  /// Closes the open database so the next access uses [testDatabasePath] again.
  static Future<void> resetForTesting() async {
    await instance._db?.close();
    instance._db = null;
    instance._opening = null;
  }

  /// Opens the DB once at startup so the home tab does not race on first access.
  Future<void> ensureInitialized() async {
    await database;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _opening ??= _open().then((db) {
      _db = db;
      return db;
    });
    try {
      return await _opening!;
    } catch (e) {
      _opening = null;
      rethrow;
    }
  }

  Future<String> _databaseFilePath() async {
    if (testDatabasePath != null) return testDatabasePath!;

    final databasesPath = await getDatabasesPath();
    final legacyPath = join(databasesPath, 'halal_scan.db');

    if (!Platform.isIOS) return legacyPath;

    // iOS file protection can block writes in the default folder (empty history).
    const folder = 'unprotected';
    final protectedDir = join(databasesPath, folder);
    if (!await Directory(protectedDir).exists()) {
      await SqfliteDarwin.createUnprotectedFolder(databasesPath, folder);
    }
    final path = join(protectedDir, 'halal_scan.db');

    final legacyFile = File(legacyPath);
    final migratedFile = File(path);
    if (await legacyFile.exists() && !await migratedFile.exists()) {
      try {
        await legacyFile.copy(path);
      } catch (e, stack) {
        debugPrint('[DatabaseService] legacy DB migrate failed: $e\n$stack');
      }
    }
    return path;
  }

  Future<Database> _open() async {
    final path = await _databaseFilePath();
    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        try {
          await db.execute('PRAGMA journal_mode=WAL');
        } catch (e) {
          debugPrint('[DatabaseService] WAL not enabled: $e');
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
      final countRow = await txn.rawQuery('SELECT COUNT(*) AS cnt FROM scans');
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
    final db = await database;
    final rows = await db.query(
      'scans',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(scanRowFromDb).toList();
  }
}
