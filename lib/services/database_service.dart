import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  // Set to ':memory:' in tests to avoid parallel-isolate file contention.
  static String? testDatabasePath;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = testDatabasePath ?? join(dir, 'halal_scan.db');
    return openDatabase(
      path,
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
      },
    );
  }

  Future<void> insertScan({
    required String barcode,
    required String productName,
    required bool isHalal,
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
        existingFlagged = (existing.first['is_flagged'] as int?) ?? 0;
      }
    }
    await db.delete('scans', where: 'barcode = ?', whereArgs: [barcode]);
    await db.insert('scans', {
      'barcode': barcode,
      'product_name': productName,
      'is_halal': isHalal ? 1 : 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'notes': existingNotes,
      'is_flagged': existingFlagged,
    });
    // Keep only the 50 most recent scans
    await db.execute('''
      DELETE FROM scans WHERE id NOT IN (
        SELECT id FROM scans ORDER BY timestamp DESC LIMIT 50
      )
    ''');
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
    return rows
        .map(
          (row) => {
            'barcode': row['barcode'] as String,
            'productName': row['product_name'] as String,
            'isHalal': (row['is_halal'] as int) == 1,
            'timestamp': row['timestamp'] as int,
            'notes': row['notes'] as String?,
            'isFlagged': (row['is_flagged'] as int?) == 1,
          },
        )
        .toList();
  }
}
