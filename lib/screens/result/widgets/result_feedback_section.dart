import 'package:flutter/material.dart';

import '../../../app_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/feedback.dart';
import '../format_relative_date.dart';

class ResultFeedbackSection extends StatelessWidget {
  const ResultFeedbackSection({
    super.key,
    required this.loc,
    required this.feedbacks,
    required this.isLoading,
    required this.onProducerReply,
  });

  final AppLocalizations loc;
  final List<FeedbackItem> feedbacks;
  final bool isLoading;
  final void Function(String feedbackId) onProducerReply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            loc.communityFeedback,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (feedbacks.isEmpty)
          Text(loc.noFeedbackYet, style: const TextStyle(color: Colors.grey))
        else
          ...feedbacks.map(
            (feedback) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          loc.userFeedback,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatRelativeDate(feedback.submittedAt, loc),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(feedback.userFeedback),
                    if (feedback.attachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: feedback.attachments
                            .map(
                              (attachment) => Chip(
                                label: Text(
                                  '📎 ${attachment.split(RegExp(r'[/\\]')).last}',
                                ),
                                backgroundColor: Colors.blue.shade50,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (feedback.producerReply != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kGreenSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kGreenLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.business,
                                  size: 16,
                                  color: kGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  loc.producerReply,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: kGreenMid,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  feedback.repliedAt != null
                                      ? formatRelativeDate(
                                          feedback.repliedAt!,
                                          loc,
                                        )
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(feedback.producerReply!),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => onProducerReply(feedback.id),
                          icon: const Icon(Icons.reply, size: 16),
                          label: Text(loc.replyAsProducer),
                          style: TextButton.styleFrom(
                            foregroundColor: kGreenMid,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
