import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:halal_checker/services/ingredient_contribution_service.dart';

void main() {
  // ── no Supabase config (guard-path) ───────────────────────────────────────

  group('IngredientContributionService — no Supabase config', () {
    test('submitIngredients returns false', () async {
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water, sugar, salt',
        ),
        isFalse,
      );
    });

    test('submitIngredients with empty barcode returns false', () async {
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '',
          ingredientText: 'flour, water',
        ),
        isFalse,
      );
    });

    test('getContributions returns empty list', () async {
      expect(await IngredientContributionService.getContributions(), isEmpty);
    });

    test('getContributions with explicit status returns empty list', () async {
      expect(
        await IngredientContributionService.getContributions(
          status: 'approved',
        ),
        isEmpty,
      );
    });

    test('updateStatus returns false', () async {
      expect(
        await IngredientContributionService.updateStatus(1, 'approved'),
        isFalse,
      );
    });

    test('updateStatus rejected returns false', () async {
      expect(
        await IngredientContributionService.updateStatus(1, 'rejected'),
        isFalse,
      );
    });
  });

  // ── HTTP mock tests ───────────────────────────────────────────────────────

  group('IngredientContributionService.submitIngredients — HTTP responses', () {
    tearDown(IngredientContributionService.resetForTesting);

    test('HTTP 201 → true', () async {
      IngredientContributionService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 201)),
      );
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water, sugar, salt',
        ),
        isTrue,
      );
    });

    test('HTTP 200 (not 201) → false', () async {
      IngredientContributionService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 200)),
      );
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water, sugar',
        ),
        isFalse,
      );
    });

    test('HTTP 400 → false', () async {
      IngredientContributionService.setHttpClientForTesting(
        MockClient((_) async => http.Response('', 400)),
      );
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water',
        ),
        isFalse,
      );
    });

    test('network exception → false', () async {
      IngredientContributionService.setHttpClientForTesting(
        MockClient((_) async => throw Exception('network error')),
      );
      expect(
        await IngredientContributionService.submitIngredients(
          barcode: '111222333',
          ingredientText: 'water',
        ),
        isFalse,
      );
    });

    test('request body contains barcode and ingredient_text', () async {
      late http.Request captured;
      IngredientContributionService.setHttpClientForTesting(
        MockClient((req) async {
          captured = req;
          return http.Response('', 201);
        }),
      );
      await IngredientContributionService.submitIngredients(
        barcode: '9876543210',
        ingredientText: 'sugar, water, salt',
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['barcode'], '9876543210');
      expect(body['ingredient_text'], 'sugar, water, salt');
    });
  });
}
