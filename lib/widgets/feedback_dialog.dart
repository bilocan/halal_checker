import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../services/feedback_service.dart';

Future<void> showFeedbackDialog({
  required BuildContext context,
  required String barcode,
  required FeedbackService feedbackService,
  required Future<void> Function() onSubmitted,
}) async {
  final loc = AppLocalizations.of(context);
  final feedbackController = TextEditingController();
  final List<String> selectedFiles = [];

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(loc.provideFeedback),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.feedbackDialogHint,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                maxLength: 500,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText: loc.feedbackInputHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                        );
                        if (result != null) {
                          setDialogState(() {
                            selectedFiles.addAll(
                              result.files
                                  .map((f) => f.path)
                                  .whereType<String>(),
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(loc.attachFiles),
                    ),
                  ),
                ],
              ),
              if (selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: selectedFiles
                      .map(
                        (file) => Chip(
                          label: Text(file.split(RegExp(r'[/\\]')).last),
                          onDeleted: () =>
                              setDialogState(() => selectedFiles.remove(file)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: feedbackController.text.trim().isEmpty
                ? null
                : () async {
                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await feedbackService.addFeedback(
                        barcode,
                        feedbackController.text.trim(),
                        attachments: selectedFiles,
                      );
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text(loc.thankYouFeedback)),
                      );
                      await onSubmitted();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(loc.couldNotSubmitFeedback)),
                      );
                    }
                  },
            child: Text(loc.submit),
          ),
        ],
      ),
    ),
  );
  feedbackController.dispose();
}
