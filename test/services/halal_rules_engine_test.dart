import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/constants/ingredient_keywords.dart';
import 'package:halal_checker/services/halal_rules_engine.dart';

void main() {
  const engine = HalalRulesEngine();

  group('HalalRulesEngine.analyzeIngredients', () {
    test('returns haram verdict when a haram ingredient matches', () {
      final result = engine.analyzeIngredients(['water', 'pork', 'salt']);

      expect(result.verdict, HalalRuleVerdict.haram);
      expect(result.isHalal, isFalse);
      expect(result.haram, contains('pork'));
      expect(result.warnings['pork'], contains('pork'));
      expect(result.matches.single.category, HalalRuleCategory.ingredient);
    });

    test(
      'returns halal verdict with suspicious matches for doubtful items',
      () {
        final result = engine.analyzeIngredients(['flour', 'e471', 'salt']);

        expect(result.verdict, HalalRuleVerdict.halal);
        expect(result.isHalal, isTrue);
        expect(result.haram, isEmpty);
        expect(result.suspicious, contains('e471'));
        expect(result.explanation, contains('require verification'));
      },
    );

    test('keeps alcohol-free and fatty alcohol out of haram matches', () {
      final result = engine.analyzeIngredients([
        'malt extract alcohol-free',
        'cetyl alcohol',
      ]);

      expect(result.haram, isEmpty);
      expect(result.verdict, HalalRuleVerdict.halal);
    });

    group('negation suppression', () {
      // Regression: barcode 8690766143732 — ingredient text contains allergen-free
      // declarations ("enthält keine Zutaten vom Schwein", "ne contient pas … porc")
      // which were falsely triggering the pork keyword.
      test('German "keine" before keyword suppresses haram match', () {
        final result = engine.analyzeIngredients([
          'enthält keine zutaten vom schwein',
        ]);
        expect(result.verdict, HalalRuleVerdict.halal);
        expect(result.haram, isEmpty);
      });

      test('French "pas" before keyword suppresses haram match', () {
        final result = engine.analyzeIngredients([
          "ne contient pas d'ingrédients provenant de porc",
        ]);
        expect(result.verdict, HalalRuleVerdict.halal);
        expect(result.haram, isEmpty);
      });

      test('Dutch "geen" before keyword suppresses haram match', () {
        final result = engine.analyzeIngredients(['bevat geen varkensvlees']);
        expect(result.verdict, HalalRuleVerdict.halal);
        expect(result.haram, isEmpty);
      });

      test('English "no" before keyword suppresses haram match', () {
        final result = engine.analyzeIngredients(['contains no pork']);
        expect(result.verdict, HalalRuleVerdict.halal);
        expect(result.haram, isEmpty);
      });

      test('actual pork ingredient without negation is still flagged', () {
        final result = engine.analyzeIngredients(['schwein', 'salz']);
        expect(result.verdict, HalalRuleVerdict.haram);
        expect(result.haram, contains('schwein'));
      });

      test(
        'negation in one chunk does not suppress a real match in another',
        () {
          final result = engine.analyzeIngredients([
            'enthält keine zutaten vom schwein',
            'schweinefleisch',
          ]);
          expect(result.verdict, HalalRuleVerdict.haram);
          expect(result.haram, contains('schweinefleisch'));
        },
      );
    });
  });

  group('HalalRulesEngine custom rule sets', () {
    test('can merge app-managed custom keywords', () {
      final customEngine = engine.merge(
        const HalalKeywordRuleSet(
          haram: {'test additive': 'Custom haram rule'},
          haramVariants: {
            'test additive': ['additive x'],
          },
        ),
      );

      final result = customEngine.analyzeIngredients(['additive x']);

      expect(result.verdict, HalalRuleVerdict.haram);
      expect(result.haram, contains('additive x'));
      expect(result.warnings['additive x'], 'Custom haram rule');
    });

    test('merge preserves base rules alongside custom rules', () {
      final customEngine = engine.merge(
        const HalalKeywordRuleSet(haram: {'mycustomthing': 'Custom'}),
      );

      final result = customEngine.analyzeIngredients(['pork', 'mycustomthing']);

      expect(result.haram, containsAll(['pork', 'mycustomthing']));
    });
  });

  group('HalalRulesResult fields', () {
    test('checkedValues contains all analyzed ingredients', () {
      final result = engine.analyzeIngredients(['water', 'salt', 'pork']);
      expect(result.checkedValues, containsAll(['water', 'salt', 'pork']));
      expect(result.checkedValues.length, 3);
    });

    test('checkedValues is unmodifiable', () {
      final result = engine.analyzeIngredients(['water']);
      expect(
        () => (result.checkedValues as dynamic).add('extra'),
        throwsUnsupportedError,
      );
    });

    test(
      'checkedRuleCount equals default haram + suspicious keyword count',
      () {
        final result = engine.analyzeIngredients([]);
        expect(
          result.checkedRuleCount,
          IngredientKeywords.haram.length +
              IngredientKeywords.suspicious.length,
        );
      },
    );

    test('translations populated when ingredient is in another language', () {
      // 'alkohol' matches canonical 'alcohol' via haramVariants but does not contain 'alcohol'
      final result = engine.analyzeIngredients(['alkohol']);
      expect(result.translations, containsPair('alkohol', 'alcohol'));
    });

    test(
      'translations absent when ingredient text already contains canonical',
      () {
        // 'pork fat' contains 'pork', so _needsTranslation returns false
        final result = engine.analyzeIngredients(['pork fat']);
        expect(result.translations.containsKey('pork fat'), isFalse);
      },
    );
  });

  group('explanation strings', () {
    test('haram explanation names the offending ingredient', () {
      final result = engine.analyzeIngredients(['pork', 'salt']);
      expect(result.explanation, contains('pork'));
      expect(result.explanation, contains('not permissible'));
    });

    test('suspicious-only explanation mentions verification needed', () {
      final result = engine.analyzeIngredients(['e471']);
      expect(result.explanation, contains('require verification'));
    });

    test('clean list explanation says no haram detected', () {
      final result = engine.analyzeIngredients(['water', 'salt']);
      expect(result.explanation, contains('No haram or suspicious'));
    });

    test('empty ingredient list explanation says no data available', () {
      final result = engine.analyzeIngredients([]);
      expect(result.explanation, contains('No ingredient data'));
    });
  });

  group('HalalRulesEngine static helpers', () {
    test('isFattyAlcohol returns true for cosmetic fatty alcohols', () {
      expect(HalalRulesEngine.isFattyAlcohol('cetyl alcohol'), isTrue);
      expect(HalalRulesEngine.isFattyAlcohol('stearyl alcohol'), isTrue);
      expect(HalalRulesEngine.isFattyAlcohol('lauryl alcohol'), isTrue);
    });

    test('isFattyAlcohol returns false for ethanol and plain alcohol', () {
      expect(HalalRulesEngine.isFattyAlcohol('ethanol'), isFalse);
      expect(HalalRulesEngine.isFattyAlcohol('alcohol'), isFalse);
    });

    test('canonicalDisplay returns locale-specific name when available', () {
      expect(HalalRulesEngine.canonicalDisplay('alcohol', 'de'), 'Alkohol');
      expect(HalalRulesEngine.canonicalDisplay('alcohol', 'tr'), 'alkol');
    });

    test('canonicalDisplay falls back to canonical for unknown locale', () {
      expect(HalalRulesEngine.canonicalDisplay('alcohol', 'xx'), 'alcohol');
    });
  });

  group('HalalRulesEngine.matchesKeyword', () {
    test('returns true when ingredient contains a known keyword variant', () {
      expect(engine.matchesKeyword('pork rinds', 'pork'), isTrue);
      expect(engine.matchesKeyword('alkohol', 'alcohol'), isTrue);
      expect(engine.matchesKeyword('bier', 'beer'), isTrue);
    });

    test('returns false for unrelated ingredients', () {
      expect(engine.matchesKeyword('water', 'pork'), isFalse);
      expect(engine.matchesKeyword('salt', 'alcohol'), isFalse);
    });

    test('respects fatty-alcohol exclusion', () {
      expect(engine.matchesKeyword('cetyl alcohol', 'alcohol'), isFalse);
    });

    test('respects alcohol-free exclusion', () {
      expect(engine.matchesKeyword('malt alcohol-free', 'alcohol'), isFalse);
    });
  });

  group('HalalKeywordRuleSet', () {
    test('ruleCount equals haram + suspicious keyword counts', () {
      const ruleSet = HalalKeywordRuleSet();
      expect(
        ruleSet.ruleCount,
        IngredientKeywords.haram.length + IngredientKeywords.suspicious.length,
      );
    });

    test('custom rule set ruleCount reflects only its own rules', () {
      const ruleSet = HalalKeywordRuleSet(
        haram: {'x': 'reason x', 'y': 'reason y'},
        suspicious: {'z': 'reason z'},
      );
      expect(ruleSet.ruleCount, 3);
    });
  });

  group('multilingual variant detection', () {
    test('German bier is detected as beer (haram)', () {
      final result = engine.analyzeIngredients(['bier']);
      expect(result.verdict, HalalRuleVerdict.haram);
      expect(result.haram, contains('bier'));
    });

    test('German wein is detected as wine (haram)', () {
      final result = engine.analyzeIngredients(['wein']);
      expect(result.verdict, HalalRuleVerdict.haram);
    });

    test('Turkish bira is detected as beer (haram)', () {
      final result = engine.analyzeIngredients(['bira']);
      expect(result.verdict, HalalRuleVerdict.haram);
    });

    test('German schweinefleisch is detected as pork (haram)', () {
      final result = engine.analyzeIngredients(['schweinefleisch']);
      expect(result.verdict, HalalRuleVerdict.haram);
    });
  });

  group('verdict priority', () {
    test('haram wins when both haram and suspicious ingredients present', () {
      final result = engine.analyzeIngredients(['pork', 'e471', 'flour']);
      expect(result.verdict, HalalRuleVerdict.haram);
      expect(result.haram, contains('pork'));
      expect(result.suspicious, contains('e471'));
      expect(result.isHalal, isFalse);
    });

    test('empty ingredient list gives halal verdict', () {
      final result = engine.analyzeIngredients([]);
      expect(result.verdict, HalalRuleVerdict.halal);
      expect(result.isHalal, isTrue);
      expect(result.matches, isEmpty);
    });
  });

  group('additional negation languages', () {
    test('Italian "senza" before keyword suppresses haram match', () {
      final result = engine.analyzeIngredients(['senza maiale']);
      expect(result.verdict, HalalRuleVerdict.halal);
      expect(result.haram, isEmpty);
    });

    test('Spanish "sin" before keyword suppresses haram match', () {
      final result = engine.analyzeIngredients(['sin cerdo']);
      expect(result.verdict, HalalRuleVerdict.halal);
      expect(result.haram, isEmpty);
    });

    test('"without" before keyword suppresses haram match', () {
      final result = engine.analyzeIngredients(['made without alcohol']);
      expect(result.verdict, HalalRuleVerdict.halal);
      expect(result.haram, isEmpty);
    });

    test('"free from" before keyword suppresses haram match', () {
      final result = engine.analyzeIngredients(['free from pork']);
      expect(result.verdict, HalalRuleVerdict.halal);
      expect(result.haram, isEmpty);
    });

    test('Hungarian "nem" before keyword suppresses haram match', () {
      final result = engine.analyzeIngredients(['nem tartalmaz schwein']);
      expect(result.verdict, HalalRuleVerdict.halal);
      expect(result.haram, isEmpty);
    });

    test('Hungarian "mentes" before keyword suppresses haram match', () {
      final result = engine.analyzeIngredients(['mentes schwein']);
      expect(result.verdict, HalalRuleVerdict.halal);
      expect(result.haram, isEmpty);
    });

    test('CS/SR "bez" before keyword suppresses haram match', () {
      final result = engine.analyzeIngredients(['bez schwein']);
      expect(result.verdict, HalalRuleVerdict.halal);
      expect(result.haram, isEmpty);
    });

    test('"free of" before keyword suppresses haram match', () {
      final result = engine.analyzeIngredients(['free of pork']);
      expect(result.verdict, HalalRuleVerdict.halal);
      expect(result.haram, isEmpty);
    });
  });

  group('false positive regressions', () {
    // Product 9000144046903 — white wine vinegar
    // "weißweinessig" was matching the Dutch whey variant "wei" at position 0
    // because Dart's regex engine case-folds ß → SS under caseSensitive:false,
    // pushing it outside the À-ɏ range in the lookahead character class.
    test('weißweinessig (product 9000144046903) does not trigger whey', () {
      final result = engine.analyzeIngredients(['weißweinessig']);
      expect(result.suspicious, isEmpty);
      expect(result.haram, isEmpty);
      expect(result.verdict, HalalRuleVerdict.halal);
    });

    test('wein still detected as haram when it stands alone', () {
      final result = engine.analyzeIngredients(['wein']);
      expect(result.verdict, HalalRuleVerdict.haram);
    });

    // Product 9008700236522 — tea drink
    // Bare "aroma" was word-boundary-matching the 'flavouring' suspicious
    // keyword even when the rest of the token identified a plant-derived source.
    test(
      'aroma tee-extrakt token (product 9008700236522) is not suspicious',
      () {
        final result = engine.analyzeIngredients([
          'aroma. tee-extrakt: mind. 1',
        ]);
        expect(result.suspicious, isEmpty);
      },
    );

    // Product 4000539003004 — Chocolate Cognac
    // "aroma vanillin" falsely triggered suspicious; cognac keeps it haram.
    test(
      'aroma vanillin token (product 4000539003004) does not flag suspicious',
      () {
        final result = engine.analyzeIngredients([
          'aroma vanillin. kann haselnüsse und andere schalenfrüchte enthalten.',
        ]);
        expect(result.suspicious, isEmpty);
      },
    );

    test('cognac still marks product 4000539003004 as haram', () {
      final result = engine.analyzeIngredients([
        'cognac',
        'aroma vanillin. kann haselnüsse und andere schalenfrüchte enthalten.',
      ]);
      expect(result.verdict, HalalRuleVerdict.haram);
      expect(result.haram, contains('cognac'));
    });

    // Smoke-test: qualified aroma forms are still caught
    test('natürliches aroma is still suspicious', () {
      final result = engine.analyzeIngredients(['natürliches aroma']);
      expect(result.suspicious, isNotEmpty);
    });

    test('natural flavouring is still suspicious', () {
      final result = engine.analyzeIngredients(['natural flavouring']);
      expect(result.suspicious, isNotEmpty);
    });

    // "lactosérum" (FR whey) contains "rum" after the accented "é".
    // ASCII \b treats "é" as a non-word char, creating a false boundary.
    // wPre/wPost cover À-ɏ so "é" is treated as a word char → no match.
    test('lactosérum does not false-positive on "rum"', () {
      final result = engine.analyzeIngredients(['poudre de lactosérum (lait)']);
      expect(result.haram, isEmpty);
    });

    test('standalone rum is still haram', () {
      final result = engine.analyzeIngredients(['rum']);
      expect(result.verdict, HalalRuleVerdict.haram);
    });

    // Dutch "aroma's" (plural of aroma) is a vague flavouring term and must
    // be flagged, unlike "aroma vanillin" or "aroma tee-extrakt" which name
    // a specific source and are intentionally excluded.
    test("Dutch aroma's is suspicious with flavouring canonical", () {
      final result = engine.analyzeIngredients(["aroma's"]);
      expect(result.suspicious, equals(["aroma's"]));
      expect(result.canonicals["aroma's"], equals('flavouring'));
    });
  });
}
