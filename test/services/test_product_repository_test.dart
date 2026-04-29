import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/services/test_product_repository.dart';

Product _makeProduct(String barcode, {bool isHalal = true}) => Product(
  barcode: barcode,
  name: 'Test Product $barcode',
  ingredients: ['water', 'salt'],
  isHalal: isHalal,
  haramIngredients: isHalal ? [] : ['pork'],
  suspiciousIngredients: [],
  ingredientWarnings: {},
  labels: [],
  explanation: 'Test fixture.',
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestProductRepository.dbPathOverride = inMemoryDatabasePath;
  });

  // Reset the singleton's DB before each test so every test starts empty.
  setUp(() async {
    await TestProductRepository.instance.closeForTesting();
  });

  group('TestProductRepository', () {
    test('returns null for unknown barcode', () async {
      final repo = TestProductRepository.instance;
      final result = await repo.getByBarcode('nonexistent');
      expect(result, isNull);
    });

    test('upsert and retrieve round-trips all fields', () async {
      final repo = TestProductRepository.instance;
      final product = Product(
        barcode: '3068320114094',
        name: 'Evian Natural Mineral Water 1.5L',
        ingredients: ['natural mineral water'],
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        labels: [],
        explanation: 'Pure water. Clearly halal.',
        analyzedByAI: false,
      );

      await repo.upsert(product);
      final retrieved = await repo.getByBarcode('3068320114094');

      expect(retrieved, isNotNull);
      expect(retrieved!.barcode, '3068320114094');
      expect(retrieved.name, 'Evian Natural Mineral Water 1.5L');
      expect(retrieved.ingredients, ['natural mineral water']);
      expect(retrieved.isHalal, isTrue);
      expect(retrieved.explanation, 'Pure water. Clearly halal.');
    });

    test('upsert overwrites existing product', () async {
      final repo = TestProductRepository.instance;
      await repo.upsert(_makeProduct('ABC', isHalal: true));
      await repo.upsert(_makeProduct('ABC', isHalal: false));

      final result = await repo.getByBarcode('ABC');
      expect(result!.isHalal, isFalse);
    });

    test('getAll returns all upserted products', () async {
      final repo = TestProductRepository.instance;
      await repo.upsert(_makeProduct('001'));
      await repo.upsert(_makeProduct('002'));
      await repo.upsert(_makeProduct('003'));

      final all = await repo.getAll();
      final barcodes = all.map((p) => p.barcode).toSet();
      expect(barcodes, containsAll(['001', '002', '003']));
    });

    test('getAll returns empty list when no products seeded', () async {
      final all = await TestProductRepository.instance.getAll();
      expect(all, isEmpty);
    });

    test('metadata returns null for unknown key', () async {
      final value = await TestProductRepository.instance.getMetadata(
        'no_such_key',
      );
      expect(value, isNull);
    });

    test('setMetadata and getMetadata round-trip', () async {
      final repo = TestProductRepository.instance;
      await repo.setMetadata('seed_version', 'v1');
      final value = await repo.getMetadata('seed_version');
      expect(value, 'v1');
    });

    test('setMetadata overwrites existing value', () async {
      final repo = TestProductRepository.instance;
      await repo.setMetadata('key', 'first');
      await repo.setMetadata('key', 'second');
      expect(await repo.getMetadata('key'), 'second');
    });

    test('haram product fields survive round-trip', () async {
      final repo = TestProductRepository.instance;
      final product = Product(
        barcode: '0037600000871',
        name: 'Spam Classic',
        ingredients: ['pork', 'salt', 'water'],
        isHalal: false,
        haramIngredients: ['pork'],
        suspiciousIngredients: [],
        ingredientWarnings: {'pork': 'Pork is haram.'},
        labels: [],
        explanation: 'Contains pork.',
      );

      await repo.upsert(product);
      final r = await repo.getByBarcode('0037600000871');

      expect(r!.isHalal, isFalse);
      expect(r.haramIngredients, contains('pork'));
      expect(r.ingredientWarnings['pork'], 'Pork is haram.');
    });

    test('suspicious product fields survive round-trip', () async {
      final repo = TestProductRepository.instance;
      final product = Product(
        barcode: '3017620429484',
        name: 'Nutella',
        ingredients: ['sugar', 'palm oil', 'whey powder'],
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: ['whey powder'],
        ingredientWarnings: {
          'whey powder': 'Whey requires source verification.',
        },
        labels: [],
        explanation: 'No haram ingredients; whey requires verification.',
      );

      await repo.upsert(product);
      final r = await repo.getByBarcode('3017620429484');

      expect(r!.isHalal, isTrue);
      expect(r.suspiciousIngredients, contains('whey powder'));
      expect(r.ingredientWarnings['whey powder'], contains('verification'));
    });
  });
}
