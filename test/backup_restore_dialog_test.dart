import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_import_plan.dart';
import 'package:quran_i_kerim/src/data/backup/backup_preview.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/settings/backup_restore_dialog.dart';

void main() {
  const plan = BackupImportPlan(incomingRecords: 8, localRecords: 7, conflictingRecords: 2, incomingOnlyRecords: 3, localOnlyRecords: 2, sectionImpacts: <BackupSectionImpact>[
    BackupSectionImpact(section: 'bookmarks', incomingRecords: 2, localRecords: 4, conflictingRecords: 0, incomingOnlyRecords: 0, localOnlyRecords: 2),
    BackupSectionImpact(section: 'notes', incomingRecords: 6, localRecords: 3, conflictingRecords: 2, incomingOnlyRecords: 3, localOnlyRecords: 0),
  ]);
  final preview = BackupPreview(version: BackupPreviewParser.currentVersion, createdAt: DateTime.utc(2026, 9, 21), recordCounts: const <String, int>{'notes': 8}, issues: const <BackupPreviewIssue>{}, integrityVerified: true);

  Future<void> openDialog(WidgetTester tester, ValueSetter<BackupRestoreMode?> result) async {
    await tester.pumpWidget(MaterialApp(locale: const Locale('tr'), supportedLocales: const <Locale>[Locale('tr'), Locale('en')], localizationsDelegates: GlobalMaterialLocalizations.delegates, home: Builder(builder: (context) => Scaffold(body: FilledButton(onPressed: () async {
      result(await showDialog<BackupRestoreMode>(context: context, builder: (_) => BackupRestoreDialog(preview: preview, plan: plan)));
    }, child: const Text('open'))))));
    await tester.tap(find.text('open')); await tester.pumpAndSettle();
  }

  testWidgets('explains recovery and asks again before destructive replace', (tester) async {
    BackupRestoreMode? result; await openDialog(tester, (value) => result = value);
    expect(find.text('Çakışan: 2'), findsOneWidget); expect(find.text('Yalnız yedekte: 3'), findsOneWidget); expect(find.text('Yalnız cihazda: 2'), findsOneWidget); expect(find.text('Cihazda korunacak: 2'), findsOneWidget); expect(find.byIcon(Icons.shield_outlined), findsOneWidget); expect(find.textContaining('otomatik güvenlik kopyası'), findsOneWidget);
    await tester.tap(find.text('Değiştir')); await tester.pumpAndSettle();
    expect(find.text('Değiştir ile kaldırılacak: 2'), findsOneWidget); expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
    await tester.tap(find.text('Devam et')); await tester.pumpAndSettle();
    expect(result, isNull); expect(find.text('Cihazdaki kayıtlar kaldırılsın mı?'), findsOneWidget); expect(find.textContaining('yalnızca cihazda bulunan 2 kaydı kaldıracak'), findsOneWidget);
    await tester.tap(find.text('Değiştir').last); await tester.pumpAndSettle(); expect(result, BackupRestoreMode.replace);
  });

  testWidgets('cancel from destructive confirmation keeps restore review open', (tester) async {
    BackupRestoreMode? result; await openDialog(tester, (value) => result = value);
    await tester.tap(find.text('Değiştir')); await tester.pumpAndSettle(); await tester.tap(find.text('Devam et')); await tester.pumpAndSettle(); await tester.tap(find.byType(TextButton).last); await tester.pumpAndSettle();
    expect(result, isNull); expect(find.text('Yedeği nasıl geri yükleyelim?'), findsOneWidget); expect(find.text('Değiştir ile kaldırılacak: 2'), findsOneWidget);
  });

  testWidgets('merge remains one-step because device-only records are preserved', (tester) async {
    BackupRestoreMode? result; await openDialog(tester, (value) => result = value); await tester.tap(find.text('Devam et')); await tester.pumpAndSettle(); expect(result, BackupRestoreMode.merge); expect(find.text('Cihazdaki kayıtlar kaldırılsın mı?'), findsNothing);
  });

  testWidgets('uses English fallback for unsupported locale', (tester) async {
    await tester.pumpWidget(MaterialApp(locale: const Locale('de'), home: Scaffold(body: BackupRestoreDialog(preview: preview, plan: plan))));
    expect(find.text('How should this backup be restored?'), findsOneWidget); expect(find.text('Merge'), findsOneWidget); expect(find.text('Replace'), findsOneWidget); expect(find.text('Kept on device: 2'), findsOneWidget); expect(find.textContaining('safety copy'), findsOneWidget); expect(find.textContaining('on-screen Undo action'), findsOneWidget);
  });

  test('all product locales explain immediate undo and destructive replace', () {
    for (final code in const <String>['tr', 'en', 'fr', 'ar', 'az', 'ru']) {
      final copy = BackupRestoreCopy.forLocale(Locale(code)); expect(copy.safetyNote, isNotEmpty, reason: code); expect(copy.safetyNote.length, greaterThan(80), reason: code); expect(copy.replaceConfirmTitle, isNotEmpty, reason: code); expect(copy.replaceConfirmBody(3), contains('3'), reason: code);
    }
  });
}
