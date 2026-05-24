// Manual integration test: full OCR → Sanitize → Analyze pipeline on device.
//
// Tagged @manual — skipped by default. Run explicitly:
//   flutter test integration_test/ocr_pipeline_test.dart
//
// Requirements:
//   - Android or iOS device / emulator (ML Kit does not run in the Dart VM)
//   - Test image placed at: test/assets/soletti_ingredients.jpg
//
// To add a new product image, see TESTING.md (OCR testing).

// @Tags(['manual'])

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:halal_checker/services/ingredient_sanitizer.dart';
import 'package:halal_checker/services/ocr_service.dart';
import 'package:halal_checker/services/product_service.dart';

// ---------------------------------------------------------------------------
// Expected ingredients from the Soletti Salzgebäckmischung label.
//
// Each record is (de, en): a German and English form of the same ingredient.
// The test passes if EITHER substring is found (case-insensitive) in the
// sanitised output. This tolerates OCR favouring one language section over
// the other depending on image angle, contrast, or font size.
//
// For sub-ingredients inside (…): both DE and EN forms live inside their
// parent token, so `'natriumhydroxid'` is found inside
// "Säureregulator (Natriumhydroxid)" even when the EN form is not read.
// ---------------------------------------------------------------------------
const _expectedIngredients = <(String, String)>[
  ('weizenmehl', 'wheat flour'),
  ('rapsöl', 'rapeseed oil'),
  ('zucker', 'sugar'),
  ('salz', 'salt'),
  // Raising agents — parent token must contain sub-ingredients (structural
  // tests below check the (…) is preserved as one token)
  ('backtriebmittel', 'raising agents'),
  ('ammoniumhydrogencarbonat', 'ammonium hydrogen carbonate'),
  ('natriumhydrogencarbonat', 'sodium hydrogen carbonate'),
  ('dinatriumdiphosphat', 'disodium diphosphate'),
  ('mohn', 'poppy seeds'),
  ('sesam', 'sesame'),
  ('glukosesirup', 'glucose syrup'),
  ('weizenmalz', 'wheat malt'),
  ('käsepulver', 'cheese powder'),
  ('buttermilchpulver', 'buttermilk powder'),
  ('hefe', 'yeast'),
  ('roggenmehl', 'rye flour'),
  ('molkenpulver', 'whey powder'), // flagged suspicious (whey)
  ('fructose', 'fructose'),
  (
    'natürliches aroma',
    'natural flavouring',
  ), // flagged suspicious (flavouring)
  ('maltodextrin', 'maltodextrin'),
  // Acidity regulator with sub-ingredient
  ('säureregulator', 'acidity regulator'),
  ('natriumhydroxid', 'sodium hydroxide'),
  // Acidifying agent with sub-ingredient
  ('säuerungsmittel', 'acetic acid'), // EN: "acid (acetic acid)"
  ('essigsäure', 'acetic acid'),
  ('pfeffer', 'ground pepper'),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('OCR → Sanitize → Analyze — Soletti ingredients label', () {
    File? imageFile;
    String? rawOcrText;
    List<String> ingredients = const [];

    setUpAll(() async {
      // Load the bundled test image into a temp file for OcrService.
      final data = await rootBundle.load(
        'test/assets/soletti_ingredients.jpeg',
      );
      final dir = await getTemporaryDirectory();
      imageFile = File('${dir.path}/soletti_ocr_test.jpg');
      await imageFile!.writeAsBytes(data.buffer.asUint8List());

      // Step 1 — OCR (on-device ML Kit)
      rawOcrText = await OcrService.extractIngredientsFromFile(imageFile!);

      // Step 2 — Sanitize
      ingredients = rawOcrText != null
          ? IngredientSanitizer.sanitize(rawOcrText!)
          : [];
    });

    tearDownAll(() async {
      await imageFile?.delete().catchError((_) => imageFile!);
    });

    // ── OCR ─────────────────────────────────────────────────────────────────

    test('OCR produces non-empty text', () {
      expect(rawOcrText, isNotNull);
      expect(
        rawOcrText!.length,
        greaterThan(100),
        reason:
            'Expected at least 100 chars from a multilingual ingredients label',
      );
    });

    // ── Expected ingredients present after sanitisation ──────────────────────

    for (final (de, en) in _expectedIngredients) {
      test('sanitized output contains "$de" (DE) or "$en" (EN)', () {
        final lower = ingredients.map((e) => e.toLowerCase()).toList();
        expect(
          lower.any((e) => e.contains(de) || e.contains(en)),
          isTrue,
          reason:
              '"$de" (DE) / "$en" (EN) not found in sanitized list.\n'
              'Sanitized (${ingredients.length} entries):\n'
              '  ${ingredients.join('\n  ')}',
        );
      });
    }

    // ── Sanitizer structure ──────────────────────────────────────────────────

    test('no section labels remain after sanitisation', () {
      final lower = ingredients.map((e) => e.toLowerCase()).toList();
      expect(lower.any((e) => e.startsWith('ingredients')), isFalse);
      expect(lower.any((e) => e.startsWith('zutaten')), isFalse);
      expect(lower.any((e) => e.startsWith('salzgebäckmischung')), isFalse);
      expect(
        ingredients.any((e) => RegExp(r'^[A-Z]{1,3}$').hasMatch(e.trim())),
        isFalse,
        reason: 'Bare language codes like GB, A, D must be removed',
      );
    });

    test('raising agents kept as single token with sub-ingredients', () {
      final entry = ingredients.firstWhere(
        (e) => e.toLowerCase().contains('raising agents') && e.contains('('),
        orElse: () => '',
      );
      expect(entry, isNotEmpty, reason: 'raising agents (…) must be one token');
      expect(
        entry.toLowerCase().contains('ammonium hydrogen carbonate'),
        isTrue,
        reason: 'Sub-ingredients must remain inside the parent token',
      );
    });

    test('Backtriebmittel kept as single token with sub-ingredients', () {
      final entry = ingredients.firstWhere(
        (e) => e.toLowerCase().contains('backtriebmittel') && e.contains('('),
        orElse: () => '',
      );
      expect(
        entry,
        isNotEmpty,
        reason: 'Backtriebmittel (…) must be one token',
      );
      expect(entry.toLowerCase().contains('ammoniumhydrogencarbonat'), isTrue);
    });

    // ── Analysis ────────────────────────────────────────────────────────────

    test('analysis: product is halal (no haram ingredients)', () {
      final result = ProductService.analyzeWithKeywords(ingredients);
      expect(result.isHalal, isTrue);
      expect(result.haram, isEmpty);
    });

    test('analysis: flags whey / Molkenpulver as suspicious', () {
      final result = ProductService.analyzeWithKeywords(ingredients);
      final lower = result.suspicious.map((s) => s.toLowerCase()).toList();
      expect(
        lower.any((s) => s.contains('whey') || s.contains('molke')),
        isTrue,
        reason: 'WHEY POWDER and/or MOLKENPULVER must be flagged suspicious',
      );
    });

    test('analysis: flags natural flavouring / Aroma as suspicious', () {
      final result = ProductService.analyzeWithKeywords(ingredients);
      final lower = result.suspicious.map((s) => s.toLowerCase()).toList();
      expect(
        lower.any((s) => s.contains('flavour') || s.contains('aroma')),
        isTrue,
        reason: 'natural flavouring and/or natürliches Aroma must be flagged',
      );
    });
  });
}
