import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/cache_service.dart';

Product _makeProduct(String barcode) => Product(
  barcode: barcode,
  name: 'Test Product',
  ingredients: ['water', 'salt'],
  isHalal: true,
  haramIngredients: [],
  suspiciousIngredients: [],
  ingredientWarnings: {},
  labels: [],
  explanation: 'No haram detected.',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CacheService.getProduct', () {
    test('returns null when barcode not cached', () async {
      expect(await CacheService().getProduct('0000000000'), isNull);
    });

    test('returns product after saveProduct', () async {
      final cache = CacheService();
      await cache.saveProduct('1234567890', _makeProduct('1234567890'));
      final result = await cache.getProduct('1234567890');
      expect(result, isNotNull);
      expect(result!.barcode, equals('1234567890'));
      expect(result.name, equals('Test Product'));
    });

    test('returns null for expired entry (cachedAt > 30 days ago)', () async {
      final cache = CacheService();
      await cache.saveProduct('expired_bc', _makeProduct('expired_bc'));

      final prefs = await SharedPreferences.getInstance();
      const key = 'halal_cache_expired_bc';
      final raw = prefs.getString(key)!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map['_cachedAt'] = DateTime(2000).toIso8601String();
      await prefs.setString(key, jsonEncode(map));

      expect(await cache.getProduct('expired_bc'), isNull);
    });

    test('removes expired entry from prefs', () async {
      final cache = CacheService();
      await cache.saveProduct('stale_bc', _makeProduct('stale_bc'));

      final prefs = await SharedPreferences.getInstance();
      const key = 'halal_cache_stale_bc';
      final raw = prefs.getString(key)!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map['_cachedAt'] = DateTime(2000).toIso8601String();
      await prefs.setString(key, jsonEncode(map));

      await cache.getProduct('stale_bc');
      expect(prefs.getString(key), isNull);
    });

    test('returns null and removes entry for corrupt JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('halal_cache_corrupt', 'not { valid json <<<');

      final result = await CacheService().getProduct('corrupt');
      expect(result, isNull);
      expect(prefs.getString('halal_cache_corrupt'), isNull);
    });

    test('returns null and removes entry when _cachedAt is missing', () async {
      final prefs = await SharedPreferences.getInstance();
      final product = _makeProduct('no_ts');
      final map = product.toJson();
      // omit _cachedAt key
      await prefs.setString('halal_cache_no_ts', jsonEncode(map));

      expect(await CacheService().getProduct('no_ts'), isNull);
    });
  });

  group('CacheService.saveProduct', () {
    test('different barcodes are cached independently', () async {
      final cache = CacheService();
      await cache.saveProduct('aaa', _makeProduct('aaa'));
      await cache.saveProduct('bbb', _makeProduct('bbb'));

      expect((await cache.getProduct('aaa'))!.barcode, equals('aaa'));
      expect((await cache.getProduct('bbb'))!.barcode, equals('bbb'));
    });

    test('overwriting barcode replaces cached value', () async {
      final cache = CacheService();
      await cache.saveProduct('over_bc', _makeProduct('over_bc'));

      final updated = Product(
        barcode: 'over_bc',
        name: 'Updated Name',
        ingredients: [],
        isHalal: false,
        haramIngredients: ['pork'],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        labels: [],
      );
      await cache.saveProduct('over_bc', updated);
      final result = await cache.getProduct('over_bc');
      expect(result!.name, equals('Updated Name'));
      expect(result.isHalal, isFalse);
    });
  });

  group('CacheService.removeProduct', () {
    test('removes existing cached entry', () async {
      final cache = CacheService();
      await cache.saveProduct('rm_bc', _makeProduct('rm_bc'));
      await cache.removeProduct('rm_bc');
      expect(await cache.getProduct('rm_bc'), isNull);
    });

    test('no-ops gracefully when barcode not in cache', () async {
      await expectLater(CacheService().removeProduct('nonexistent'), completes);
    });
  });
}
