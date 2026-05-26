import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/product.dart';

// Builds a minimal valid Product JSON map.
Map<String, dynamic> _baseJson({
  String barcode = '1234567890',
  String name = 'Test Product',
  bool isHalal = true,
  bool analyzedByAI = false,
  String? analysisMethod,
}) => {
  'barcode': barcode,
  'name': name,
  'ingredients': <String>[],
  'isHalal': isHalal,
  'isUnknown': false,
  'isNonFood': false,
  'haramIngredients': <String>[],
  'suspiciousIngredients': <String>[],
  'ingredientWarnings': <String, String>{},
  'labels': <String>[],
  'explanation': '',
  'analyzedByAI': analyzedByAI,
  'analysisMethod': ?analysisMethod,
};

void main() {
  group('Product.fromJson — analysisMethod field', () {
    test('analysisMethod: ai → parsed correctly', () {
      final p = Product.fromJson(
        _baseJson(analyzedByAI: true, analysisMethod: 'ai'),
      );
      expect(p.analysisMethod, equals('ai'));
      expect(p.analyzedByAI, isTrue);
    });

    test('analysisMethod: keyword → parsed correctly', () {
      final p = Product.fromJson(
        _baseJson(analyzedByAI: false, analysisMethod: 'keyword'),
      );
      expect(p.analysisMethod, equals('keyword'));
      expect(p.analyzedByAI, isFalse);
    });

    test('missing analysisMethod → null (backward compat)', () {
      final p = Product.fromJson(_baseJson());
      expect(p.analysisMethod, isNull);
    });

    test('analysisMethod survives toJson/fromJson round-trip', () {
      final original = Product.fromJson(
        _baseJson(analyzedByAI: true, analysisMethod: 'ai'),
      );
      final roundTripped = Product.fromJson(original.toJson());
      expect(roundTripped.analysisMethod, equals('ai'));
    });

    test('copyWith preserves analysisMethod when not overridden', () {
      final p = Product.fromJson(_baseJson(analysisMethod: 'keyword'));
      final copy = p.copyWith(isHalal: false);
      expect(copy.analysisMethod, equals('keyword'));
    });

    test('copyWith can override analysisMethod', () {
      final p = Product.fromJson(_baseJson(analysisMethod: 'keyword'));
      final updated = p.copyWith(analysisMethod: 'ai');
      expect(updated.analysisMethod, equals('ai'));
    });
  });

  group('Product.fromJson — analysisMethod inferred from analyzedByAI', () {
    test('legacy JSON with only analyzedByAI:true → analysisMethod null', () {
      // Old backend responses only had analyzedByAI; analysisMethod was not present.
      // analysisMethod should be null (not 'ai') to avoid false assertion.
      final p = Product.fromJson(_baseJson(analyzedByAI: true));
      expect(p.analysisMethod, isNull);
      expect(p.analyzedByAI, isTrue);
    });
  });

  group('Product — isManaged field', () {
    test('isManaged defaults to false when absent', () {
      final p = Product.fromJson(_baseJson());
      expect(p.isManaged, isFalse);
    });

    test('isManaged: true parsed correctly', () {
      final json = _baseJson();
      json['isManaged'] = true;
      final p = Product.fromJson(json);
      expect(p.isManaged, isTrue);
    });

    test('isManaged survives toJson/fromJson round-trip', () {
      final json = _baseJson();
      json['isManaged'] = true;
      final original = Product.fromJson(json);
      final roundTripped = Product.fromJson(original.toJson());
      expect(roundTripped.isManaged, isTrue);
    });

    test('isManaged false is omitted from toJson', () {
      final p = Product.fromJson(_baseJson());
      expect(p.toJson().containsKey('isManaged'), isFalse);
    });

    test('copyWith preserves isManaged when not overridden', () {
      final json = _baseJson();
      json['isManaged'] = true;
      final p = Product.fromJson(json);
      final copy = p.copyWith(isHalal: false);
      expect(copy.isManaged, isTrue);
    });

    test('copyWith can override isManaged', () {
      final p = Product.fromJson(_baseJson());
      final updated = p.copyWith(isManaged: true);
      expect(updated.isManaged, isTrue);
    });
  });

  group('Product — Gemini web ingredient lookup dedupe flag', () {
    test('explicit true from backend JSON', () {
      final json = _baseJson();
      json['geminiWebIngredientLookupAttemptedForName'] = true;
      final p = Product.fromJson(json);
      expect(p.geminiWebIngredientLookupAttemptedForName, isTrue);
    });

    test('computed true from lookup timestamp + name key', () {
      final json = _baseJson(name: '  My   Candy  ');
      json['geminiWebIngredientLookupAt'] = '2026-05-01T12:00:00Z';
      json['geminiWebIngredientLookupNameKey'] = 'my candy';
      final p = Product.fromJson(json);
      expect(p.geminiWebIngredientLookupAttemptedForName, isTrue);
    });

    test('computed false when name key mismatches normalized name', () {
      final json = _baseJson(name: 'Cola Zero');
      json['geminiWebIngredientLookupAt'] = '2026-05-01T12:00:00Z';
      json['geminiWebIngredientLookupNameKey'] = 'cola light';
      final p = Product.fromJson(json);
      expect(p.geminiWebIngredientLookupAttemptedForName, isFalse);
    });

    test(
      'normalizeProductNameForGeminiKey matches edge function semantics',
      () {
        expect(
          Product.normalizeProductNameForGeminiKey('  Foo   BAR  '),
          'foo bar',
        );
      },
    );

    test('survives toJson/fromJson when true', () {
      final json = _baseJson();
      json['geminiWebIngredientLookupAttemptedForName'] = true;
      final roundTripped = Product.fromJson(Product.fromJson(json).toJson());
      expect(roundTripped.geminiWebIngredientLookupAttemptedForName, isTrue);
    });
  });
}
