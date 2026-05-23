import 'package:halal_checker/models/feedback.dart';
import 'package:halal_checker/services/feedback_service.dart';

/// [FeedbackService] that returns fixed data for [ResultController] tests.
class StubFeedbackService extends FeedbackService {
  StubFeedbackService({this.items = const [], this.failOnLoad = false});

  final List<FeedbackItem> items;
  final bool failOnLoad;

  @override
  Future<List<FeedbackItem>> getFeedbacksForBarcode(String barcode) async {
    if (failOnLoad) throw StateError('feedback load failed');
    return items.where((f) => f.barcode == barcode).toList();
  }
}
