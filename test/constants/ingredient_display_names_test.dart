import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/constants/ingredient_display_names.dart';
import 'package:halal_checker/constants/ingredient_keywords.dart';

void main() {
  // ── Data consistency ─────────────────────────────────────────────────────────

  group('IngredientDisplayNames — keys match haram + suspicious maps', () {
    final allKeywords = {
      ...IngredientKeywords.haram.keys,
      ...IngredientKeywords.suspicious.keys,
    };

    test('every display-name key is a known haram or suspicious keyword', () {
      for (final key in IngredientDisplayNames.names.keys) {
        expect(
          allKeywords.contains(key),
          isTrue,
          reason: '"$key" has a display name but is not in haram or suspicious',
        );
      }
    });
  });

  // ── IngredientDisplayNames.of() ──────────────────────────────────────────────

  group('IngredientDisplayNames.of — returns localized name', () {
    test('returns German name for alcohol/de', () {
      expect(IngredientDisplayNames.of('alcohol', 'de'), equals('Alkohol'));
    });
    test('returns Turkish name for pork/tr', () {
      expect(IngredientDisplayNames.of('pork', 'tr'), equals('domuz'));
    });
    test('returns French name for gelatin/fr', () {
      expect(IngredientDisplayNames.of('gelatin', 'fr'), equals('gélatine'));
    });
    test('returns Hungarian name for beer/hu', () {
      expect(IngredientDisplayNames.of('beer', 'hu'), equals('sör'));
    });
  });

  group('IngredientDisplayNames.of — falls back to canonical', () {
    test('returns canonical when locale is absent for that keyword', () {
      // "whisky" has only 'tr' entry — any other locale falls back
      expect(IngredientDisplayNames.of('whisky', 'de'), equals('whisky'));
    });
    test('returns canonical for unknown keyword', () {
      expect(
        IngredientDisplayNames.of('unknown-ingredient', 'de'),
        equals('unknown-ingredient'),
      );
    });
    test('returns canonical for empty locale string', () {
      expect(IngredientDisplayNames.of('alcohol', ''), equals('alcohol'));
    });
  });

  // ── Locale map non-empty ─────────────────────────────────────────────────────

  group('IngredientDisplayNames — locale maps are non-empty', () {
    test('every keyword with a display-name entry has at least one locale', () {
      for (final entry in IngredientDisplayNames.names.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '"${entry.key}" has an empty locale map',
        );
      }
    });
  });

  // ── fallback for keywords with no display entry ───────────────────────────

  group(
    'IngredientDisplayNames.of — haram/suspicious keywords without display entry fall back',
    () {
      test('haram key with no display entry returns canonical', () {
        // 'prosecco' is in IngredientKeywords.haram but has no display name entry
        expect(IngredientDisplayNames.of('prosecco', 'de'), equals('prosecco'));
      });

      test('suspicious key with no display entry returns canonical', () {
        // 'e322' is in IngredientKeywords.suspicious but has no display name entry
        expect(IngredientDisplayNames.of('e322', 'tr'), equals('e322'));
      });

      test('completely unknown key returns canonical regardless of locale', () {
        expect(IngredientDisplayNames.of('xylitol', 'fr'), equals('xylitol'));
      });
    },
  );
}
