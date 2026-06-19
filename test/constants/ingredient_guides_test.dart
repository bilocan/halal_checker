import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/constants/ingredient_guides.dart';
import 'package:halal_checker/models/product.dart';

void main() {
  group('IngredientGuides', () {
    test('byCanonical matches shared fixture (web sync contract)', () {
      final fixturePath = 'test/fixtures/ingredient_guides_canonical_map.json';
      final raw = File(fixturePath).readAsStringSync();
      final fixture = jsonDecode(raw) as Map<String, dynamic>;

      expect(IngredientGuides.byCanonical.length, fixture.length);
      for (final entry in fixture.entries) {
        final slugs = (entry.value as List).cast<String>();
        expect(
          IngredientGuides.byCanonical[entry.key],
          slugs,
          reason: 'canonical "${entry.key}"',
        );
      }
    });

    test('every guide slug has localized card copy', () {
      final slugs = IngredientGuides.byCanonical.values
          .expand((list) => list)
          .toSet();
      for (final slug in slugs) {
        expect(
          IngredientGuides.copyBySlug[slug],
          isNotNull,
          reason: 'missing copy for slug "$slug"',
        );
      }
    });

    test('natural flavoring resolves to alcohol in flavorings guide', () {
      expect(
        IngredientGuides.slugsForCanonical('natural flavour'),
        contains('gida-aromalarinda-alkol'),
      );
      expect(
        IngredientGuides.canonicalForTerm('natural flavoring'),
        'natural flavour',
      );
      expect(
        IngredientGuides.slugsForCanonical(
          IngredientGuides.canonicalForTerm('natural flavoring')!,
        ),
        contains('gida-aromalarinda-alkol'),
      );
    });

    test('en:e471 additive tag links to e-numbers guide', () {
      final canonical = IngredientGuides.canonicalForTerm('en:e471');
      expect(canonical, 'e471');
      expect(
        IngredientGuides.slugsForCanonical(canonical!),
        contains('e-numbers-guide'),
      );
    });

    test('dedupes guide slugs on product', () {
      final product = Product(
        barcode: '4014400928907',
        name: 'Test',
        ingredients: const ['natural flavor', 'natürliches aroma'],
        isHalal: false,
        haramIngredients: const [],
        suspiciousIngredients: const ['natural flavor', 'natürliches aroma'],
        ingredientWarnings: const {},
        labels: const [],
        ingredientCanonicals: const {
          'natural flavor': 'natural flavour',
          'natürliches aroma': 'natural flavour',
        },
      );

      expect(IngredientGuides.slugsForProduct(product), [
        'gida-aromalarinda-alkol',
      ]);
    });

    test('blog URL uses locale prefix', () {
      final link = IngredientGuides.linkForSlug(
        'gida-aromalarinda-alkol',
        'de',
      );
      expect(link?.url, 'https://halalscan.at/de/blog/gida-aromalarinda-alkol');
    });

    test('linksForTerm returns localized copy for carmine guide', () {
      final links = IngredientGuides.linksForTerm('carmine', 'de');
      expect(links, hasLength(1));
      expect(links.first.title, 'Ist Karmin (E120) halal?');
      expect(links.first.url, contains('/de/blog/carmine-e120'));
    });

    test('flavouring term links to both aroma guides', () {
      final slugs = IngredientGuides.linksForTerm(
        'flavouring',
        'en',
      ).map((link) => link.slug).toList();
      expect(slugs, [
        'gida-aromalarinda-alkol',
        'mono-propylene-glycol-halal-alternative',
      ]);
    });
  });
}
