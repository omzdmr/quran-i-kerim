import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';
import 'package:quran_i_kerim/src/features/settings/backup_restore_dialog.dart';

void main() {
  testWidgets('restore preview exposes date, record count and schema version', (tester) async {
    final preview = BackupPreview(
      version: BackupPreviewParser.currentVersion,
      createdAt: DateTime(2026, 9, 21, 14, 30),
      recordCounts: const <String, int>{'notes': 5, 'bookmarks': 3},
      issues: const <BackupPreviewIssue>{},
      integrityVerified: true,
    );
    const plan = BackupImportPlan(
      incomingRecords: 8,
      localRecords: 2,
      conflictingRecords: 1,
      incomingOnlyRecords: 7,
      localOnlyRecords: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(body: BackupRestoreDialog(preview: preview, plan: plan)),
      ),
    );

    expect(find.textContaining('Backup:'), findsOneWidget);
    expect(find.textContaining('records: 8'), findsOneWidget);
    expect(find.textContaining('version: ${BackupPreviewParser.currentVersion}'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Backup:.*records: 8.*version:')), findsOneWidget);
  });

  test('all product locales provide explicit backup identity labels', () {
    for (final code in const <String>['tr', 'en', 'fr', 'ar', 'az', 'ru']) {
      final copy = BackupRestoreCopy.forLocale(Locale(code));
      expect(copy.backupLabel, isNotEmpty, reason: code);
      expect(copy.recordsLabel, isNotEmpty, reason: code);
      expect(copy.versionLabel, isNotEmpty, reason: code);
    }
  });
}