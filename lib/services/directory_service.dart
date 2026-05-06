import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/halal_brand.dart';
import '../models/halal_store.dart';

class DirectoryService {
  final http.Client _client;
  final bool _hasSupabase;
  final String _supabaseUrl;
  final String _anonKey;

  DirectoryService({
    http.Client? client,
    bool? hasSupabase,
    String? supabaseUrl,
    String? anonKey,
  }) : _client = client ?? http.Client(),
       _hasSupabase = hasSupabase ?? AppConfig.hasSupabase,
       _supabaseUrl = supabaseUrl ?? AppConfig.supabaseUrl,
       _anonKey = anonKey ?? AppConfig.supabaseAnonKey;

  Future<List<HalalBrand>> fetchBrands() async {
    if (!_hasSupabase) return [];
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/halal_brands'
              '?select=id,name,logo_url,country,category,certification_body,website'
              '&order=name.asc',
            ),
            headers: {'apikey': _anonKey, 'Authorization': 'Bearer $_anonKey'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      return (json.decode(response.body) as List)
          .map((e) => HalalBrand.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<HalalStore>> fetchStores() async {
    if (!_hasSupabase) return [];
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/halal_stores'
              '?select=id,name,logo_url,address,city,country,latitude,longitude,category,certification_body,phone,website'
              '&order=name.asc',
            ),
            headers: {'apikey': _anonKey, 'Authorization': 'Bearer $_anonKey'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      return (json.decode(response.body) as List)
          .map((e) => HalalStore.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> insertBrand({
    required String name,
    required String country,
    required String category,
    String? certificationBody,
    String? website,
    String? logoUrl,
  }) async {
    if (!_hasSupabase) return false;
    try {
      final response = await _client
          .post(
            Uri.parse('$_supabaseUrl/rest/v1/halal_brands'),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal',
            },
            body: jsonEncode({
              'name': name,
              'country': country,
              'category': category,
              'certification_body': ?certificationBody,
              'website': ?website,
              'logo_url': ?logoUrl,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> insertStore({
    required String name,
    required String address,
    required String city,
    required String country,
    required double latitude,
    required double longitude,
    required String category,
    String? certificationBody,
    String? phone,
    String? website,
    String? logoUrl,
  }) async {
    if (!_hasSupabase) return false;
    try {
      final response = await _client
          .post(
            Uri.parse('$_supabaseUrl/rest/v1/halal_stores'),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal',
            },
            body: jsonEncode({
              'name': name,
              'address': address,
              'city': city,
              'country': country,
              'latitude': latitude,
              'longitude': longitude,
              'category': category,
              'certification_body': ?certificationBody,
              'phone': ?phone,
              'website': ?website,
              'logo_url': ?logoUrl,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
