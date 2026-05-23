import 'package:halal_checker/services/analysis_service.dart';

/// Configurable [AnalysisService] for widget tests — no Supabase calls.
class StubAnalysisService extends AnalysisService {
  StubAnalysisService({this.admin = false, this.batchImport = false})
    : super(hasSupabase: false);

  final bool admin;
  final bool batchImport;

  @override
  Future<bool> isAdmin() async => admin;

  @override
  Future<bool> hasOperation(String operationId) async {
    if (operationId == 'admin.batch_import') return batchImport;
    return false;
  }
}
