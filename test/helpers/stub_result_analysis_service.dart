import 'package:halal_checker/models/product.dart';
import 'package:halal_checker/models/product_analysis.dart';
import 'package:halal_checker/services/analysis_service.dart';

/// [AnalysisService] for [ResultController] unit tests — no network.
class StubResultAnalysisService extends AnalysisService {
  StubResultAnalysisService({this.admin = false, this.analysis});

  final bool admin;
  final ProductAnalysis? analysis;

  @override
  Future<bool> isAdmin() async => admin;

  @override
  Future<ProductAnalysis?> getAnalysis(String barcode) async => analysis;

  @override
  Future<ProductAnalysis?> requestDeepAnalysis(
    String barcode, {
    Product? product,
    String? jwtOverride,
  }) async => analysis;
}
