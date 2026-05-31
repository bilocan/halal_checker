import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/product.dart';

Map<String, dynamic> _baseProductJson({
  List<String> haramLabels = const [],
  List<String> suspiciousLabels = const [],
  Map<String, String> labelWarnings = const {},
}) {
  return {
    'barcode': '1234567890',
    'name': 'Test Product',
    'ingredients': <String>['water', 'salt'],
    'isHalal': false,
    'isUnknown': false,
    'isNonFood': false,
    'haramIngredients': <String>[],
    'suspiciousIngredients': <String>[],
    'ingredientWarnings': <String, String>{},
    'labels': <String>[],
    if (haramLabels.isNotEmpty) 'haramLabels': haramLabels,
    if (suspiciousLabels.isNotEmpty) 'suspiciousLabels': suspiciousLabels,
    if (labelWarnings.isNotEmpty) 'labelWarnings': labelWarnings,
  };
}

void main() {
  group('Product.fromJson — label analysis fields', () {
    test('parses haramLabels', () {
      final p = Product.fromJson(
        _baseProductJson(haramLabels: ['pork', 'alcohol']),
      );
      expect(p.haramLabels, ['pork', 'alcohol']);
    });

    test('parses suspiciousLabels', () {
      final p = Product.fromJson(
        _baseProductJson(suspiciousLabels: ['gelatin', 'rennet']),
      );
      expect(p.suspiciousLabels, ['gelatin', 'rennet']);
    });

    test('parses labelWarnings', () {
      final p = Product.fromJson(
        _baseProductJson(
          labelWarnings: {
            'pork': 'Found on label: Contains pork or pork-derived ingredient',
          },
        ),
      );
      expect(
        p.labelWarnings['pork'],
        'Found on label: Contains pork or pork-derived ingredient',
      );
    });

    test('defaults haramLabels to [] when absent', () {
      final p = Product.fromJson(_baseProductJson());
      expect(p.haramLabels, isEmpty);
    });

    test('defaults suspiciousLabels to [] when absent', () {
      final p = Product.fromJson(_baseProductJson());
      expect(p.suspiciousLabels, isEmpty);
    });

    test('defaults labelWarnings to {} when absent', () {
      final p = Product.fromJson(_baseProductJson());
      expect(p.labelWarnings, isEmpty);
    });

    test('parses all three fields together', () {
      final p = Product.fromJson(
        _baseProductJson(
          haramLabels: ['pork'],
          suspiciousLabels: ['gelatin'],
          labelWarnings: {
            'pork': 'Found on label: Contains pork',
            'gelatin': 'Found on label: Gelatin source unclear',
          },
        ),
      );
      expect(p.haramLabels, ['pork']);
      expect(p.suspiciousLabels, ['gelatin']);
      expect(p.labelWarnings, hasLength(2));
    });
  });

  group('Product.toJson — label analysis fields', () {
    test('omits haramLabels when empty', () {
      final p = Product.fromJson(_baseProductJson());
      expect(p.toJson().containsKey('haramLabels'), isFalse);
    });

    test('omits suspiciousLabels when empty', () {
      final p = Product.fromJson(_baseProductJson());
      expect(p.toJson().containsKey('suspiciousLabels'), isFalse);
    });

    test('omits labelWarnings when empty', () {
      final p = Product.fromJson(_baseProductJson());
      expect(p.toJson().containsKey('labelWarnings'), isFalse);
    });

    test('includes haramLabels when non-empty', () {
      final p = Product.fromJson(_baseProductJson(haramLabels: ['pork']));
      expect(p.toJson()['haramLabels'], ['pork']);
    });

    test('includes suspiciousLabels when non-empty', () {
      final p = Product.fromJson(
        _baseProductJson(suspiciousLabels: ['gelatin']),
      );
      expect(p.toJson()['suspiciousLabels'], ['gelatin']);
    });

    test('includes labelWarnings when non-empty', () {
      final p = Product.fromJson(
        _baseProductJson(
          labelWarnings: {'pork': 'Found on label: Contains pork'},
        ),
      );
      expect(p.toJson()['labelWarnings'], {
        'pork': 'Found on label: Contains pork',
      });
    });
  });

  group('Product.copyWith — label analysis fields', () {
    test('copyWith overrides haramLabels', () {
      final p = Product.fromJson(_baseProductJson(haramLabels: ['pork']));
      final copy = p.copyWith(haramLabels: ['alcohol', 'wine']);
      expect(copy.haramLabels, ['alcohol', 'wine']);
      expect(p.haramLabels, ['pork']); // original unchanged
    });

    test('copyWith overrides suspiciousLabels', () {
      final p = Product.fromJson(
        _baseProductJson(suspiciousLabels: ['gelatin']),
      );
      final copy = p.copyWith(suspiciousLabels: []);
      expect(copy.suspiciousLabels, isEmpty);
    });

    test('copyWith overrides labelWarnings', () {
      final p = Product.fromJson(
        _baseProductJson(
          labelWarnings: {'pork': 'Found on label: Contains pork'},
        ),
      );
      final newWarnings = {'alcohol': 'Found on label: Contains alcohol'};
      final copy = p.copyWith(labelWarnings: newWarnings);
      expect(copy.labelWarnings, newWarnings);
    });

    test('copyWith preserves label fields when not overriding', () {
      final p = Product.fromJson(
        _baseProductJson(
          haramLabels: ['pork'],
          suspiciousLabels: ['gelatin'],
          labelWarnings: {'pork': 'Found on label: Contains pork'},
        ),
      );
      final copy = p.copyWith(isHalal: true);
      expect(copy.haramLabels, ['pork']);
      expect(copy.suspiciousLabels, ['gelatin']);
      expect(copy.labelWarnings, {'pork': 'Found on label: Contains pork'});
    });
  });
}
