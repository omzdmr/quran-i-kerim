import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/settings/backup_restore_dialog.dart';

void main() {
  const plan = BackupImportPlan(incomingRecords: 8, localRecords: 7, conflictingRecords: 2, incomingOnlyRecords: 3, localOnlyRecords: 2);
  final preview = BackupPreview(version: BackupPreviewParser.currentVersion, createdAt: DateTime.utc(2026, 9, 21), recordCounts: const <String, int>{'notes': 8}, issues: const <BackupPreviewIssue>{}, integrityVerified: true);

  testWidgets('explains recovery, defaults to merge and returns selected mode', (tester) async {
    BackupRestoreMode? result;
    await tester.pumpWidget(MaterialApp(locale: const Locale('tr'), home: Builder(builder: (context) => Scaffold(body: FilledButton(onPressed: () async {
      result = await showDialog<BackupRestoreMode>(context: context, builder: (_) => BackupRestoreDialog(preview: preview, plan: plan));
    }, child: const Text('open'))))));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Çakışan: 2'), findsOneWidget);
    expect(find.text('Yalnız yedekte: 3'), findsOneWidget);
    expect(find.text('Yalnız cihazda: 2'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(find.textContaining('otomatik güvenlik kopyası'), findsOneWidget);
    expect(find.textContaining('Geri al düğmesiyle'), findsOneWidget);

    await tester.tap(find.text('Değiştir'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(result, BackupRestoreMode.replace);
  });

  testWidgets('uses English fallback for unsupported locale', (tester) async {
    await tester.pumpWidget(MaterialApp(locale: const Locale('de'), home: Scaffold(body: BackupRestoreDialog(preview: preview, plan: plan))));
    expect(find.text('How should this backup be restored?'), findsOneWidget);
    expect(find.text('Merge'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
    expect(find.textContaining('safety copy'), findsOneWidget);
    expect(find.textContaining('on-screen Undo action'), findsOneWidget);
  });

  test('all product locales explain immediate undo without losing safety-copy wording', () {
    for (final code in const <String>['tr', 'en', 'fr', 'ar', 'az', 'ru']) {
      final copy = BackupRestoreCopy.forLocale(Locale(code));
      expect(copy.safetyNote, isNotEmpty, reason: code);
      expect(copy.safetyNote.length, greaterThan(80), reason: code);
    }
  });
}