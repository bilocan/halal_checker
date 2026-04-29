import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class TestProductRepository {
  static final instance = TestProductRepository._();
  TestProductRepository._();

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  // Set to inMemoryDatabasePath in tests to avoid touching the real filesystem.
  static String? dbPathOverride;

  Future<Database> _open() async {
    final path =
        dbPathOverride ?? join(await getDatabasesPath(), 'halal_test.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE test_products (
            barcode TEXT PRIMARY KEY,
            product_json TEXT NOT NULL,
            seeded_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<String?> getMetadata(String key) async {
    final db = await _database;
    final rows = await db.query('metadata', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await _database;
    await db.insert('metadata', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Product?> getByBarcode(String barcode) async {
    final db = await _database;
    final rows = await db.query(
      'test_products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (rows.isEmpty) return null;
    return Product.fromJson(
      jsonDecode(rows.first['product_json'] as String) as Map<String, dynamic>,
    );
  }

  Future<void> upsert(Product product) async {
    final db = await _database;
    await db.insert('test_products', {
      'barcode': product.barcode,
      'product_json': jsonEncode(product.toJson()),
      'seeded_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> closeForTesting() async {
    await _db?.close();
    _db = null;
  }

  Future<List<Product>> getAll() async {
    final db = await _database;
    final rows = await db.query('test_products', orderBy: 'seeded_at DESC');
    return rows
        .map(
          (row) => Product.fromJson(
            jsonDecode(row['product_json'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
