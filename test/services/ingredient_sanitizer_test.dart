import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/ingredient_sanitizer.dart';
import 'package:halal_checker/services/product_service.dart';

// Raw OCR text simulating what ML Kit produces from the Soletti Salzgebäckmischung
// label (photo provided by user). Includes:
//   - Parenthesised country codes: (A)(D)(CH), (GB)
//   - Section description headers ending with ":"
//   - "Zutaten:" / "Ingredients:" prefixes
//   - Sub-ingredient lists inside parentheses (must NOT be split)
//   - Visual line-wraps mid-ingredient (e.g. WHEY\nPOWDER)
//   - Hyphenated line-break artifact (natür-\nliches)
const _soletiOcr = '''
(A)(D)(CH) Salzgebäckmischung:
Zutaten: WEIZENMEHL, Rapsöl, Zucker, Salz, Backtriebmittel (Ammoniumhydrogencarbonat, Natriumhydrogencarbonat,
Dinatriumdiphosphat), Mohn, SESAM, Glukosesirup,
WEIZENMALZ, KÄSEPULVER, BUTTERMILCHPULVER, Hefe,
ROGGENMEHL, MOLKENPULVER, Fructose, natür-
liches Aroma, Maltodextrin, Säureregulator (Natriumhydroxid),
Säuerungsmittel (Essigsäure), Pfeffer gemahlen.
(GB) Assortment of pretzel snacks:
Ingredients: WHEAT FLOUR, rapeseed oil, sugar, salt, raising
agents (ammonium hydrogen carbonate, sodium hydrogen
carbonate, disodium diphosphate), poppy seeds, SESAME,
glucose syrup, WHEAT MALT, CHEESE POWDER,
BUTTERMILK POWDER, yeast, RYE FLOUR, WHEY
POWDER, fructose, natural flavouring, maltodextrin, acidity
regulator (sodium hydroxide), acid (acetic acid), ground
pepper.
''';

