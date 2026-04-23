import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, 'halal_scan.db');
    return openDatabase(
      path,
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
        await db.execute(
          'CREATE INDEX idx_scans_timestamp ON scans(timestamp DESC)',
        );
      },
    );
  }

  Future<void> insertScan({
    required String barcode,
    required String productName,
    required bool isHalal,
  }) async {
    final db = await database;
    // Remove previous entry for the same barcode (move it to top)
    await db.delete('scans', where: 'barcode = ?', whereArgs: [barcode]);
    await db.insert('scans', {
      'barcode': barcode,
      'product_name': productName,
      'is_halal': isHalal ? 1 : 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // Keep only the 50 most recent scans
    await db.execute('''
      DELETE FROM scans WHERE id NOT IN (
        SELECT id FROM scans ORDER BY timestamp DESC LIMIT 50
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getRecentScans({int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'scans',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map((row) => {
      'barcode': row['barcode'] as String,
      'productName': row['product_name'] as String,
      'isHalal': (row['is_halal'] as int) == 1,
      'timestamp': row['timestamp'] as int,
    }).toList();
  }
}
