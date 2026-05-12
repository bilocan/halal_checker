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
