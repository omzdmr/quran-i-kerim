import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/settings/backup_restore_dialog.dart';

void main() {
  const plan = BackupImportPlan(
    incomingRecords: 8,
    localRecords: 7,
    conflictingRecords: 2,
    incomingOnlyRecords: 3,
    localOnlyRecords: 2,
  );

  const preview = BackupPreview(
    version: 1,
    createdAt: null,
    totalRecords: 8,
    canRestore: true,
  );

  testWidgets('defaults to merge and returns selected restore mode', (tester) async {
    BackupRestoreMode? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showDialog<BackupRestoreMode>(
                  context: context,
                  builder: (_) => const BackupRestoreDialog(
                    preview: preview,
                    plan: plan,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Çakışan: 2'), findsOneWidget);
    expect(find.text('Yalnız yedekte: 3'), findsOneWidget);
    expect(find.text('Yalnız cihazda: 2'), findsOneWidget);
    expect(
      tester.widget<RadioListTile<BackupRestoreMode>>(
        find.widgetWithText(RadioListTile<BackupRestoreMode>, 'Birleştir'),
      ).groupValue,
      BackupRestoreMode.merge,
    );

    await tester.tap(find.text('Değiştir'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(result, BackupRestoreMode.replace);
  });

  testWidgets('uses English fallback for unsupported locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        home: Scaffold(body: BackupRestoreDialog(preview: preview, plan: plan)),
      ),
    );

    expect(find.text('How should this backup be restored?'), findsOneWidget);
    expect(find.text('Merge'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
  });
}
