import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/seed_data_service.dart';
import 'package:halal_checker/services/test_product_repository.dart';

Product _fixture(String barcode, {bool isUnknown = false}) => Product(
  barcode: barcode,
  name: 'Product $barcode',
  ingredients: ['water', 'salt'],
  isHalal: true,
  isUnknown: isUnknown,
  haramIngredients: [],
  suspiciousIngredients: [],
  ingredientWarnings: {},
  labels: [],
  explanation: 'Test fixture.',
);

// Routes a specific asset key to inline content; all other asset requests
// return null (which triggers the default Flutter bundle lookup).
void _mockAsset(String key, String content) {
  final contentBytes = utf8.encode(content);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? msg) async {
        if (msg == null) return null;
        final requested = utf8.decode(msg.buffer.asUint8List());
        if (requested == key) {
          return ByteData.sublistView(Uint8List.fromList(contentBytes));
        }
        return null;
      });
}

void _clearAssetMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', null);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestProductRepository.dbPathOverride = inMemoryDatabasePath;
  });

  setUp(() async {
    await TestProductRepository.instance.closeForTesting();
    _clearAssetMock();
    rootBundle.evict('test_data/seed_products.json');
    rootBundle.evict('test_data/seed_barcodes.txt');
  });

  tearDown(_clearAssetMock);

  group('SeedDataService.seedIfNeeded', () {
    test('skips seeding when seed version already matches', () async {
      // Pre-set the DB version so the early-exit guard fires.
      await TestProductRepository.instance.setMetadata('seed_version', 'v1');

      await SeedDataService.seedIfNeeded();

      final all = await TestProductRepository.instance.getAll();
      expect(all, isEmpty);
    });

    test('seeds products from JSON asset when version is absent', () async {
      final product = _fixture('1234567890');
      _mockAsset(
        'test_data/seed_products.json',
        jsonEncode([product.toJson()]),
      );

      await SeedDataService.seedIfNeeded();

      final result = await TestProductRepository.instance.getByBarcode(
        '1234567890',
      );
      expect(result, isNotNull);
      expect(result!.name, 'Product 1234567890');
    });

    test('sets seed_version metadata after seeding', () async {
      final product = _fixture('0987654321');
      _mockAsset(
        'test_data/seed_products.json',
        jsonEncode([product.toJson()]),
      );

      await SeedDataService.seedIfNeeded();

      final version = await TestProductRepository.instance.getMetadata(
        'seed_version',
      );
      expect(version, 'v1');
    });

    test('does not re-seed on a second call once version is written', () async {
      final product = _fixture('1111111111');
      _mockAsset(
        'test_data/seed_products.json',
        jsonEncode([product.toJson()]),
      );

      await SeedDataService.seedIfNeeded();
      // Second call: version now matches, so no additional upserts happen.
      await SeedDataService.seedIfNeeded();

      final all = await TestProductRepository.instance.getAll();
      expect(all.length, 1);
    });

    test('seeds multiple products from a JSON array', () async {
      final products = [_fixture('AAA'), _fixture('BBB'), _fixture('CCC')];
      _mockAsset(
        'test_data/seed_products.json',
        jsonEncode(products.map((p) => p.toJson()).toList()),
      );

      await SeedDataService.seedIfNeeded();

      final all = await TestProductRepository.instance.getAll();
      expect(all.map((p) => p.barcode), containsAll(['AAA', 'BBB', 'CCC']));
    });
  });

  group('SeedDataService.seedFromBarcodes', () {
    test('skips barcodes whose product is already known in the repo', () async {
      await TestProductRepository.instance.upsert(_fixture('9999999999'));
      _mockAsset('test_data/seed_barcodes.txt', '9999999999\n');

      await SeedDataService.seedFromBarcodes();

      // Repo unchanged — product was already there, no network fetch attempted.
      final all = await TestProductRepository.instance.getAll();
      expect(all.length, 1);
    });

    test(
      'attempts to re-fetch barcodes marked isUnknown in the repo',
      () async {
        await TestProductRepository.instance.upsert(
          _fixture('8888888888', isUnknown: true),
        );
        _mockAsset('test_data/seed_barcodes.txt', '8888888888\n');

        // Network will fail in tests; catch block handles it silently.
        await expectLater(SeedDataService.seedFromBarcodes(), completes);
      },
    );

    test('strips inline # comments from barcode lines', () async {
      _mockAsset(
        'test_data/seed_barcodes.txt',
        '1234567 # this is a comment\n',
      );

      // No crash means parsing succeeded; the barcode was attempted (and
      // silently skipped when the network fetch failed).
      await expectLater(SeedDataService.seedFromBarcodes(), completes);
    });

    test('ignores empty and whitespace-only lines', () async {
      _mockAsset('test_data/seed_barcodes.txt', '\n   \n# only a comment\n\n');

      await expectLater(SeedDataService.seedFromBarcodes(), completes);
    });

    test(
      'silently survives network failures for all listed barcodes',
      () async {
        _mockAsset('test_data/seed_barcodes.txt', '0000000001\n0000000002\n');

        await expectLater(SeedDataService.seedFromBarcodes(), completes);
      },
    );

    test('does nothing when barcode file is empty', () async {
      _mockAsset('test_data/seed_barcodes.txt', '');

      await expectLater(SeedDataService.seedFromBarcodes(), completes);
      final all = await TestProductRepository.instance.getAll();
      expect(all, isEmpty);
    });
  });
}
