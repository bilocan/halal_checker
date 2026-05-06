import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/halal_brand.dart';
import 'package:halal_checker/models/halal_store.dart';

void main() {
  // ── HalalBrand ─────────────────────────────────────────────────────────────

  group('HalalBrand.fromJson', () {
    test('parses all fields from full JSON', () {
      final brand = HalalBrand.fromJson({
        'id': 'abc-123',
        'name': 'Test Brand',
        'logo_url': 'https://example.com/logo.png',
        'country': 'Germany',
        'category': 'food',
        'certification_body': 'HFCE',
        'website': 'https://example.com',
      });

      expect(brand.id, equals('abc-123'));
      expect(brand.name, equals('Test Brand'));
      expect(brand.logoUrl, equals('https://example.com/logo.png'));
      expect(brand.country, equals('Germany'));
      expect(brand.category, equals('food'));
      expect(brand.certificationBody, equals('HFCE'));
      expect(brand.website, equals('https://example.com'));
    });

    test(
      'accepts null optional fields (logo_url, certification_body, website)',
      () {
        final brand = HalalBrand.fromJson({
          'id': 'abc-123',
          'name': 'Minimal Brand',
          'logo_url': null,
          'country': 'Turkey',
          'category': 'pharma',
          'certification_body': null,
          'website': null,
        });

        expect(brand.logoUrl, isNull);
        expect(brand.certificationBody, isNull);
        expect(brand.website, isNull);
      },
    );

    test('defaults category to "other" when key is absent', () {
      final brand = HalalBrand.fromJson({
        'id': 'abc-123',
        'name': 'Brand',
        'country': 'UK',
      });

      expect(brand.category, equals('other'));
    });

    test('preserves category value for each valid option', () {
      for (final cat in ['food', 'cosmetics', 'pharma', 'other']) {
        final brand = HalalBrand.fromJson({
          'id': 'x',
          'name': 'B',
          'country': 'C',
          'category': cat,
        });
        expect(brand.category, equals(cat));
      }
    });
  });

  // ── HalalStore ─────────────────────────────────────────────────────────────

  group('HalalStore.fromJson', () {
    test('parses all fields from full JSON', () {
      final store = HalalStore.fromJson({
        'id': 'xyz-456',
        'name': 'Test Restaurant',
        'logo_url': 'https://example.com/logo.png',
        'address': '123 Main St',
        'city': 'Berlin',
        'country': 'Germany',
        'latitude': 52.52,
        'longitude': 13.405,
        'category': 'restaurant',
        'certification_body': 'HFCE',
        'phone': '+49 30 123456',
        'website': 'https://example.com',
      });

      expect(store.id, equals('xyz-456'));
      expect(store.name, equals('Test Restaurant'));
      expect(store.logoUrl, equals('https://example.com/logo.png'));
      expect(store.address, equals('123 Main St'));
      expect(store.city, equals('Berlin'));
      expect(store.country, equals('Germany'));
      expect(store.latitude, equals(52.52));
      expect(store.longitude, equals(13.405));
      expect(store.category, equals('restaurant'));
      expect(store.certificationBody, equals('HFCE'));
      expect(store.phone, equals('+49 30 123456'));
      expect(store.website, equals('https://example.com'));
    });

    test(
      'accepts null optional fields (logo_url, certification_body, phone, website)',
      () {
        final store = HalalStore.fromJson({
          'id': 'xyz-456',
          'name': 'Minimal Store',
          'logo_url': null,
          'address': '1 Street',
          'city': 'Paris',
          'country': 'France',
          'latitude': 48.85,
          'longitude': 2.35,
          'category': 'grocery',
          'certification_body': null,
          'phone': null,
          'website': null,
        });

        expect(store.logoUrl, isNull);
        expect(store.certificationBody, isNull);
        expect(store.phone, isNull);
        expect(store.website, isNull);
      },
    );

    test('converts integer lat/lng to double', () {
      final store = HalalStore.fromJson({
        'id': 'x',
        'name': 'Store',
        'address': '1 St',
        'city': 'City',
        'country': 'Country',
        'latitude': 52,
        'longitude': 13,
        'category': 'butcher',
      });

      expect(store.latitude, isA<double>());
      expect(store.longitude, isA<double>());
      expect(store.latitude, equals(52.0));
      expect(store.longitude, equals(13.0));
    });

    test('defaults category to "other" when key is absent', () {
      final store = HalalStore.fromJson({
        'id': 'x',
        'name': 'Store',
        'address': '1 St',
        'city': 'City',
        'country': 'Country',
        'latitude': 0.0,
        'longitude': 0.0,
      });

      expect(store.category, equals('other'));
    });

    test('preserves category value for each valid option', () {
      for (final cat in [
        'restaurant',
        'grocery',
        'butcher',
        'bakery',
        'other',
      ]) {
        final store = HalalStore.fromJson({
          'id': 'x',
          'name': 'S',
          'address': 'A',
          'city': 'C',
          'country': 'D',
          'latitude': 0.0,
          'longitude': 0.0,
          'category': cat,
        });
        expect(store.category, equals(cat));
      }
    });

    test('stores negative coordinates correctly', () {
      final store = HalalStore.fromJson({
        'id': 'x',
        'name': 'Store',
        'address': '1 St',
        'city': 'São Paulo',
        'country': 'Brazil',
        'latitude': -23.5505,
        'longitude': -46.6333,
        'category': 'restaurant',
      });

      expect(store.latitude, closeTo(-23.5505, 0.0001));
      expect(store.longitude, closeTo(-46.6333, 0.0001));
    });
  });
}
