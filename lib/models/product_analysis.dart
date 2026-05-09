class IngredientAnalysis {
  final String name;
  final String verdict; // 'halal' | 'haram' | 'suspicious' | 'unknown'
  final String confidence; // 'high' | 'medium' | 'low'
  final String reason;
  final String islamicBasis;
  final List<String> alternativeNames;

  const IngredientAnalysis({
    required this.name,
    required this.verdict,
    required this.confidence,
    required this.reason,
    required this.islamicBasis,
    required this.alternativeNames,
  });

  factory IngredientAnalysis.fromJson(Map<String, dynamic> j) =>
      IngredientAnalysis(
        name: j['name'] as String? ?? '',
        verdict: j['verdict'] as String? ?? 'unknown',
        confidence: j['confidence'] as String? ?? 'low',
        reason: j['reason'] as String? ?? '',
        islamicBasis: j['islamicBasis'] as String? ?? '',
        alternativeNames: List<String>.from(
          j['alternativeNames'] as List? ?? [],
        ),
      );
}

class DeepAnalysisResult {
  final String summary;
  final List<IngredientAnalysis> ingredients;

  const DeepAnalysisResult({required this.summary, required this.ingredients});

  factory DeepAnalysisResult.fromJson(Map<String, dynamic> j) =>
      DeepAnalysisResult(
        summary: j['summary'] as String? ?? '',
        ingredients: (j['ingredients'] as List? ?? [])
            .map((e) => IngredientAnalysis.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

enum AnalysisStatus {
  pending,
  aiAnalyzing,
  aiDone,
  communityReview,
  consulting,
  resolved;

  static AnalysisStatus fromString(String s) => switch (s) {
    'ai_analyzing' => AnalysisStatus.aiAnalyzing,
    'ai_done' => AnalysisStatus.aiDone,
    'community_review' => AnalysisStatus.communityReview,
    'consulting' => AnalysisStatus.consulting,
    'resolved' => AnalysisStatus.resolved,
    _ => AnalysisStatus.pending,
  };

  String get label => switch (this) {
    AnalysisStatus.pending => 'Queued',
    AnalysisStatus.aiAnalyzing => 'AI analysing…',
    AnalysisStatus.aiDone => 'AI done',
    AnalysisStatus.communityReview => 'Community review',
    AnalysisStatus.consulting => 'Scholar consulting',
    AnalysisStatus.resolved => 'Resolved',
  };
}

class ProductAnalysis {
  final String id;
  final String barcode;
  final AnalysisStatus status;
  final DeepAnalysisResult? aiAnalysis;
  final String? finalVerdict;
  final String? finalVerdictReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductAnalysis({
    required this.id,
    required this.barcode,
    required this.status,
    this.aiAnalysis,
    this.finalVerdict,
    this.finalVerdictReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductAnalysis.fromJson(Map<String, dynamic> j) => ProductAnalysis(
    id: j['id'] as String,
    barcode: j['barcode'] as String,
    status: AnalysisStatus.fromString(j['status'] as String? ?? 'pending'),
    aiAnalysis: j['ai_analysis'] != null
        ? DeepAnalysisResult.fromJson(j['ai_analysis'] as Map<String, dynamic>)
        : null,
    finalVerdict: j['final_verdict'] as String?,
    finalVerdictReason: j['final_verdict_reason'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );
}
