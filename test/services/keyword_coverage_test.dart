// Data-driven behavioural coverage for every keyword in IngredientKeywords.
//
// Unlike keyword_analysis_test.dart (which hand-picks specific keywords) or
// ingredient_keywords_test.dart (which only checks map structure), this file
// iterates IngredientKeywords.haram/suspicious + their variant lists directly.
// Adding a new keyword or variant to lib/constants/ingredient_keywords.dart is
// automatically exercised here — no new test case needs to be written.
import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/constants/ingredient_keywords.dart';
import 'package:halal_checker/services/product_service.dart';

void main() {
  group('haram keywords — every variant is flagged haram', () {
    for (final canonical in IngredientKeywords.haram.keys) {
      final variants =
          IngredientKeywords.haramVariants[canonical] ?? [canonical];
      for (final variant in variants) {
        test('"$variant" ($canonical) → haram, not suspicious', () {
          final r = ProductService.analyzeWithKeywords([variant]);
          expect(
            r.haram,
            contains(variant),
            reason: '"$variant" should be flagged haram via "$canonical"',
          );
          expect(r.isHalal, isFalse);
          expect(
            r.suspicious,
            isEmpty,
            reason: 'haram match should take precedence over suspicious',
          );
        });
      }
    }
  });

  group('suspicious keywords — every variant is flagged suspicious', () {
    for (final canonical in IngredientKeywords.suspicious.keys) {
      final variants =
          IngredientKeywords.suspiciousVariants[canonical] ?? [canonical];
      for (final variant in variants) {
        test('"$variant" ($canonical) → suspicious, not haram', () {
          final r = ProductService.analyzeWithKeywords([variant]);
          expect(
            r.haram,
            isEmpty,
            reason: '"$variant" should not be flagged haram',
          );
          expect(
            r.suspicious,
            contains(variant),
            reason: '"$variant" should be flagged suspicious via "$canonical"',
          );
          expect(r.isHalal, isFalse);
        });
      }
    }
  });
}
