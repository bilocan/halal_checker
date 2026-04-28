import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import 'product_service.dart';
import 'test_product_repository.dart';

class SeedDataService {
  // Bump this value whenever test_data/seed_products.json changes to re-seed
  static const _seedVersion = 'v1';
  static const _metaKey = 'seed_version';

  /// Seeds full product fixtures from seed_products.json.
  /// Runs synchronously at startup; no network calls.
  static Future<void> seedIfNeeded() async {
    if (!kDebugMode) return;

    final repo = TestProductRepository.instance;
    final current = await repo.getMetadata(_metaKey);
    if (current == _seedVersion) return;

    final raw = await rootBundle.loadString('test_data/seed_products.json');
    final list = jsonDecode(raw) as List<dynamic>;

    for (final item in list) {
      final product = Product.fromJson(item as Map<String, dynamic>);
      await repo.upsert(product);
    }

    await repo.setMetadata(_metaKey, _seedVersion);
  }

  /// Fetches any barcodes in seed_barcodes.txt not yet in the test DB.
  /// Runs fire-and-forget; does not block app startup.
  static Future<void> seedFromBarcodes() async {
    if (!kDebugMode) return;

    final raw = await rootBundle.loadString('test_data/seed_barcodes.txt');
    final barcodes = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();

    if (barcodes.isEmpty) return;

    final repo = TestProductRepository.instance;
    final service = ProductService();

    for (final barcode in barcodes) {
      final existing = await repo.getByBarcode(barcode);
      if (existing != null) continue;

      try {
        final product = await service.getProduct(barcode);
        if (product != null) await repo.upsert(product);
      } catch (_) {
        // Network unavailable or product not found; skip silently
      }
    }
  }
}
