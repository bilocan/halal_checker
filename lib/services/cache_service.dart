import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class CacheService {
  static const String _prefix = 'halal_cache_';
  static const Duration _ttl = Duration(days: 30);

  Future<Product?> getProduct(String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$barcode');
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(map['_cachedAt'] as String? ?? '');
      if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
        await prefs.remove('$_prefix$barcode');
        return null;
      }
      return Product.fromJson(map);
    } catch (_) {
      await prefs.remove('$_prefix$barcode');
      return null;
    }
  }

  Future<void> saveProduct(String barcode, Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final map = product.toJson();
    map['_cachedAt'] = DateTime.now().toIso8601String();
    await prefs.setString('$_prefix$barcode', jsonEncode(map));
  }

  Future<void> removeProduct(String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$barcode');
  }
}
