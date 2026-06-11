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
    test('matches alcohol-free EU labels', () {
      expect(ProductService.matchesKeyword('alcohol-free', 'alcohol'), isTrue);
    });
    test('matches alcohol free (space)', () {
      expect(ProductService.matchesKeyword('alcohol free', 'alcohol'), isTrue);
    });
    test('does not match 0% alcohol declaration', () {
      expect(ProductService.matchesKeyword('0% alcohol', 'alcohol'), isFalse);
      expect(
        ProductService.matchesKeyword('sugar, 0% alcohol', 'alcohol'),
        isFalse,
      );
    });
    test('does not match cetyl alcohol as haram alcohol', () {
      expect(
        ProductService.matchesKeyword('cetyl alcohol', 'alcohol'),
        isFalse,
      );
    });
    test('does not match stearyl alcohol as haram alcohol', () {
      expect(
        ProductService.matchesKeyword('stearyl alcohol', 'alcohol'),
        isFalse,
      );
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
    test('matches e422', () {
      expect(ProductService.matchesKeyword('e422', 'e422'), isTrue);
    });
    test('matches e-422 with hyphen', () {
      expect(ProductService.matchesKeyword('e-422', 'e422'), isTrue);
    });
    test('does not match e1200 as e120', () {
      expect(ProductService.matchesKeyword('e1200', 'e120'), isFalse);
    });
    test('matches e481', () {
      expect(ProductService.matchesKeyword('e481', 'e481'), isTrue);
    });
    test('matches e-481 with hyphen', () {
      expect(ProductService.matchesKeyword('e-481', 'e481'), isTrue);
    });
    test('matches e482', () {
      expect(ProductService.matchesKeyword('e482', 'e482'), isTrue);
    });
    test('matches e570', () {
      expect(ProductService.matchesKeyword('e570', 'e570'), isTrue);
    });
    test('matches e-570 with hyphen', () {
      expect(ProductService.matchesKeyword('e-570', 'e570'), isTrue);
    });
    test('matches e572', () {
      expect(ProductService.matchesKeyword('e572', 'e572'), isTrue);
    });
    test('matches e631', () {
      expect(ProductService.matchesKeyword('e631', 'e631'), isTrue);
    });
    test('matches e-631 with hyphen', () {
      expect(ProductService.matchesKeyword('e-631', 'e631'), isTrue);
    });
    test('matches e635', () {
      expect(ProductService.matchesKeyword('e635', 'e635'), isTrue);
    });
    test('matches e-635 with hyphen', () {
      expect(ProductService.matchesKeyword('e-635', 'e635'), isTrue);
    });
    test('does not match e5700 as e570', () {
      expect(ProductService.matchesKeyword('e5700', 'e570'), isFalse);
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
      expect(
        ProductService.matchesKeyword('natural flavour', 'natural flavour'),
        isTrue,
      );
    });
    test('matches natural flavor (US spelling)', () {
      expect(
        ProductService.matchesKeyword('natural flavor', 'natural flavour'),
        isTrue,
      );
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
      expect(r.suspicious, contains('gelatin'));
    });

    test('product with lard is haram', () {
      final r = ProductService.analyzeWithKeywords([
        'wheat flour',
        'lard',
        'salt',
      ]);
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
      final r = ProductService.analyzeWithKeywords([
        'sugar',
        'water',
        'e120',
        'citric acid',
      ]);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('e120'));
    });

    test('crisp ingredients with e631 and e635 are flagged suspicious', () {
      final r = ProductService.analyzeWithKeywords([
        'potato',
        'sunflower oil',
        'salt',
        'e631',
        'e635',
      ]);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, containsAll(['e631', 'e635']));
    });

    test('product with e481 and e570 are flagged suspicious', () {
      final r = ProductService.analyzeWithKeywords([
        'wheat flour',
        'water',
        'e481',
        'e570',
      ]);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, containsAll(['e481', 'e570']));
    });

    test('hyphenated e-631 and e-635 are flagged suspicious', () {
      final r = ProductService.analyzeWithKeywords([
        'potato',
        'e-631',
        'e-635',
      ]);
      expect(r.suspicious, containsAll(['e-631', 'e-635']));
    });

    test('German pork ingredient is flagged', () {
      final r = ProductService.analyzeWithKeywords([
        'schweinefleisch',
        'salz',
        'wasser',
      ]);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('schweinefleisch'));
    });

    test('Turkish gelatin is flagged', () {
      final r = ProductService.analyzeWithKeywords([
        'şeker',
        'jelatin',
        'sitrik asit',
      ]);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('jelatin'));
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
      expect(r.isHalal, isFalse);
      expect(r.haram, isEmpty);
      expect(r.suspicious, contains('whey powder'));
    });

    test('product with e471 is suspicious', () {
      final r = ProductService.analyzeWithKeywords(['flour', 'e471', 'salt']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e471'));
    });

    test('product with e422 is suspicious', () {
      final r = ProductService.analyzeWithKeywords(['flour', 'e422', 'salt']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e422'));
    });

    test('product with natural flavour is suspicious', () {
      final r = ProductService.analyzeWithKeywords([
        'sugar',
        'natural flavour',
        'water',
      ]);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('natural flavour'));
    });

    test('product with enzymes is suspicious', () {
      final r = ProductService.analyzeWithKeywords([
        'wheat flour',
        'water',
        'yeast',
        'enzymes',
      ]);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('enzymes'));
    });
  });

  group('analyzeWithKeywords — precedence rules', () {
    test(
      'haram takes precedence: pork ingredient not also added to suspicious',
      () {
        final r = ProductService.analyzeWithKeywords(['pork', 'salt']);
        expect(r.haram, contains('pork'));
        expect(r.suspicious, isNot(contains('pork')));
      },
    );

    test('mixed: both haram and suspicious ingredients coexist', () {
      final r = ProductService.analyzeWithKeywords(['pork', 'whey', 'sugar']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('pork'));
      expect(r.suspicious, contains('whey'));
    });

    test('cetyl alcohol is not flagged as haram', () {
      final r = ProductService.analyzeWithKeywords([
        'water',
        'cetyl alcohol',
        'glycerin',
      ]);
      expect(r.haram, isEmpty);
      // glycerin/glycerol is suspicious
      expect(r.suspicious, contains('glycerin'));
    });

    test('alcohol-free EU label is flagged', () {
      final r = ProductService.analyzeWithKeywords([
        'water',
        'citrus extract (alcohol-free)',
        'fruit juice',
      ]);
      expect(r.haram, isNotEmpty);
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

  // ── additive slugs (as produced by _normalizeAdditiveTags) ──────────────────
  //
  // OFF tag "en:e120-carmine" normalises to slug "e120-carmine". The hyphen is a
  // word-boundary separator so the keyword "e120" still matches it.

  group('analyzeWithKeywords — additive slugs', () {
    // ── haram slugs ──────────────────────────────────────────────────────────

    test(
      'e120-carmine slug → haram (keyword e120 matches via word boundary)',
      () {
        final r = ProductService.analyzeWithKeywords(['e120-carmine']);
        expect(r.isHalal, isFalse);
        expect(r.haram, isNotEmpty);
      },
    );

    test('e120 slug (short form) → haram', () {
      final r = ProductService.analyzeWithKeywords(['e120']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('e120'));
    });

    test('e542 slug (bone phosphate) → haram', () {
      final r = ProductService.analyzeWithKeywords(['e542']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('e542'));
    });

    test('e904 slug (shellac) → haram', () {
      final r = ProductService.analyzeWithKeywords(['e904']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('e904'));
    });

    // ── suspicious slugs ─────────────────────────────────────────────────────

    test('e471 slug (mono/diglycerides) → suspicious, not haram', () {
      final r = ProductService.analyzeWithKeywords(['e471']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e471'));
      expect(r.haram, isEmpty);
    });

    test('e441 slug (gelatin E441) → suspicious, not haram', () {
      final r = ProductService.analyzeWithKeywords(['e441']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e441'));
      expect(r.haram, isEmpty);
    });

    test('e322 slug (lecithin) → suspicious', () {
      final r = ProductService.analyzeWithKeywords(['e322']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e322'));
    });

    test('e920 slug (L-cysteine) → suspicious', () {
      final r = ProductService.analyzeWithKeywords(['e920']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e920'));
    });

    test('e422 slug (glycerol) → suspicious', () {
      final r = ProductService.analyzeWithKeywords(['e422']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e422'));
    });

    test('e472 slug (emulsifier) → suspicious', () {
      final r = ProductService.analyzeWithKeywords(['e472']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e472'));
    });

    test('e473 slug (sucrose esters) → suspicious', () {
      final r = ProductService.analyzeWithKeywords(['e473']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e473'));
    });

    test('e927 slug (glycine) → suspicious', () {
      final r = ProductService.analyzeWithKeywords(['e927']);
      expect(r.isHalal, isFalse);
      expect(r.suspicious, contains('e927'));
    });

    // ── halal slugs ──────────────────────────────────────────────────────────

    test('e100 slug (curcumin, halal) → not flagged', () {
      final r = ProductService.analyzeWithKeywords(['e100']);
      expect(r.isHalal, isTrue);
      expect(r.haram, isEmpty);
      expect(r.suspicious, isEmpty);
    });

    test('e330 slug (citric acid, halal) → not flagged', () {
      final r = ProductService.analyzeWithKeywords(['e330']);
      expect(r.isHalal, isTrue);
      expect(r.haram, isEmpty);
      expect(r.suspicious, isEmpty);
    });

    test('e200 slug (sorbic acid, halal) → not flagged', () {
      final r = ProductService.analyzeWithKeywords(['e200']);
      expect(r.isHalal, isTrue);
      expect(r.haram, isEmpty);
      expect(r.suspicious, isEmpty);
    });

    // ── multi-slug cases ─────────────────────────────────────────────────────

    test('all three haram E-numbers together → all appear in haram list', () {
      final r = ProductService.analyzeWithKeywords(['e120', 'e542', 'e904']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('e120'));
      expect(r.haram, contains('e542'));
      expect(r.haram, contains('e904'));
    });

    test('mix of haram and suspicious slugs → both lists populated', () {
      final r = ProductService.analyzeWithKeywords(['e120', 'e471', 'e322']);
      expect(r.isHalal, isFalse);
      expect(r.haram, contains('e120'));
      expect(r.suspicious, containsAll(['e471', 'e322']));
    });

    test('haram slug not also added to suspicious list', () {
      final r = ProductService.analyzeWithKeywords(['e120']);
      expect(r.haram, contains('e120'));
      expect(r.suspicious, isNot(contains('e120')));
    });

    test('e1200 slug does not match e120 keyword (no false prefix match)', () {
      final r = ProductService.analyzeWithKeywords(['e1200']);
      expect(r.haram, isNot(contains('e120')));
    });
  });
}