void main() {
  group('IngredientSanitizer.sanitize — structural', () {
    late List<String> result;

    setUpAll(() {
      result = IngredientSanitizer.sanitize(_soletiOcr);
    });

    test('returns a non-empty list', () {
      expect(result, isNotEmpty);
    });

    test('strips "Zutaten:" and "Ingredients:" labels', () {
      expect(result.any((e) => e.toLowerCase().startsWith('zutaten')), isFalse);
      expect(
        result.any((e) => e.toLowerCase().startsWith('ingredients')),
        isFalse,
      );
    });

    test('strips section description headers', () {
      // "Assortment of pretzel snacks" and "Salzgebäckmischung" must not appear
      expect(
        result.any((e) => e.toLowerCase().contains('assortment')),
        isFalse,
      );
      expect(
        result.any((e) => e.toLowerCase().contains('salzgebäckmischung')),
        isFalse,
      );
    });

    test('strips parenthesised country codes', () {
      // Bare language code tokens like "GB", "A", "D", "CH" must not appear
      expect(result, isNot(contains('GB')));
      expect(result, isNot(contains('A')));
      expect(result, isNot(contains('D')));
    });

    test(
      'keeps sub-ingredient list as one token — not split inside parens',
      () {
        // "Backtriebmittel (Ammoniumhydrogencarbonat, Natriumhydrogencarbonat,
        //  Dinatriumdiphosphat)" must be ONE entry, not three fragments
        final entry = result.firstWhere(
          (e) => e.toLowerCase().contains('backtriebmittel'),
          orElse: () => '',
        );
        expect(entry, isNotEmpty, reason: 'Backtriebmittel entry must exist');
        expect(
          entry.toLowerCase().contains('ammoniumhydrogencarbonat'),
          isTrue,
          reason: 'Sub-ingredients must remain inside the parent token',
        );
      },
    );

    test(
      'repairs hyphenated line-break — natür-\\nliches → natürliches Aroma',
      () {
        final entry = result.firstWhere(
          (e) => e.toLowerCase().contains('natürliches'),
          orElse: () => '',
        );
        expect(entry, isNotEmpty, reason: 'natürliches Aroma must appear');
        // Must NOT appear as a broken fragment "natür" or "liches" on its own
        expect(result, isNot(contains('natür')));
      },
    );

    test('joins line-wrapped ingredient — WHEY / POWDER on separate lines', () {
      // OCR line-wrap produces "WHEY\nPOWDER"; must merge to "WHEY POWDER"
      final entry = result.firstWhere(
        (e) => e.toLowerCase().contains('whey'),
        orElse: () => '',
      );
      expect(entry, isNotEmpty, reason: 'WHEY entry must exist');
      expect(
        entry.toLowerCase().contains('powder'),
        isTrue,
        reason: 'WHEY and POWDER must be in the same token after line-join',
      );
    });

    test('raising agents kept as one token with sub-ingredients', () {
      final entry = result.firstWhere(
        (e) => e.toLowerCase().contains('raising'),
        orElse: () => '',
      );
      expect(entry, isNotEmpty);
      expect(
        entry.toLowerCase().contains('ammonium hydrogen carbonate'),
        isTrue,
      );
    });

    test('Mohn (poppy seeds) present', () {
      expect(result.any((e) => e.toLowerCase().contains('mohn')), isTrue);
    });

    test('WEIZENMALZ (wheat malt) present', () {
      expect(result.any((e) => e.toLowerCase().contains('weizenmalz')), isTrue);
    });

    test('Säureregulator kept as one token with sub-ingredient', () {
      final entry = result.firstWhere(
        (e) => e.toLowerCase().contains('säureregulator'),
        orElse: () => '',
      );
      expect(entry, isNotEmpty);
      expect(entry.toLowerCase().contains('natriumhydroxid'), isTrue);
    });

    test('acidity regulator kept as one token with sub-ingredient', () {
      final entry = result.firstWhere(
        (e) => e.toLowerCase().contains('acidity regulator'),
        orElse: () => '',
      );
      expect(entry, isNotEmpty);
      expect(entry.toLowerCase().contains('sodium hydroxide'), isTrue);
    });

    test('Säuerungsmittel kept as one token with sub-ingredient', () {
      final entry = result.firstWhere(
        (e) => e.toLowerCase().contains('säuerungsmittel'),
        orElse: () => '',
      );
      expect(entry, isNotEmpty);
      expect(entry.toLowerCase().contains('essigsäure'), isTrue);
    });

    test('acid (acetic acid) present', () {
      expect(
        result.any((e) => e.toLowerCase().contains('acetic acid')),
        isTrue,
      );
    });
  });

  group('IngredientSanitizer + analyzeWithKeywords — Soletti pipeline', () {
    late List<String> ingredients;

    setUpAll(() {
      ingredients = IngredientSanitizer.sanitize(_soletiOcr);
    });

    test('full pipeline: isHalal is true (no haram ingredients)', () {
      final result = ProductService.analyzeWithKeywords(ingredients);
      expect(result.isHalal, isTrue);
      expect(result.haram, isEmpty);
    });

    test('flags whey / Molkenpulver as suspicious', () {
      final result = ProductService.analyzeWithKeywords(ingredients);
      final suspiciousLower = result.suspicious.map((s) => s.toLowerCase());
      expect(
        suspiciousLower.any((s) => s.contains('whey') || s.contains('molke')),
        isTrue,
        reason: 'WHEY POWDER and/or MOLKENPULVER must be flagged suspicious',
      );
    });

    test('flags natural flavouring / natürliches Aroma as suspicious', () {
      final result = ProductService.analyzeWithKeywords(ingredients);
      final suspiciousLower = result.suspicious.map((s) => s.toLowerCase());
      expect(
        suspiciousLower.any(
          (s) => s.contains('flavour') || s.contains('aroma'),
        ),
        isTrue,
        reason: 'natural flavouring and/or natürliches Aroma must be flagged',
      );
    });
  });

  group('IngredientSanitizer.sanitize — edge cases', () {
    test('empty string returns empty list', () {
      expect(IngredientSanitizer.sanitize(''), isEmpty);
    });

    test('plain comma-separated list with no headers', () {
      final result = IngredientSanitizer.sanitize(
        'wheat flour, sugar, salt, water',
      );
      expect(result, equals(['wheat flour', 'sugar', 'salt', 'water']));
    });

    test('semicolon separator works', () {
      final result = IngredientSanitizer.sanitize('flour; sugar; salt');
      expect(result, containsAll(['flour', 'sugar', 'salt']));
    });

    test('does not split commas inside nested parens', () {
      final result = IngredientSanitizer.sanitize(
        'emulsifier (mono- and diglycerides (E471, E472)), salt',
      );
      expect(result.length, equals(2));
      expect(result[0].toLowerCase(), contains('emulsifier'));
      expect(result[1], equals('salt'));
    });

    test('strips "Ingredients:" prefix', () {
      final result = IngredientSanitizer.sanitize(
        'Ingredients: sugar, water, salt',
      );
      expect(result, containsAll(['sugar', 'water', 'salt']));
      expect(
        result.any((e) => e.toLowerCase().contains('ingredients')),
        isFalse,
      );
    });

    test('strips section header line ending with colon', () {
      final result = IngredientSanitizer.sanitize(
        'Assortment of crackers:\nwheat flour, salt, oil',
      );
      expect(
        result.any((e) => e.toLowerCase().contains('assortment')),
        isFalse,
      );
      expect(result, containsAll(['wheat flour', 'salt', 'oil']));
    });

    test('product containing pork is flagged haram', () {
      final ingredients = IngredientSanitizer.sanitize(
        'Ingredients: wheat flour, lard, salt',
      );
      final result = ProductService.analyzeWithKeywords(ingredients);
      expect(result.isHalal, isFalse);
      expect(result.haram.any((e) => e.toLowerCase().contains('lard')), isTrue);
    });
  });
}
