import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:halal_checker/services/database_service.dart';

/// Initializes in-memory SQLite for widget and integration tests.
void initTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DatabaseService.testDatabasePath = ':memory:';
}

Future<void> clearTestScans() async {
  await DatabaseService.resetForTesting();
  final db = await DatabaseService.instance.database;
  await db.delete('scans');
}
