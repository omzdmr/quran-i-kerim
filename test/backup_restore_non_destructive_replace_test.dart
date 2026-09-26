import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/settings/backup_restore_dialog.dart';

void main() {
  testWidgets('replace does not add a redundant confirmation when nothing is device-only', (tester) async {
    const plan = BackupImportPlan(
      incomingRecords: 2,
      localRecords: 1,
      conflictingRecords: 1,
      incomingOnlyRecords: 1,
      localOnlyRecords: 0,
      sectionImpacts: <BackupSectionImpact>[
        BackupSectionImpact(
          section: 'notes',
          incomingRecords: 2,
          localRecords: 1,
          conflictingRecords: 1,
          incomingOnlyRecords: 1,
          localOnlyRecords: 0,
        ),
      ],
    );
    final preview = BackupPreview(
      version: BackupPreviewParser.currentVersion,
      createdAt: DateTime.utc(2026, 9, 22),
      recordCounts: const <String, int>{'notes': 2},
      issues: const <BackupPreviewIssue>{},
    );
    BackupRestoreMode? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showDialog<BackupRestoreMode>(
                context: context,
                builder: (_) => BackupRestoreDialog(preview: preview, plan: plan),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(result, BackupRestoreMode.replace);
    expect(find.text('Remove device-only records?'), findsNothing);
  });
}
