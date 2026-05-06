import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:halal_checker/services/directory_service.dart';

const _fakeUrl = 'https://test.supabase.co';
const _fakeKey = 'test_anon_key';

DirectoryService _serviceWithClient(MockClient client) => DirectoryService(
  client: client,
  hasSupabase: true,
  supabaseUrl: _fakeUrl,
  anonKey: _fakeKey,
);

// ── Fixture data ─────────────────────────────────────────────────────────────

final _brandJson = {
  'id': 'brand-1',
  'name': 'Test Brand',
  'logo_url': null,
  'country': 'Germany',
  'category': 'food',
  'certification_body': 'HFCE',
  'website': 'https://testbrand.com',
};

final _storeJson = {
  'id': 'store-1',
  'name': 'Test Restaurant',
  'logo_url': null,
  'address': '123 Main St',
  'city': 'Berlin',
  'country': 'Germany',
  'latitude': 52.52,
  'longitude': 13.405,
  'category': 'restaurant',
  'certification_body': 'HFCE',
  'phone': '+49 30 123456',
  'website': 'https://teststore.com',
};

void main() {
  // ── hasSupabase: false guard ───────────────────────────────────────────────

  group('DirectoryService — hasSupabase: false', () {
    late DirectoryService service;

    setUp(() => service = DirectoryService(hasSupabase: false));

    test('fetchBrands returns empty list', () async {
      expect(await service.fetchBrands(), isEmpty);
    });

    test('fetchStores returns empty list', () async {
      expect(await service.fetchStores(), isEmpty);
    });

    test('insertBrand returns false', () async {
      final result = await service.insertBrand(
        name: 'Brand',
        country: 'DE',
        category: 'food',
      );
      expect(result, isFalse);
    });

    test('insertStore returns false', () async {
      final result = await service.insertStore(
        name: 'Store',
        address: '1 St',
        city: 'Berlin',
        country: 'Germany',
        latitude: 52.52,
        longitude: 13.40,
        category: 'restaurant',
      );
      expect(result, isFalse);
    });
  });

  // ── fetchBrands ────────────────────────────────────────────────────────────

  group('DirectoryService.fetchBrands — HTTP paths', () {
    test('returns parsed brand list on HTTP 200', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode([_brandJson, _brandJson]), 200),
      );

      final brands = await _serviceWithClient(client).fetchBrands();

      expect(brands.length, equals(2));
      expect(brands.first.id, equals('brand-1'));
      expect(brands.first.name, equals('Test Brand'));
      expect(brands.first.country, equals('Germany'));
      expect(brands.first.category, equals('food'));
      expect(brands.first.certificationBody, equals('HFCE'));
      expect(brands.first.website, equals('https://testbrand.com'));
    });

    test('sends correct URL, path, and auth headers', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;

      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        return http.Response(jsonEncode([]), 200);
      });

      await _serviceWithClient(client).fetchBrands();

      expect(capturedUri.host, equals('test.supabase.co'));
      expect(capturedUri.path, equals('/rest/v1/halal_brands'));
      expect(capturedHeaders['apikey'], equals(_fakeKey));
      expect(capturedHeaders['Authorization'], equals('Bearer $_fakeKey'));
    });

    test(
      'requests name, logo, country, category, certification, website fields',
      () async {
        late Uri capturedUri;

        final client = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode([]), 200);
        });

        await _serviceWithClient(client).fetchBrands();

        final select = capturedUri.queryParameters['select'] ?? '';
        expect(select, contains('name'));
        expect(select, contains('country'));
        expect(select, contains('category'));
        expect(select, contains('logo_url'));
        expect(select, contains('certification_body'));
        expect(select, contains('website'));
      },
    );

    test('returns empty list on HTTP 401', () async {
      final client = MockClient(
        (_) async => http.Response('Unauthorized', 401),
      );
      expect(await _serviceWithClient(client).fetchBrands(), isEmpty);
    });

    test('returns empty list on HTTP 500', () async {
      final client = MockClient((_) async => http.Response('Error', 500));
      expect(await _serviceWithClient(client).fetchBrands(), isEmpty);
    });

    test('returns empty list on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Network error'),
      );
      expect(await _serviceWithClient(client).fetchBrands(), isEmpty);
    });
  });

  // ── fetchStores ────────────────────────────────────────────────────────────

  group('DirectoryService.fetchStores — HTTP paths', () {
    test('returns parsed store list on HTTP 200', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode([_storeJson]), 200),
      );

      final stores = await _serviceWithClient(client).fetchStores();

      expect(stores.length, equals(1));
      expect(stores.first.id, equals('store-1'));
      expect(stores.first.name, equals('Test Restaurant'));
      expect(stores.first.address, equals('123 Main St'));
      expect(stores.first.city, equals('Berlin'));
      expect(stores.first.country, equals('Germany'));
      expect(stores.first.latitude, equals(52.52));
      expect(stores.first.longitude, equals(13.405));
      expect(stores.first.category, equals('restaurant'));
      expect(stores.first.phone, equals('+49 30 123456'));
    });

    test('sends correct URL, path, and auth headers', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;

      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        return http.Response(jsonEncode([]), 200);
      });

      await _serviceWithClient(client).fetchStores();

      expect(capturedUri.host, equals('test.supabase.co'));
      expect(capturedUri.path, equals('/rest/v1/halal_stores'));
      expect(capturedHeaders['apikey'], equals(_fakeKey));
      expect(capturedHeaders['Authorization'], equals('Bearer $_fakeKey'));
    });

    test(
      'requests lat, lng, address, city, country, category, phone, website fields',
      () async {
        late Uri capturedUri;

        final client = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode([]), 200);
        });

        await _serviceWithClient(client).fetchStores();

        final select = capturedUri.queryParameters['select'] ?? '';
        expect(select, contains('latitude'));
        expect(select, contains('longitude'));
        expect(select, contains('address'));
        expect(select, contains('city'));
        expect(select, contains('country'));
        expect(select, contains('phone'));
      },
    );

    test('returns empty list on HTTP 401', () async {
      final client = MockClient(
        (_) async => http.Response('Unauthorized', 401),
      );
      expect(await _serviceWithClient(client).fetchStores(), isEmpty);
    });

    test('returns empty list on HTTP 500', () async {
      final client = MockClient((_) async => http.Response('Error', 500));
      expect(await _serviceWithClient(client).fetchStores(), isEmpty);
    });

    test('returns empty list on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Network error'),
      );
      expect(await _serviceWithClient(client).fetchStores(), isEmpty);
    });
  });

  // ── insertBrand ────────────────────────────────────────────────────────────

  group('DirectoryService.insertBrand — HTTP paths', () {
    test('returns true on HTTP 201', () async {
      final client = MockClient((_) async => http.Response('', 201));
      final result = await _serviceWithClient(
        client,
      ).insertBrand(name: 'Brand A', country: 'Germany', category: 'food');
      expect(result, isTrue);
    });

    test('returns false on HTTP 400', () async {
      final client = MockClient((_) async => http.Response('Bad Request', 400));
      final result = await _serviceWithClient(
        client,
      ).insertBrand(name: 'Brand A', country: 'Germany', category: 'food');
      expect(result, isFalse);
    });

    test('returns false on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Timeout'),
      );
      final result = await _serviceWithClient(
        client,
      ).insertBrand(name: 'Brand A', country: 'Germany', category: 'food');
      expect(result, isFalse);
    });

    test('sends correct URL and auth headers', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;

      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        return http.Response('', 201);
      });

      await _serviceWithClient(
        client,
      ).insertBrand(name: 'Brand A', country: 'Germany', category: 'food');

      expect(capturedUri.path, equals('/rest/v1/halal_brands'));
      expect(capturedHeaders['apikey'], equals(_fakeKey));
      expect(capturedHeaders['Authorization'], equals('Bearer $_fakeKey'));
      expect(capturedHeaders['Content-Type'], contains('application/json'));
      expect(capturedHeaders['Prefer'], equals('return=minimal'));
    });

    test('sends required fields in request body', () async {
      Map<String, dynamic>? sentBody;

      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });

      await _serviceWithClient(client).insertBrand(
        name: 'Test Brand',
        country: 'Turkey',
        category: 'cosmetics',
      );

      expect(sentBody!['name'], equals('Test Brand'));
      expect(sentBody!['country'], equals('Turkey'));
      expect(sentBody!['category'], equals('cosmetics'));
    });

    test('omits null optional fields from body', () async {
      Map<String, dynamic>? sentBody;

      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });

      await _serviceWithClient(client).insertBrand(
        name: 'Brand A',
        country: 'Germany',
        category: 'food',
        // certificationBody, website, logoUrl all null (omitted)
      );

      expect(sentBody!.containsKey('certification_body'), isFalse);
      expect(sentBody!.containsKey('website'), isFalse);
      expect(sentBody!.containsKey('logo_url'), isFalse);
    });

    test('includes optional fields in body when provided', () async {
      Map<String, dynamic>? sentBody;

      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });

      await _serviceWithClient(client).insertBrand(
        name: 'Brand A',
        country: 'Germany',
        category: 'food',
        certificationBody: 'HFCE',
        website: 'https://example.com',
        logoUrl: 'https://example.com/logo.png',
      );

      expect(sentBody!['certification_body'], equals('HFCE'));
      expect(sentBody!['website'], equals('https://example.com'));
      expect(sentBody!['logo_url'], equals('https://example.com/logo.png'));
    });
  });

  // ── insertStore ────────────────────────────────────────────────────────────

  group('DirectoryService.insertStore — HTTP paths', () {
    test('returns true on HTTP 201', () async {
      final client = MockClient((_) async => http.Response('', 201));
      final result = await _serviceWithClient(client).insertStore(
        name: 'Store A',
        address: '1 Main St',
        city: 'Berlin',
        country: 'Germany',
        latitude: 52.52,
        longitude: 13.40,
        category: 'restaurant',
      );
      expect(result, isTrue);
    });

    test('returns false on HTTP 400', () async {
      final client = MockClient((_) async => http.Response('Bad Request', 400));
      final result = await _serviceWithClient(client).insertStore(
        name: 'Store A',
        address: '1 Main St',
        city: 'Berlin',
        country: 'Germany',
        latitude: 52.52,
        longitude: 13.40,
        category: 'restaurant',
      );
      expect(result, isFalse);
    });

    test('returns false on network exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('Timeout'),
      );
      final result = await _serviceWithClient(client).insertStore(
        name: 'Store A',
        address: '1 Main St',
        city: 'Berlin',
        country: 'Germany',
        latitude: 52.52,
        longitude: 13.40,
        category: 'restaurant',
      );
      expect(result, isFalse);
    });

    test('sends correct URL and auth headers', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;

      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        return http.Response('', 201);
      });

      await _serviceWithClient(client).insertStore(
        name: 'Store A',
        address: '1 Main St',
        city: 'Berlin',
        country: 'Germany',
        latitude: 52.52,
        longitude: 13.40,
        category: 'restaurant',
      );

      expect(capturedUri.path, equals('/rest/v1/halal_stores'));
      expect(capturedHeaders['apikey'], equals(_fakeKey));
      expect(capturedHeaders['Authorization'], equals('Bearer $_fakeKey'));
      expect(capturedHeaders['Content-Type'], contains('application/json'));
      expect(capturedHeaders['Prefer'], equals('return=minimal'));
    });

    test(
      'sends all required fields including lat/lng in request body',
      () async {
        Map<String, dynamic>? sentBody;

        final client = MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 201);
        });

        await _serviceWithClient(client).insertStore(
          name: 'Test Store',
          address: '42 High St',
          city: 'London',
          country: 'UK',
          latitude: 51.5074,
          longitude: -0.1278,
          category: 'grocery',
        );

        expect(sentBody!['name'], equals('Test Store'));
        expect(sentBody!['address'], equals('42 High St'));
        expect(sentBody!['city'], equals('London'));
        expect(sentBody!['country'], equals('UK'));
        expect(sentBody!['latitude'], equals(51.5074));
        expect(sentBody!['longitude'], equals(-0.1278));
        expect(sentBody!['category'], equals('grocery'));
      },
    );

    test('sends negative coordinates correctly', () async {
      Map<String, dynamic>? sentBody;

      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });

      await _serviceWithClient(client).insertStore(
        name: 'Store',
        address: 'Av. Paulista',
        city: 'São Paulo',
        country: 'Brazil',
        latitude: -23.5505,
        longitude: -46.6333,
        category: 'restaurant',
      );

      expect(sentBody!['latitude'], closeTo(-23.5505, 0.0001));
      expect(sentBody!['longitude'], closeTo(-46.6333, 0.0001));
    });

    test('omits null optional fields from body', () async {
      Map<String, dynamic>? sentBody;

      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });

      await _serviceWithClient(client).insertStore(
        name: 'Store A',
        address: '1 Main St',
        city: 'Berlin',
        country: 'Germany',
        latitude: 52.52,
        longitude: 13.40,
        category: 'restaurant',
        // certificationBody, phone, website, logoUrl all null (omitted)
      );

      expect(sentBody!.containsKey('certification_body'), isFalse);
      expect(sentBody!.containsKey('phone'), isFalse);
      expect(sentBody!.containsKey('website'), isFalse);
      expect(sentBody!.containsKey('logo_url'), isFalse);
    });

    test('includes optional fields in body when provided', () async {
      Map<String, dynamic>? sentBody;

      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 201);
      });

      await _serviceWithClient(client).insertStore(
        name: 'Store A',
        address: '1 Main St',
        city: 'Berlin',
        country: 'Germany',
        latitude: 52.52,
        longitude: 13.40,
        category: 'restaurant',
        certificationBody: 'HFCE',
        phone: '+49 30 123456',
        website: 'https://example.com',
        logoUrl: 'https://example.com/logo.png',
      );

      expect(sentBody!['certification_body'], equals('HFCE'));
      expect(sentBody!['phone'], equals('+49 30 123456'));
      expect(sentBody!['website'], equals('https://example.com'));
      expect(sentBody!['logo_url'], equals('https://example.com/logo.png'));
    });
  });
}
