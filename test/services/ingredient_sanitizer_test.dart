import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/ingredient_sanitizer.dart';
import 'package:halal_checker/services/product_service.dart';

// Real OCR output from ML Kit processing an actual Soletti Salzgebäckmischung
// photo (4-language European packaging). Deliberately kept messy to reflect
// what the device actually produces, not an idealised version. Notable
// artefacts that the sanitizer must handle:
//   - Garbled country codes on section headers: "O0D", bare "GB", "D", "O"
//     (all on section-header lines that are stripped wholesale)
//   - Section description headers ending with ":"
//   - "Zutaten:" / "Ingredients:" / "Ingredienti:" prefixes
//   - OCR typos inside ingredient names (Fyuctese, Säurerequlator, etc.)
//     — the sanitizer does NOT fix spelling, only structure
//   - Sub-ingredient lists inside parentheses (must NOT be split)
//   - Visual line-wraps mid-ingredient (e.g. WHEY\nPOWDER)
//   - Hyphenated line-break artefact (idrogenocar-\nbonato)
//   - Trailing footer noise with no commas (brand logo text, origin badge)
//     — must be stripped by the trailing-noise heuristic
const _soletiOcr = '''
O0D Salzgebäckmischung:
Zutaten: WEIZENMEHL, Rapsöl, Zucker, Salz, Backtriebmittel
(Ammoniumhydrogencarbonat, Natriumhydrogencarbonat,
Dinatriumdiphosphat), Mohn, SESAM, Glukosesirup,
WEIZENMALZ, KÄSEPULVER, BUTTERMILCHPULVER, Hefe,
ROGGENMEHL, MOLKENPULVER, Fyuctese natürliches
Aroma, Maltodextrin, Säurerequlator (Naemhydroxid).
Säuerungsittel (Essigsäure), Pfeffer gemahlen.
GB Assortment of pretzel snacks:
Ingredients: WHEAT FLOUR, rapeseed oil, sugar, salt, raising
agents (ammonium hydrogen carbonate, sodium hydrogen
carbonate, disodium diphosphate), poppy seeds, SESAME,
glucose syrup, WHEAT MALT, CHEESE POWDER,
BUTTERMILK POWDER, yeast, RYE FLOUR, WHEY
POWDER, fructose, natural flavouring, maltodextrin, acidity
Tegulator (sodium hydroxide), acid (acetic acid), ground
pepper.
DMélange de biscuits salés:
Ingredients: FARINE DE FROMENT, huile de colza, sucre,
sel, poudres à lever (carbonate acide d'ammonium, carbonate
Bcde ue sodium, diphosphate disodique), pavot, SESAME,
op de glucose, MALT DE FROMENT, FROMAGE EN
POUDRE, BABEURRE EN POUDRE, levure, FARINE DE
SEIGLE, PETIT-LAIT EN POUDRE, fructose, arôme naturel,
maltodextrine, correcteur d'acidité (hydroxyde de sodium),
acidifiant (acide acétique), poivre moulu.
O Salatini assortiti:
Ingredienti: FARINA DI FRUMENTO, olio di colza, zucchero,
sale, agenti lievitanti (carbonato di ammonio, idrogenocar-
bonato di sodio, difosfati), papavero, SESAMO, sciroppo di
glucosio, MALTO DI FRUMENTO, FORMAGGIO IN POLVERE,
BURRO IN POLVERE, amido, FARINA DI SEGALE,
SOLETTI-
AUS ÖSTEK
REGIONALIT
höchste Prio
werden alle
Produkte be
im steirisch
produziert
GUT Z
V Palolf
VOHA ZL
Gesc
OHNE
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
      'repairs hyphenated line-break — idrogenocar-\\nbonato → idrogenocarbonato',
      () {
        final entry = result.firstWhere(
          (e) => e.toLowerCase().contains('idrogenocarbonato'),
          orElse: () => '',
        );
        expect(
          entry,
          isNotEmpty,
          reason: 'idrogenocarbonato must appear joined',
        );
        expect(result, isNot(contains('idrogenocar')));
      },
    );

    test('natürliches Aroma present (OCR may merge with adjacent word)', () {
      expect(
        result.any((e) => e.toLowerCase().contains('natürliches')),
        isTrue,
        reason: 'natürliches must appear somewhere in the ingredient list',
      );
    });

    test(
      'strips trailing footer noise — brand/origin text after last comma',
      () {
        // Marketing lines: "SOLETTI-", "AUS ÖSTEK", "GUT Z", "OHNE", etc.
        for (final noise in [
          'soletti',
          'aus östek',
          'regionalit',
          'gut z',
          'voha',
          'ohne',
        ]) {
          expect(
            result.any((e) => e.toLowerCase().contains(noise)),
            isFalse,
            reason: '"$noise" is footer noise and must be stripped',
          );
        }
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

    test(
      'Säurerequlator (OCR typo) kept as one token with its sub-ingredient',
      () {
        // Real OCR reads "Säurerequlator" (q not g) and "Naemhydroxid".
        // Sanitizer preserves structure; spelling is not corrected.
        final entry = result.firstWhere(
          (e) => e.toLowerCase().contains('säurereq'),
          orElse: () => '',
        );
        expect(entry, isNotEmpty, reason: 'Säurerequlator entry must exist');
        expect(entry.toLowerCase().contains('naemhydroxid'), isTrue);
      },
    );

    test(
      'acidity Tegulator (OCR typo) kept as one token with sub-ingredient',
      () {
        // Real OCR reads "acidity Tegulator" (capital T, r dropped).
        final entry = result.firstWhere(
          (e) => e.toLowerCase().contains('acidity'),
          orElse: () => '',
        );
        expect(entry, isNotEmpty, reason: 'acidity entry must exist');
        expect(entry.toLowerCase().contains('sodium hydroxide'), isTrue);
      },
    );

    test('Säuerungsittel (OCR typo) kept as one token with sub-ingredient', () {
      // Real OCR reads "Säuerungsittel" (missing m).
      final entry = result.firstWhere(
        (e) => e.toLowerCase().contains('säuerungsittel'),
        orElse: () => '',
      );
      expect(entry, isNotEmpty, reason: 'Säuerungsittel entry must exist');
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

    test('full pipeline: not halal when suspicious ingredients present', () {
      final result = ProductService.analyzeWithKeywords(ingredients);
      expect(result.isHalal, isFalse);
      expect(result.haram, isEmpty);
      expect(result.suspicious, isNotEmpty);
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

  group(
    'IngredientSanitizer.sanitizeByLanguage — Soletti 4-language label',
    () {
      late Map<String, List<String>> sections;

      setUpAll(() {
        sections = IngredientSanitizer.sanitizeByLanguage(_soletiOcr);
      });

      test('produces exactly 4 language sections', () {
        expect(sections.keys.toSet(), equals({'de', 'en', 'fr', 'it'}));
      });

      test('de section contains German ingredients', () {
        expect(
          sections['de']!.any((e) => e.toLowerCase().contains('weizenmehl')),
          isTrue,
        );
      });

      test(
        'en section contains English ingredients (bare GB code detected)',
        () {
          expect(
            sections['en'],
            isNotNull,
            reason: 'EN section must be detected',
          );
          expect(
            sections['en']!.any((e) => e.toLowerCase().contains('wheat flour')),
            isTrue,
          );
        },
      );

      test('fr section contains French ingredients', () {
        expect(
          sections['fr']!.any(
            (e) => e.toLowerCase().contains('farine de froment'),
          ),
          isTrue,
        );
      });

      test('it section contains Italian ingredients', () {
        expect(
          sections['it']!.any(
            (e) => e.toLowerCase().contains('farina di frumento'),
          ),
          isTrue,
        );
      });
    },
  );

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
