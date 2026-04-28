import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/product_service.dart';

void main() {
  // ── isFattyAlcohol ──────────────────────────────────────────────────────────

  group('isFattyAlcohol', () {
    test('cetyl alcohol is fatty', () {
      expect(ProductService.isFattyAlcohol('cetyl alcohol'), isTrue);
    });
    test('stearyl alcohol is fatty', () {
      expect(ProductService.isFattyAlcohol('stearyl alcohol'), isTrue);
    });
    test('behenyl alcohol is fatty', () {
      expect(ProductService.isFattyAlcohol('behenyl alcohol'), isTrue);
    });
    test('lauryl alcohol is fatty', () {
      expect(ProductService.isFattyAlcohol('lauryl alcohol'), isTrue);
    });
    test('plain alcohol is not fatty', () {
      expect(ProductService.isFattyAlcohol('alcohol'), isFalse);
    });
    test('ethanol is not fatty', () {
      expect(ProductService.isFattyAlcohol('ethanol'), isFalse);
    });
    test('ethyl alcohol is not fatty', () {
      expect(ProductService.isFattyAlcohol('ethyl alcohol'), isFalse);
    });
  });

  // ── matchesKeyword ──────────────────────────────────────────────────────────

  group('matchesKeyword — pork', () {
    test('matches pork', () {
      expect(ProductService.matchesKeyword('pork', 'pork'), isTrue);
    });
    test('matches pork belly', () {
      expect(ProductService.matchesKeyword('pork belly', 'pork'), isTrue);
    });
    test('matches German schwein', () {
      expect(ProductService.matchesKeyword('schwein', 'pork'), isTrue);
    });
    test('matches German schweinefleisch', () {
      expect(ProductService.matchesKeyword('schweinefleisch', 'pork'), isTrue);
    });
    test('matches Turkish domuz', () {
      expect(ProductService.matchesKeyword('domuz', 'pork'), isTrue);
    });
    test('matches French porc', () {
      expect(ProductService.matchesKeyword('porc', 'pork'), isTrue);
    });
    test('does not match porcelain', () {
      expect(ProductService.matchesKeyword('porcelain', 'pork'), isFalse);
    });
  });

  group('matchesKeyword — gelatin', () {
    test('matches gelatin', () {
      expect(ProductService.matchesKeyword('gelatin', 'gelatin'), isTrue);
    });
    test('matches gelatine', () {
      expect(ProductService.matchesKeyword('gelatine', 'gelatin'), isTrue);
    });
    test('matches Turkish jelatin', () {
      expect(ProductService.matchesKeyword('jelatin', 'gelatin'), isTrue);
    });
    test('matches Spanish gelatina', () {
      expect(ProductService.matchesKeyword('gelatina', 'gelatin'), isTrue);
    });
  });

  group('matchesKeyword — alcohol', () {
    test('matches alcohol', () {
      expect(ProductService.matchesKeyword('alcohol', 'alcohol'), isTrue);
    });
    test('matches ethanol', () {
      expect(ProductService.matchesKeyword('ethanol', 'ethanol'), isTrue);
    });
    test('does not match alcohol-free', () {
      expect(ProductService.matchesKeyword('alcohol-free', 'alcohol'), isFalse);
    });
    test('does not match alcohol free (space)', () {
      expect(ProductService.matchesKeyword('alcohol free', 'alcohol'), isFalse);
    });
    test('does not match cetyl alcohol as haram alcohol', () {
      expect(ProductService.matchesKeyword('cetyl alcohol', 'alcohol'), isFalse);
    });
    test('does not match stearyl alcohol as haram alcohol', () {
      expect(ProductService.matchesKeyword('stearyl alcohol', 'alcohol'), isFalse);
    });
  });

  group('matchesKeyword — E-numbers', () {
    test('matches e120', () {
      expect(ProductService.matchesKeyword('e120', 'e120'), isTrue);
    });
    test('matches e-120 with hyphen', () {
      expect(ProductService.matchesKeyword('e-120', 'e120'), isTrue);
    });
    test('matches e471', () {
      expect(ProductService.matchesKeyword('e471', 'e471'), isTrue);
    });
    test('matches e-471 with hyphen', () {
      expect(ProductService.matchesKeyword('e-471', 'e471'), isTrue);
    });
    test('does not match e1200 as e120', () {
      expect(ProductService.matchesKeyword('e1200', 'e120'), isFalse);
    });
  });

  group('matchesKeyword — suspicious', () {
    test('matches whey', () {
      expect(ProductService.matchesKeyword('whey', 'whey'), isTrue);
    });
    test('matches whey powder', () {
      expect(ProductService.matchesKeyword('whey powder', 'whey'), isTrue);
    });
    test('matches German Molke', () {
      expect(ProductService.matchesKeyword('molke', 'whey'), isTrue);
    });
    test('matches natural flavour', () {
      expect(ProductService.matchesKeyword('natural flavour', 'natural flavour'), isTrue);
    });
    test('matches natural flavor (US spelling)', () {
      expect(ProductService.matchesKeyword('natural flavor', 'natural flavour'), isTrue);
    });
    test('matches enzymes', () {
      expect(ProductService.matchesKeyword('enzymes', 'enzymes'), isTrue);
    });
    test('matches glycerol', () {
      expect(ProductService.matchesKeyword('glycerol', 'glycerol'), isTrue);
    });
    test('matches glycerin', () {
      expect(ProductService.matchesKeyword('glycerin', 'glycerol'), isTrue);
    });
  });

  // ── analyzeWithKeywords ─────────────────────────────────────────────────────

  group('analyzeWithKeywords — halal products', () {
    test('pure water is halal with no flags', () {
      final r = ProductService.analyzeWithKeywords(['natural mineral water']);
      expect(r.isHalal, isTrue);
      expect(r.haram, isEmpty);
      expect(r.suspicious, isEmpty);
    });

    test('oat drink is halal with no flags', () {
      final r = ProductService.analyzeWithKeywords([
        'oat base (water, oats 10%)',
        'rapeseed oil',
        'calcium carbonate',
        'salt',
      ]);
      expect(r.isHalal, isTrue);
      expect(r.haram, isEmpty);
      expect(r.suspicious, isEmpty);
    });

    test('empty ingredient list is halal', () {
      final r = ProductService.analyzeWithKeywords([]);
      expect(r.isHalal, isTrue);
      expect(r.haram, isEmpty);
      expect(r.suspicious, isEmpty);
      expect(r.explanation, contains('No ingredient data'));
    });
  });

  group('analyzeWithKeywords — haram products', () {
    test('spam ingredients flagged for pork', () {
      final r = ProductService.analyzeWithKeywords([
        'pork',
        'salt',
        'water',
        'potato starch',
        'sugar',
        'sodium nitrite',
      ]);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('pork'));
      expect(r.warnings, containsPair('pork', contains('pork')));
    });

    test('haribo ingredients flagged for gelatin', () {
      final r = ProductService.analyzeWithKeywords([
        'glucose syrup',
        'sugar',
        'gelatin',
        'dextrose',
        'citric acid',
        'natural and artificial flavors',
        'carnauba wax',
      ]);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('gelatin'));
    });

    test('product with lard is haram', () {
      final r = ProductService.analyzeWithKeywords(['wheat flour', 'lard', 'salt']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('lard'));
    });

    test('product with bacon is haram', () {
      final r = ProductService.analyzeWithKeywords(['pasta', 'bacon', 'cream']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('bacon'));
    });

    test('product with wine is haram', () {
      final r = ProductService.analyzeWithKeywords(['beef', 'wine', 'herbs']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('wine'));
    });

    test('product with e120 (carmine) is haram', () {
      final r = ProductService.analyzeWithKeywords(['sugar', 'water', 'e120', 'citric acid']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('e120'));
    });

    test('German pork ingredient is flagged', () {
      final r = ProductService.analyzeWithKeywords(['schweinefleisch', 'salz', 'wasser']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('schweinefleisch'));
    });

    test('Turkish gelatin is flagged', () {
      final r = ProductService.analyzeWithKeywords(['şeker', 'jelatin', 'sitrik asit']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('jelatin'));
    });
  });

  group('analyzeWithKeywords — suspicious products', () {
    test('nutella-like ingredients flagged whey as suspicious', () {
      final r = ProductService.analyzeWithKeywords([
        'sugar',
        'palm oil',
        'hazelnuts',
        'skim milk powder',
        'cocoa powder',
        'whey powder',
        'vanillin',
      ]);
      expect(r.isHalal, isTrue);
      expect(r.haram, isEmpty);
      expect(r.suspicious, contains('whey powder'));
    });

    test('product with e471 is suspicious', () {
      final r = ProductService.analyzeWithKeywords(['flour', 'e471', 'salt']);
      expect(r.isHalal, isTrue);
      expect(r.suspicious, contains('e471'));
    });

    test('product with natural flavour is suspicious', () {
      final r = ProductService.analyzeWithKeywords(['sugar', 'natural flavour', 'water']);
      expect(r.isHalal, isTrue);
      expect(r.suspicious, contains('natural flavour'));
    });

    test('product with enzymes is suspicious', () {
      final r = ProductService.analyzeWithKeywords(['wheat flour', 'water', 'yeast', 'enzymes']);
      expect(r.isHalal, isTrue);
      expect(r.suspicious, contains('enzymes'));
    });
  });

  group('analyzeWithKeywords — precedence rules', () {
    test('haram takes precedence: pork ingredient not also added to suspicious', () {
      final r = ProductService.analyzeWithKeywords(['pork', 'salt']);
      expect(r.haram, contains('pork'));
      expect(r.suspicious, isNot(contains('pork')));
    });

    test('mixed: both haram and suspicious ingredients coexist', () {
      final r = ProductService.analyzeWithKeywords(['gelatin', 'whey', 'sugar']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('gelatin'));
      expect(r.suspicious, contains('whey'));
    });

    test('cetyl alcohol is not flagged as haram', () {
      final r = ProductService.analyzeWithKeywords(['water', 'cetyl alcohol', 'glycerin']);
      expect(r.haram, isEmpty);
      // glycerin/glycerol is suspicious
      expect(r.suspicious, contains('glycerin'));
    });

    test('alcohol-free label is not flagged', () {
      final r = ProductService.analyzeWithKeywords(['water', 'citrus extract (alcohol-free)', 'fruit juice']);
      expect(r.haram, isEmpty);
    });
  });

  group('analyzeWithKeywords — explanation text', () {
    test('haram explanation mentions the ingredient', () {
      final r = ProductService.analyzeWithKeywords(['pork', 'salt']);
      expect(r.explanation, contains('pork'));
    });

    test('suspicious explanation mentions the ingredient', () {
      final r = ProductService.analyzeWithKeywords(['whey', 'sugar']);
      expect(r.explanation, contains('whey'));
    });

    test('clean product explanation says no haram detected', () {
      final r = ProductService.analyzeWithKeywords(['water', 'salt']);
      expect(r.explanation, contains('No haram'));
    });
  });
}
