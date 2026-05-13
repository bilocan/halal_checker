import 'package:flutter_test/flutter_test.dart';

import 'package:halal_checker/models/feedback.dart';

void main() {
  group('FeedbackItem.toJson', () {
    test('serializes all fields', () {
      final now = DateTime(2026, 1, 15, 10, 30);
      final replied = DateTime(2026, 1, 16, 12, 0);
      final item = FeedbackItem(
        id: 'fb-1',
        barcode: '123456',
        userFeedback: 'Great product',
        submittedAt: now,
        producerReply: 'Thank you',
        repliedAt: replied,
        attachments: ['photo1.jpg', 'photo2.jpg'],
      );

      final json = item.toJson();
      expect(json['id'], 'fb-1');
      expect(json['barcode'], '123456');
      expect(json['userFeedback'], 'Great product');
      expect(json['submittedAt'], now.toIso8601String());
      expect(json['producerReply'], 'Thank you');
      expect(json['repliedAt'], replied.toIso8601String());
      expect(json['attachments'], ['photo1.jpg', 'photo2.jpg']);
    });

    test('serializes null optional fields', () {
      final item = FeedbackItem(
        id: 'fb-2',
        barcode: '789012',
        userFeedback: 'Needs improvement',
        submittedAt: DateTime(2026, 2, 1),
      );

      final json = item.toJson();
      expect(json['producerReply'], isNull);
      expect(json['repliedAt'], isNull);
      expect(json['attachments'], isEmpty);
    });
  });

  group('FeedbackItem.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'fb-3',
        'barcode': '111222',
        'userFeedback': 'Check this',
        'submittedAt': '2026-03-01T08:00:00.000',
        'producerReply': 'Will do',
        'repliedAt': '2026-03-02T09:00:00.000',
        'attachments': ['doc.pdf'],
      };

      final item = FeedbackItem.fromJson(json);
      expect(item.id, 'fb-3');
      expect(item.barcode, '111222');
      expect(item.userFeedback, 'Check this');
      expect(item.submittedAt.year, 2026);
      expect(item.producerReply, 'Will do');
      expect(item.repliedAt, isNotNull);
      expect(item.attachments, ['doc.pdf']);
    });

    test('handles missing submittedAt gracefully', () {
      final json = {'id': 'fb-4', 'barcode': '333444', 'userFeedback': 'Test'};

      final item = FeedbackItem.fromJson(json);
      expect(item.submittedAt, isNotNull);
    });

    test('handles null repliedAt', () {
      final json = {
        'id': 'fb-5',
        'barcode': '555666',
        'userFeedback': 'No reply',
        'submittedAt': '2026-01-01T00:00:00.000',
        'repliedAt': null,
      };

      final item = FeedbackItem.fromJson(json);
      expect(item.repliedAt, isNull);
    });

    test('handles missing attachments', () {
      final json = {
        'id': 'fb-6',
        'barcode': '777888',
        'userFeedback': 'No attachments',
        'submittedAt': '2026-01-01T00:00:00.000',
      };

      final item = FeedbackItem.fromJson(json);
      expect(item.attachments, isEmpty);
    });
  });

  group('FeedbackItem round-trip', () {
    test('toJson → fromJson preserves data', () {
      final original = FeedbackItem(
        id: 'rt-1',
        barcode: '999000',
        userFeedback: 'Round trip test',
        submittedAt: DateTime(2026, 6, 15, 14, 30),
        producerReply: 'Acknowledged',
        repliedAt: DateTime(2026, 6, 16, 10, 0),
        attachments: ['file1.png'],
      );

      final restored = FeedbackItem.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.barcode, original.barcode);
      expect(restored.userFeedback, original.userFeedback);
      expect(restored.producerReply, original.producerReply);
      expect(restored.attachments, original.attachments);
    });
  });
}
