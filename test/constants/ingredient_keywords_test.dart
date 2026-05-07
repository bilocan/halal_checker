import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/constants/ingredient_keywords.dart';

void main() {
  // ── Data consistency ────────────────────────────────────────────────────────

  group('IngredientKeywords — haramVariants keys match haram map', () {
    test('every haramVariants key has a haram entry', () {
      for (final key in IngredientKeywords.haramVariants.keys) {
        expect(
          IngredientKeywords.haram.containsKey(key),
          isTrue,
          reason: '"$key" is in haramVariants but missing from haram',
        );
      }
    });

    test('every haram key has a haramVariants entry', () {
      for (final key in IngredientKeywords.haram.keys) {
        expect(
          IngredientKeywords.haramVariants.containsKey(key),
          isTrue,
          reason: '"$key" is in haram but missing from haramVariants',
        );
      }
    });
  });

  group(
    'IngredientKeywords — suspiciousVariants keys match suspicious map',
    () {
      test('every suspiciousVariants key has a suspicious entry', () {
        for (final key in IngredientKeywords.suspiciousVariants.keys) {
          expect(
            IngredientKeywords.suspicious.containsKey(key),
            isTrue,
            reason:
                '"$key" is in suspiciousVariants but missing from suspicious',
          );
        }
      });

      test('every suspicious key has a suspiciousVariants entry', () {
        for (final key in IngredientKeywords.suspicious.keys) {
          expect(
            IngredientKeywords.suspiciousVariants.containsKey(key),
            isTrue,
            reason:
                '"$key" is in suspicious but missing from suspiciousVariants',
          );
        }
      });
    },
  );

  group('IngredientKeywords — no overlap between haram and suspicious', () {
    test('haram and suspicious have no shared keys', () {
      final shared = IngredientKeywords.haram.keys.toSet().intersection(
        IngredientKeywords.suspicious.keys.toSet(),
      );
      expect(shared, isEmpty, reason: 'shared keys: $shared');
    });
  });

  group('IngredientKeywords — haramVariants non-empty lists', () {
    test('every haramVariants list has at least one entry', () {
      for (final entry in IngredientKeywords.haramVariants.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '"${entry.key}" haramVariants list is empty',
        );
      }
    });
  });

  group('IngredientKeywords — suspiciousVariants non-empty lists', () {
    test('every suspiciousVariants list has at least one entry', () {
      for (final entry in IngredientKeywords.suspiciousVariants.entries) {
        expect(
          entry.value,
          isNotEmpty,
          reason: '"${entry.key}" suspiciousVariants list is empty',
        );
      }
    });
  });

  // ── alcoholFamily ───────────────────────────────────────────────────────────

  group('IngredientKeywords — alcoholFamily', () {
    test('contains English alcohol', () {
      expect(IngredientKeywords.alcoholFamily.contains('alcohol'), isTrue);
    });
    test('contains ethanol', () {
      expect(IngredientKeywords.alcoholFamily.contains('ethanol'), isTrue);
    });
    test('contains German alkohol', () {
      expect(IngredientKeywords.alcoholFamily.contains('alkohol'), isTrue);
    });
    test('contains Turkish alkol', () {
      expect(IngredientKeywords.alcoholFamily.contains('alkol'), isTrue);
    });
    test('does not contain pork', () {
      expect(IngredientKeywords.alcoholFamily.contains('pork'), isFalse);
    });
  });

  // ── fattyAlcoholPrefix regex ─────────────────────────────────────────────────

  group('IngredientKeywords — fattyAlcoholPrefix', () {
    final re = IngredientKeywords.fattyAlcoholPrefix;

    test('matches "cetyl " prefix', () {
      expect(re.hasMatch('cetyl alcohol'), isTrue);
    });
    test('matches "stearyl " prefix', () {
      expect(re.hasMatch('stearyl alcohol'), isTrue);
    });
    test('matches "behenyl " prefix', () {
      expect(re.hasMatch('behenyl alcohol'), isTrue);
    });
    test('matches "lauryl " prefix', () {
      expect(re.hasMatch('lauryl alcohol'), isTrue);
    });
    test('matches "myristyl " prefix', () {
      expect(re.hasMatch('myristyl alcohol'), isTrue);
    });
    test('matches "lanolin " prefix', () {
      expect(re.hasMatch('lanolin alcohol'), isTrue);
    });
    test('does not match plain alcohol', () {
      expect(re.hasMatch('alcohol'), isFalse);
    });
    test('does not match ethanol', () {
      expect(re.hasMatch('ethanol'), isFalse);
    });
    test('is case-insensitive', () {
      expect(re.hasMatch('Cetyl Alcohol'), isTrue);
    });
  });

  // ── word boundary patterns ───────────────────────────────────────────────────
  // Behavioural coverage lives in keyword_analysis_test.dart via
  // ProductService.matchesKeyword, which uses these constants internally.

  group('IngredientKeywords — wPre / wPost word boundary patterns', () {
    test('wPre is non-empty', () {
      expect(IngredientKeywords.wPre, isNotEmpty);
    });
    test('wPost is non-empty', () {
      expect(IngredientKeywords.wPost, isNotEmpty);
    });
  });
}
