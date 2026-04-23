import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feedback.dart';

class FeedbackService {
  static const String _feedbacksKey = 'feedbacks';
  static const String _nextIdKey = 'next_feedback_id';

  Future<List<FeedbackItem>> getFeedbacksForBarcode(String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbacksJson = prefs.getStringList(_feedbacksKey) ?? [];

    return feedbacksJson
        .map((json) => FeedbackItem.fromJson(jsonDecode(json)))
        .where((feedback) => feedback.barcode == barcode)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  Future<void> addFeedback(String barcode, String userFeedback, {List<String> attachments = const []}) async {
    final prefs = await SharedPreferences.getInstance();
    final nextId = prefs.getInt(_nextIdKey) ?? 1;

    final feedback = FeedbackItem(
      id: nextId.toString(),
      barcode: barcode,
      userFeedback: userFeedback,
      submittedAt: DateTime.now(),
      attachments: attachments,
    );

    final feedbacksJson = prefs.getStringList(_feedbacksKey) ?? [];
    feedbacksJson.add(jsonEncode(feedback.toJson()));

    await prefs.setStringList(_feedbacksKey, feedbacksJson);
    await prefs.setInt(_nextIdKey, nextId + 1);
  }

  Future<void> addProducerReply(String feedbackId, String reply) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbacksJson = prefs.getStringList(_feedbacksKey) ?? [];

    final updatedFeedbacks = feedbacksJson.map((json) {
      final feedback = FeedbackItem.fromJson(jsonDecode(json));
      if (feedback.id == feedbackId) {
        return jsonEncode(FeedbackItem(
          id: feedback.id,
          barcode: feedback.barcode,
          userFeedback: feedback.userFeedback,
          submittedAt: feedback.submittedAt,
          producerReply: reply,
          repliedAt: DateTime.now(),
          attachments: feedback.attachments,
        ).toJson());
      }
      return json;
    }).toList();

    await prefs.setStringList(_feedbacksKey, updatedFeedbacks);
  }

  Future<void> addAttachment(String feedbackId, String attachmentPath) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbacksJson = prefs.getStringList(_feedbacksKey) ?? [];

    final updatedFeedbacks = feedbacksJson.map((json) {
      final feedback = FeedbackItem.fromJson(jsonDecode(json));
      if (feedback.id == feedbackId) {
        final newAttachments = List<String>.from(feedback.attachments)..add(attachmentPath);
        return jsonEncode(FeedbackItem(
          id: feedback.id,
          barcode: feedback.barcode,
          userFeedback: feedback.userFeedback,
          submittedAt: feedback.submittedAt,
          producerReply: feedback.producerReply,
          repliedAt: feedback.repliedAt,
          attachments: newAttachments,
        ).toJson());
      }
      return json;
    }).toList();

    await prefs.setStringList(_feedbacksKey, updatedFeedbacks);
  }
}