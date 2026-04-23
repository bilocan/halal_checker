import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class HalalAnalysis {
  final bool isHalal;
  final List<String> haramIngredients;
  final List<String> suspiciousIngredients;
  final Map<String, String> ingredientWarnings;
  final String explanation;

  HalalAnalysis({
    required this.isHalal,
    required this.haramIngredients,
    required this.suspiciousIngredients,
    required this.ingredientWarnings,
    required this.explanation,
  });
}

class ClaudeService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-haiku-4-5';

  static const String _systemPrompt =
      'You are an expert in Islamic dietary laws (halal). Analyze ingredient lists '
      'and determine if a product is halal.\n\n'
      'Respond with a raw JSON object only — no markdown, no prose outside the JSON:\n'
      '{\n'
      '  "isHalal": boolean,\n'
      '  "haramIngredients": ["ingredient names that are definitively haram"],\n'
      '  "suspiciousIngredients": ["ingredient names that may be non-halal"],\n'
      '  "ingredientWarnings": {"ingredient name": "reason why haram or suspicious"},\n'
      '  "explanation": "2-3 sentence plain-language summary of the verdict and the key reasons"\n'
      '}\n\n'
      'Haram: pork and derivatives (lard, bacon, ham, pepperoni, salami, chorizo, '
      'prosciutto, pork gelatin), alcohol (ethanol, wine, beer), blood, carnivorous '
      'animals, insects (carmine, cochineal, E120).\n\n'
      'Suspicious: gelatin (source unspecified), L-cysteine (E920), mono- and '
      'diglycerides (E471), rennet (non-microbial), enzymes (source unspecified), '
      'natural flavors (source unspecified), emulsifiers that may be animal-derived.\n\n'
      'If the ingredients list is empty, respond with isHalal true, empty arrays, '
      'and explanation "No ingredient data available to analyze."';

  bool get isAvailable => AppConfig.anthropicApiKey.isNotEmpty;

  Future<HalalAnalysis?> analyzeIngredients(List<String> ingredients) async {
    if (!isAvailable) return null;

    if (ingredients.isEmpty) {
      return HalalAnalysis(
        isHalal: true,
        haramIngredients: [],
        suspiciousIngredients: [],
        ingredientWarnings: {},
        explanation: 'No ingredient data available to analyze.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': AppConfig.anthropicApiKey,
              'anthropic-version': '2023-06-01',
              'anthropic-beta': 'prompt-caching-2024-07-31',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 1024,
              'system': [
                {
                  'type': 'text',
                  'text': _systemPrompt,
                  'cache_control': {'type': 'ephemeral'},
                }
              ],
              'messages': [
                {
                  'role': 'user',
                  'content':
                      'Analyze these ingredients:\n${ingredients.join(', ')}',
                }
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final contentList = data['content'] as List;
        final text = contentList
            .firstWhere((c) => (c as Map)['type'] == 'text')['text'] as String;

        final parsed = jsonDecode(text.trim()) as Map<String, dynamic>;
        return HalalAnalysis(
          isHalal: parsed['isHalal'] as bool? ?? true,
          haramIngredients:
              List<String>.from(parsed['haramIngredients'] as List? ?? []),
          suspiciousIngredients:
              List<String>.from(parsed['suspiciousIngredients'] as List? ?? []),
          ingredientWarnings: Map<String, String>.from(
              parsed['ingredientWarnings'] as Map? ?? {}),
          explanation: parsed['explanation'] as String? ?? '',
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
