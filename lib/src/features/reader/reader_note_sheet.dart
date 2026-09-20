import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

Future<void> showReaderPersonalNotePreview({
  required BuildContext context,
  required String reference,
  required String note,
  required String sourceCode,
  required Future<void> Function() onEdit,
  required VoidCallback onOpenArchive,
}) async {
  final l10n = context.l10n;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.readerPersonalNote,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$reference · $sourceCode',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                note,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onOpenArchive();
                    },
                    icon: const Icon(Icons.person_outline_rounded),
                    label: Text(l10n.readerOpenArchive),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await onEdit();
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(l10n.readerEditNote),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
