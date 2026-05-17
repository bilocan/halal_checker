import 'package:flutter_test/flutter_test.dart';
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
  });
}
