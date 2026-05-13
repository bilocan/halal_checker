import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/services/ingredient_contribution_service.dart';

void main() {
  // AppConfig.hasSupabase is false in tests (no --dart-define flags), so
  // submitIngredients returns false immediately without network calls.

  group('IngredientContributionService — no Supabase config', () {
    test('submitIngredients returns false', () async {
      final result = await IngredientContributionService.submitIngredients(
        barcode: '111222333',
        ingredientText: 'water, sugar, salt',
      );
      expect(result, isFalse);
    });

    test('submitIngredients with empty barcode returns false', () async {
      final result = await IngredientContributionService.submitIngredients(
        barcode: '',
        ingredientText: 'flour, water',
      );
      expect(result, isFalse);
    });
  });
}
