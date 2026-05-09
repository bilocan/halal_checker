import 'package:flutter_test/flutter_test.dart';
import 'package:halal_checker/models/product_analysis.dart';

const _ts = '2026-01-01T12:00:00.000Z';

Map<String, dynamic> _ingredientJson({
  String name = 'salt',
  String verdict = 'halal',
  String confidence = 'high',
  String reason = 'Mineral, no concerns',
  String islamicBasis = '',
  List<String> alternativeNames = const [],
}) => {
  'name': name,
  'verdict': verdict,
  'confidence': confidence,
  'reason': reason,
  'islamicBasis': islamicBasis,
  'alternativeNames': alternativeNames,
};

Map<String, dynamic> _analysisJson({
  String id = 'abc-123',
  String barcode = '111222333',
  String status = 'ai_done',
  Map<String, dynamic>? aiAnalysis,
  String? finalVerdict,
  String? finalVerdictReason,
}) => {
  'id': id,
  'barcode': barcode,
  'status': status,
  'ai_analysis': aiAnalysis,
  'final_verdict': finalVerdict,
  'final_verdict_reason': finalVerdictReason,
  'created_at': _ts,
  'updated_at': _ts,
};

void main() {
  // ── IngredientAnalysis ─────────────────────────────────────────────────────

  group('IngredientAnalysis.fromJson', () {
    test('parses all fields', () {
      final a = IngredientAnalysis.fromJson(
        _ingredientJson(
          name: 'gelatin',
          verdict: 'suspicious',
          confidence: 'medium',
          reason: 'May be pork-derived',
          islamicBasis: 'Scholars differ on istihala transformation',
          alternativeNames: ['E441', 'gelatine'],
        ),
      );

      expect(a.name, 'gelatin');
      expect(a.verdict, 'suspicious');
      expect(a.confidence, 'medium');
      expect(a.reason, 'May be pork-derived');
      expect(a.islamicBasis, 'Scholars differ on istihala transformation');
      expect(a.alternativeNames, ['E441', 'gelatine']);
    });

    test('falls back to safe defaults for missing fields', () {
      final a = IngredientAnalysis.fromJson({});

      expect(a.name, '');
      expect(a.verdict, 'unknown');
      expect(a.confidence, 'low');
      expect(a.reason, '');
      expect(a.islamicBasis, '');
      expect(a.alternativeNames, isEmpty);
    });

    test('accepts each valid verdict value', () {
      for (final v in ['halal', 'haram', 'suspicious', 'unknown']) {
        final a = IngredientAnalysis.fromJson(_ingredientJson(verdict: v));
        expect(a.verdict, v);
      }
    });

    test('accepts each valid confidence value', () {
      for (final c in ['high', 'medium', 'low']) {
        final a = IngredientAnalysis.fromJson(_ingredientJson(confidence: c));
        expect(a.confidence, c);
      }
    });

    test('handles empty alternativeNames list', () {
      final a = IngredientAnalysis.fromJson(
        _ingredientJson(alternativeNames: []),
      );
      expect(a.alternativeNames, isEmpty);
    });

    test('preserves multiple alternative names', () {
      final a = IngredientAnalysis.fromJson(
        _ingredientJson(alternativeNames: ['E471', 'mono-glycerides', 'MG']),
      );
      expect(a.alternativeNames, ['E471', 'mono-glycerides', 'MG']);
    });
  });

  // ── DeepAnalysisResult ─────────────────────────────────────────────────────

  group('DeepAnalysisResult.fromJson', () {
    test('parses summary and ingredient list', () {
      final r = DeepAnalysisResult.fromJson({
        'summary': 'Product appears halal with one suspicious ingredient.',
        'ingredients': [
          _ingredientJson(name: 'sugar', verdict: 'halal'),
          _ingredientJson(
            name: 'gelatin',
            verdict: 'suspicious',
            confidence: 'medium',
          ),
        ],
      });

      expect(
        r.summary,
        'Product appears halal with one suspicious ingredient.',
      );
      expect(r.ingredients.length, 2);
      expect(r.ingredients[0].name, 'sugar');
      expect(r.ingredients[0].verdict, 'halal');
      expect(r.ingredients[1].name, 'gelatin');
      expect(r.ingredients[1].verdict, 'suspicious');
    });

    test('handles missing summary and ingredients', () {
      final r = DeepAnalysisResult.fromJson({});
      expect(r.summary, '');
      expect(r.ingredients, isEmpty);
    });

    test('handles empty ingredients list', () {
      final r = DeepAnalysisResult.fromJson({
        'summary': 'No ingredients analysed.',
        'ingredients': [],
      });
      expect(r.ingredients, isEmpty);
    });

    test('preserves ingredient order', () {
      final names = ['water', 'salt', 'sugar', 'gelatin', 'carmine'];
      final r = DeepAnalysisResult.fromJson({
        'summary': '',
        'ingredients': names.map((n) => _ingredientJson(name: n)).toList(),
      });
      expect(r.ingredients.map((i) => i.name).toList(), names);
    });
  });

  // ── AnalysisStatus ─────────────────────────────────────────────────────────

  group('AnalysisStatus.fromString', () {
    test('maps every known status string to its enum value', () {
      expect(AnalysisStatus.fromString('pending'), AnalysisStatus.pending);
      expect(
        AnalysisStatus.fromString('ai_analyzing'),
        AnalysisStatus.aiAnalyzing,
      );
      expect(AnalysisStatus.fromString('ai_done'), AnalysisStatus.aiDone);
      expect(
        AnalysisStatus.fromString('community_review'),
        AnalysisStatus.communityReview,
      );
      expect(
        AnalysisStatus.fromString('consulting'),
        AnalysisStatus.consulting,
      );
      expect(AnalysisStatus.fromString('resolved'), AnalysisStatus.resolved);
    });

    test('falls back to pending for unknown strings', () {
      expect(AnalysisStatus.fromString(''), AnalysisStatus.pending);
      expect(AnalysisStatus.fromString('not_a_status'), AnalysisStatus.pending);
    });
  });

  group('AnalysisStatus.label', () {
    test('every status has a non-empty label', () {
      for (final s in AnalysisStatus.values) {
        expect(s.label, isNotEmpty, reason: 'Status $s has an empty label');
      }
    });

    test('all labels are distinct', () {
      final labels = AnalysisStatus.values.map((s) => s.label).toList();
      expect(
        labels.toSet().length,
        labels.length,
        reason: 'Duplicate labels found: $labels',
      );
    });
  });

  // ── ProductAnalysis ────────────────────────────────────────────────────────

  group('ProductAnalysis.fromJson', () {
    test('parses a full ai_done record with ai_analysis', () {
      final a = ProductAnalysis.fromJson(
        _analysisJson(
          status: 'ai_done',
          aiAnalysis: {
            'summary': 'One suspicious ingredient found.',
            'ingredients': [
              _ingredientJson(name: 'gelatin', verdict: 'suspicious'),
            ],
          },
        ),
      );

      expect(a.id, 'abc-123');
      expect(a.barcode, '111222333');
      expect(a.status, AnalysisStatus.aiDone);
      expect(a.aiAnalysis, isNotNull);
      expect(a.aiAnalysis!.summary, 'One suspicious ingredient found.');
      expect(a.aiAnalysis!.ingredients.length, 1);
      expect(a.aiAnalysis!.ingredients[0].name, 'gelatin');
      expect(a.finalVerdict, isNull);
      expect(a.finalVerdictReason, isNull);
      expect(a.createdAt, DateTime.parse(_ts));
      expect(a.updatedAt, DateTime.parse(_ts));
    });

    test('parses a pending record without ai_analysis', () {
      final a = ProductAnalysis.fromJson(_analysisJson(status: 'pending'));

      expect(a.status, AnalysisStatus.pending);
      expect(a.aiAnalysis, isNull);
    });

    test('parses a resolved record with final_verdict', () {
      final a = ProductAnalysis.fromJson(
        _analysisJson(
          status: 'resolved',
          finalVerdict: 'halal',
          finalVerdictReason: 'All ingredients confirmed permissible.',
        ),
      );

      expect(a.status, AnalysisStatus.resolved);
      expect(a.finalVerdict, 'halal');
      expect(a.finalVerdictReason, 'All ingredients confirmed permissible.');
    });

    test('maps every pipeline status correctly via fromJson', () {
      final statusStrings = [
        'pending',
        'ai_analyzing',
        'ai_done',
        'community_review',
        'consulting',
        'resolved',
      ];
      for (final s in statusStrings) {
        final a = ProductAnalysis.fromJson(_analysisJson(status: s));
        expect(
          a.status,
          AnalysisStatus.fromString(s),
          reason: 'Mismatch for status "$s"',
        );
      }
    });
  });
}
