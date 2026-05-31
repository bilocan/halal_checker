import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/halal_rules_engine.dart';
import 'package:halal_checker/services/ingredient_resolution.dart';
import 'package:halal_checker/services/keyword_multi_source.dart';

void main() {
  group('isAnalyzableScript', () {
    test('Latin text is analyzable', () {
      expect(isAnalyzableScript('water, pork, salt'), isTrue);
    });

    test('Cyrillic without Latin is not analyzable', () {
      expect(isAnalyzableScript('частично финомляно свинско месо'), isFalse);
    });
  });

  group('resolveOffIngredientAnalysis', () {
    test('Bulgarian primary adds English fallback source', () {
      final resolved = resolveOffIngredientAnalysis({
        'ingredients_lc': 'bg',
        'ingredients_text': 'частично финомляно свинско месо, вода',
        'ingredients_text_en': '80% pork meat is partially minced, water',
        'ingredients': [
          {'id': 'en:water', 'text': 'вода'},
        ],
      });

      expect(resolved.displayLang, 'bg');
      expect(resolved.analyzeLang, 'en');
      expect(resolved.sources.any((s) => s.key == 'off_en'), isTrue);
    });
  });

  group('analyzeIngredientsFromSources', () {
    const engine = HalalRulesEngine();

    test('English fallback catches pork', () {
      final result = analyzeIngredientsFromSources(
        engine: engine,
        sources: [
          const IngredientAnalysisSource(
            key: 'primary',
            ingredients: ['свинско месо'],
          ),
          const IngredientAnalysisSource(
            key: 'off_en',
            ingredients: ['80% pork meat is partially minced'],
          ),
        ],
        displayIngredients: ['свинско месо'],
        analyzeLang: 'en',
      );

      expect(result.isHalal, isFalse);
      expect(result.keywordMatchSource, contains('off_en'));
      expect(result.haram, isNotEmpty);
    });

    test('Cyrillic label with pork terms matches via primary source', () {
      final result = analyzeIngredientsFromSources(
        engine: engine,
        sources: [
          const IngredientAnalysisSource(
            key: 'primary',
            ingredients: ['частично финомляно свинско месо'],
          ),
        ],
        displayIngredients: ['частично финомляно свинско месо'],
      );

      expect(result.isUnknown, isFalse);
      expect(result.isHalal, isFalse);
      expect(result.keywordMatchSource, 'primary');
      expect(result.haram, isNotEmpty);
      expect(result.explanation.toLowerCase(), contains('keyword matching'));
    });

    test('Cyrillic with partial taxonomy but no pork stays unanalyzable', () {
      final result = analyzeIngredientsFromSources(
        engine: engine,
        sources: [
          const IngredientAnalysisSource(key: 'primary', ingredients: ['вода']),
          const IngredientAnalysisSource(
            key: 'off_taxonomy',
            ingredients: ['water', 'salt'],
          ),
        ],
        displayIngredients: ['вода'],
      );

      expect(result.isUnknown, isTrue);
      expect(result.keywordMatchSource, 'unanalyzable');
      expect(result.haram, isEmpty);
    });
  });
}
