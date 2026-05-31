import 'package:flutter/material.dart';

import '../../../app_colors.dart';
import '../../../localization/app_localizations.dart';

class ResultNoteCard extends StatelessWidget {
  const ResultNoteCard({
    super.key,
    required this.loc,
    required this.note,
    required this.isFlagged,
    required this.isExpanded,
    required this.noteController,
    required this.onToggleExpanded,
    required this.onToggleFlag,
    required this.onSave,
  });

  final AppLocalizations loc;
  final String note;
  final bool isFlagged;
  final bool isExpanded;
  final TextEditingController noteController;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleFlag;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final hasNote = note.isNotEmpty;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.edit_note, size: 20, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    loc.myNote,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasNote) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: kGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: onToggleFlag,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isFlagged ? Icons.bookmark : Icons.bookmark_border,
                        color: isFlagged
                            ? Colors.orange.shade700
                            : Colors.grey.shade500,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          maxLength: 300,
                          decoration: InputDecoration(
                            hintText: loc.noteHint,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(loc.submit),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
