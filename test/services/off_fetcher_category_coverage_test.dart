// Data-driven behavioural coverage for every OFF category tag declared in
// FoodCategories. Unlike food_categories_test.dart (which only spot-checks a
// handful of hardcoded entries) or the hand-picked cases in off_fetcher_test.dart,
// this file iterates FoodCategories.halal/haram/animalProduct/nonFood directly.
// Adding a new category tag to lib/constants/food_categories.dart is
// automatically exercised here — no new test case needs to be written.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:halal_checker/constants/food_categories.dart';
import 'package:halal_checker/services/off_fetcher.dart';

Future<dynamic> _fetchForCategory(
  String category, {
  String name = 'Category Test Product',
  String ingredientsText = '',
  List<String> labelsTags = const [],
}) {
  final body = jsonEncode({
    'status': 1,
    'product': {
      'product_name': name,
      'categories_tags': [category],
      'ingredients_text': ingredientsText,
      'labels_tags': labelsTags,
    },
  });
  // categories can contain non-Latin1 characters (e.g. Turkish ğ/ı) — encode
  // as UTF-8 bytes explicitly, since http.Response(body, 200) defaults to
  // Latin-1 and throws on code points above 255.
  final client = MockClient(
    (_) async => http.Response.bytes(
      utf8.encode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  );
  return OffFetcher(client).fetch('0000000000000', OffFetcher.offBaseUrl);
}

void main() {
  group('FoodCategories.halal — every category is inherently halal', () {
    for (final category in FoodCategories.halal) {
      test('"$category" with no ingredients → isHalal true', () async {
        final product = await _fetchForCategory(category);
        expect(product, isNotNull);
        expect(
          product!.isHalal,
          isTrue,
          reason: '"$category" should be inherently halal',
        );
        expect(product.isUnknown, isFalse);
      });
    }
  });

  group('FoodCategories.haram — every category is flagged not halal', () {
    for (final category in FoodCategories.haram) {
      test('"$category" → isHalal false', () async {
        final product = await _fetchForCategory(category);
        expect(product, isNotNull);
        expect(
          product!.isHalal,
          isFalse,
          reason: '"$category" should be haram by category',
        );
        expect(product.explanation, contains('not permissible'));
      });
    }
  });

  group(
    'FoodCategories.nonFood — every category marks the product non-food',
    () {
      for (final category in FoodCategories.nonFood) {
        test('"$category" → isNonFood true, isHalal false', () async {
          final product = await _fetchForCategory(category);
          expect(product, isNotNull);
          expect(
            product!.isNonFood,
            isTrue,
            reason: '"$category" should be treated as non-food',
          );
          expect(product.isHalal, isFalse);
        });
      }
    },
  );

  group(
    'FoodCategories.animalProduct — requires halal cert without a halal label',
    () {
      for (final category in FoodCategories.animalProduct) {
        test(
          '"$category" without halal label → requiresHalalCert true',
          () async {
            final product = await _fetchForCategory(category);
            expect(product, isNotNull);
            expect(
              product!.requiresHalalCert,
              isTrue,
              reason: '"$category" should require halal certification',
            );
            expect(product.isHalal, isFalse);
          },
        );
      }
    },
  );

  group(
    'FoodCategories.animalProduct — halal label suppresses cert requirement',
    () {
      for (final category in FoodCategories.animalProduct) {
        test('"$category" with halal label → requiresHalalCert false', () async {
          final product = await _fetchForCategory(
            category,
            labelsTags: ['halal'],
          );
          expect(product, isNotNull);
          expect(
            product!.requiresHalalCert,
            isFalse,
            reason:
                '"$category" with a halal label should not require certification',
          );
        });
      }
    },
  );
}
