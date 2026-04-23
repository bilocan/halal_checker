class FeedbackItem {
  final String id;
  final String barcode;
  final String userFeedback;
  final DateTime submittedAt;
  final String? producerReply;
  final DateTime? repliedAt;
  final List<String> attachments; // File paths or URLs

  FeedbackItem({
    required this.id,
    required this.barcode,
    required this.userFeedback,
    required this.submittedAt,
    this.producerReply,
    this.repliedAt,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'barcode': barcode,
    'userFeedback': userFeedback,
    'submittedAt': submittedAt.toIso8601String(),
    'producerReply': producerReply,
    'repliedAt': repliedAt?.toIso8601String(),
    'attachments': attachments,
  };

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
    id: json['id'],
    barcode: json['barcode'],
    userFeedback: json['userFeedback'],
    submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? '') ?? DateTime.now(),
    producerReply: json['producerReply'],
    repliedAt: json['repliedAt'] != null ? DateTime.tryParse(json['repliedAt'].toString()) : null,
    attachments: List<String>.from(json['attachments'] ?? []),
  );
}