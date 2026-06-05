import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/constants/ingredient_keywords.dart';

void main() {
  group('IngredientKeywords — flavouring explanations', () {
    test('default flavouring explanation mentions alcohol extraction', () {
      final msg = IngredientKeywords.buildSuspiciousExplanation(
        suspicious: ['Aroma'],
        canonicals: {'Aroma': 'flavouring'},
        labels: const [],
        productName: '',
      );
      expect(msg, contains('animal-derived or extracted with alcohol'));
    });

    test('vegan label adopts alcohol-only wording for flavouring', () {
      final msg = IngredientKeywords.buildSuspiciousExplanation(
        suspicious: ['Aroma'],
        canonicals: {'Aroma': 'flavouring'},
        labels: const ['en:vegan'],
        productName: 'Cookies',
      );
      expect(msg, contains('vegan-certified'));
      expect(msg, contains('alcohol content cannot be ruled out'));
      expect(msg, contains('non-animal per certification'));
    });

    test('vegan label rewrites per-ingredient flavouring warning', () {
      final adjusted = IngredientKeywords.adjustFlavouringForVegan(
        suspicious: ['Aroma'],
        warnings: {'Aroma': 'old'},
        canonicals: {'Aroma': 'flavouring'},
        labels: const ['en:vegan'],
        productName: 'Cookies',
      );
      expect(
        adjusted.warnings['Aroma'],
        contains('alcohol used in extraction'),
      );
    });

    test('glycerol suspicious keeps animal-derived wording without vegan', () {
      final msg = IngredientKeywords.buildSuspiciousExplanation(
        suspicious: ['glycerol'],
        canonicals: {'glycerol': 'glycerol'},
        labels: const [],
        productName: '',
      );
      expect(msg, contains('may be animal-derived: glycerol'));
      expect(msg, isNot(contains('alcohol')));
    });

    test('vegetarian label does not adopt vegan flavouring explanation', () {
      final msg = IngredientKeywords.buildSuspiciousExplanation(
        suspicious: ['natürliches aroma'],
        canonicals: {'natürliches aroma': 'natural flavour'},
        labels: const ['en:vegetarian'],
        productName: 'Cookies',
      );
      expect(msg, contains('animal-derived or extracted with alcohol'));
      expect(msg, isNot(contains('vegan-certified')));
    });

    test('vegan + glycerol splits flavouring from other suspicious items', () {
      final msg = IngredientKeywords.buildSuspiciousExplanation(
        suspicious: ['natürliches aroma', 'glycerol'],
        canonicals: {
          'natürliches aroma': 'natural flavour',
          'glycerol': 'glycerol',
        },
        labels: const ['en:vegan'],
        productName: 'Cookies',
      );
      expect(msg, contains('non-animal per certification'));
      expect(msg, contains('alcohol content cannot be ruled out'));
      expect(msg, contains('may still be animal-derived: glycerol'));
    });
  });
}
