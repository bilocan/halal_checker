import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/services/keyword_normalization.dart';

void main() {
  group('KeywordNormalization.mergeVariants', () {
    test('includes canonical and deduplicates case-insensitively', () {
      expect(
        KeywordNormalization.mergeVariants(
          canonical: 'Pork',
          variants: ['pork', 'schwein', 'SCHWEIN'],
          translations: {'de': 'Schwein', 'tr': 'domuz'},
        ),
        ['domuz', 'pork', 'schwein'],
      );
    });

    test('returns sorted list with only canonical when extras empty', () {
      expect(KeywordNormalization.mergeVariants(canonical: 'gelatin'), [
        'gelatin',
      ]);
    });
  });

  group('KeywordNormalization.parseTranslationsText', () {
    test('parses colon and equals separators', () {
      final map = KeywordNormalization.parseTranslationsText('''
de: schwein
tr=domuz
fr: porc
''');
      expect(map, {'de': 'schwein', 'tr': 'domuz', 'fr': 'porc'});
    });

    test('ignores unsupported locale codes', () {
      final map = KeywordNormalization.parseTranslationsText(
        'xx: foo\nde: bar',
      );
      expect(map, {'de': 'bar'});
    });
  });

  group('KeywordNormalization.ruleContainsAlias', () {
    test('matches canonical, variants, and translations', () {
      final rule = {
        'canonical': 'pork',
        'variants': ['schwein'],
        'translations': {'tr': 'domuz'},
      };
      expect(KeywordNormalization.ruleContainsAlias(rule, 'pork'), isTrue);
      expect(KeywordNormalization.ruleContainsAlias(rule, 'SCHWEIN'), isTrue);
      expect(KeywordNormalization.ruleContainsAlias(rule, 'domuz'), isTrue);
      expect(KeywordNormalization.ruleContainsAlias(rule, 'beef'), isFalse);
    });
  });
}
