import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:halal_checker/services/feedback_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FeedbackService.getFeedbacksForBarcode', () {
    test('returns empty list when no feedback exists', () async {
      final result = await FeedbackService().getFeedbacksForBarcode(
        '0000000000',
      );
      expect(result, isEmpty);
    });

    test('filters results by barcode', () async {
      final service = FeedbackService();
      await service.addFeedback('barcode_a', 'Feedback for A');
      await service.addFeedback('barcode_b', 'Feedback for B');

      final result = await service.getFeedbacksForBarcode('barcode_a');
      expect(result.length, equals(1));
      expect(result.first.barcode, equals('barcode_a'));
      expect(result.first.userFeedback, equals('Feedback for A'));
    });

    test('sorts results by submittedAt descending', () async {
      final service = FeedbackService();
      await service.addFeedback('sort_bc', 'Older');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await service.addFeedback('sort_bc', 'Newer');

      final result = await service.getFeedbacksForBarcode('sort_bc');
      expect(result.first.userFeedback, equals('Newer'));
      expect(result.last.userFeedback, equals('Older'));
    });
  });

  group('FeedbackService.addFeedback', () {
    test('creates feedback with auto-incrementing IDs', () async {
      final service = FeedbackService();
      await service.addFeedback('bc', 'First');
      await service.addFeedback('bc', 'Second');

      final result = await service.getFeedbacksForBarcode('bc');
      final ids = result.map((f) => f.id).toSet();
      expect(ids, containsAll(['1', '2']));
    });

    test('stores attachments when provided', () async {
      final service = FeedbackService();
      await service.addFeedback(
        'att_bc',
        'With file',
        attachments: ['/img/photo.jpg'],
      );
      final result = await service.getFeedbacksForBarcode('att_bc');
      expect(result.first.attachments, contains('/img/photo.jpg'));
    });

    test('stores empty attachments list by default', () async {
      final service = FeedbackService();
      await service.addFeedback('no_att_bc', 'No files');
      final result = await service.getFeedbacksForBarcode('no_att_bc');
      expect(result.first.attachments, isEmpty);
    });

    test('persists barcode and userFeedback fields', () async {
      final service = FeedbackService();
      await service.addFeedback('persist_bc', 'My detailed feedback text');
      final result = await service.getFeedbacksForBarcode('persist_bc');
      expect(result.first.barcode, equals('persist_bc'));
      expect(result.first.userFeedback, equals('My detailed feedback text'));
      expect(result.first.submittedAt, isNotNull);
    });
  });

  group('FeedbackService.addProducerReply', () {
    test('sets producerReply and repliedAt on matching feedback', () async {
      final service = FeedbackService();
      await service.addFeedback('reply_bc', 'Question');
      final feedbacks = await service.getFeedbacksForBarcode('reply_bc');
      final id = feedbacks.first.id;

      await service.addProducerReply(id, 'Producer answer');

      final updated = await service.getFeedbacksForBarcode('reply_bc');
      expect(updated.first.producerReply, equals('Producer answer'));
      expect(updated.first.repliedAt, isNotNull);
    });

    test('does not affect other feedback items', () async {
      final service = FeedbackService();
      await service.addFeedback('multi_bc', 'Feedback 1');
      await service.addFeedback('multi_bc', 'Feedback 2');
      final feedbacks = await service.getFeedbacksForBarcode('multi_bc');
      // feedbacks sorted desc, so last = oldest = id '1'
      final firstId = feedbacks.last.id;

      await service.addProducerReply(firstId, 'Reply to first only');

      final updated = await service.getFeedbacksForBarcode('multi_bc');
      final withReply = updated.where((f) => f.producerReply != null);
      expect(withReply.length, equals(1));
      expect(withReply.first.id, equals(firstId));
    });

    test('no-ops when feedbackId does not match any entry', () async {
      final service = FeedbackService();
      await service.addFeedback('noop_bc', 'Some feedback');
      await expectLater(
        service.addProducerReply('999', 'ghost reply'),
        completes,
      );
      final result = await service.getFeedbacksForBarcode('noop_bc');
      expect(result.first.producerReply, isNull);
    });
  });

  group('FeedbackService.addAttachment', () {
    test('appends attachment paths to matching feedback', () async {
      final service = FeedbackService();
      await service.addFeedback('attach_bc', 'With attachments');
      final feedbacks = await service.getFeedbacksForBarcode('attach_bc');
      final id = feedbacks.first.id;

      await service.addAttachment(id, '/path/img1.jpg');
      await service.addAttachment(id, '/path/img2.png');

      final updated = await service.getFeedbacksForBarcode('attach_bc');
      expect(
        updated.first.attachments,
        containsAll(['/path/img1.jpg', '/path/img2.png']),
      );
    });

    test('does not affect other feedback items', () async {
      final service = FeedbackService();
      await service.addFeedback('two_bc', 'First');
      await service.addFeedback('two_bc', 'Second');
      final feedbacks = await service.getFeedbacksForBarcode('two_bc');
      final firstId = feedbacks.last.id;

      await service.addAttachment(firstId, '/only_for_first.jpg');

      final updated = await service.getFeedbacksForBarcode('two_bc');
      final withAttachment = updated.where((f) => f.attachments.isNotEmpty);
      expect(withAttachment.length, equals(1));
      expect(withAttachment.first.id, equals(firstId));
    });
  });
}
