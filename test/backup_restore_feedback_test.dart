import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/features/settings/backup_restore_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tempRoot = await Directory.systemTemp.createTemp('quran_restore_feedback_');
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  BackupFileService service() => BackupFileService(directoryProvider: () async => tempRoot);

  testWidgets('successful restore feedback exposes undo and restores prior state', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 2, 'last_ayah': 255});
    final fileService = service();
    final incoming = File('${tempRoot.path}${Platform.pathSeparator}incoming.json');
    await incoming.writeAsString(jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{'reading': <String, Object?>{'last_surah': 36}},
    }));
    final receipt = await fileService.restoreFile(incoming, mode: BackupRestoreMode.replace);

    late BuildContext pageContext;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      home: Scaffold(body: Builder(builder: (context) {
        pageContext = context;
        return const Text('ready');
      })),
    ));

    var refreshed = false;
    BackupRestoreFeedback.show(
      context: pageContext,
      service: fileService,
      receipt: receipt,
      afterUndo: () async => refreshed = true,
    );
    await tester.pump();
    expect(find.text('Yedek geri yüklendi.'), findsOneWidget);
    expect(find.text('Geri al'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getInt('last_ayah'), 255);
    expect(refreshed, isTrue);
    expect(find.text('Geri yükleme geri alındı. Önceki verileriniz geri geldi.'), findsOneWidget);
  });

  testWidgets('feedback is exposed as a live region for screen readers', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 2});
    final fileService = service();
    final incoming = File('${tempRoot.path}${Platform.pathSeparator}incoming.json');
    await incoming.writeAsString(jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{'reading': <String, Object?>{'last_surah': 18}},
    }));
    final receipt = await fileService.restoreFile(incoming);

    late BuildContext pageContext;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (context) {
        pageContext = context;
        return const Text('ready');
      })),
    ));
    BackupRestoreFeedback.show(context: pageContext, service: fileService, receipt: receipt);
    await tester.pump();

    final semantics = tester.getSemantics(find.text('Backup restored.'));
    expect(semantics.label, contains('Backup restored.'));
    expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
  });

  test('all product locales have explicit undo copy', () {
    for (final code in const <String>['tr', 'en', 'fr', 'ar', 'az', 'ru']) {
      final copy = BackupRestoreFeedbackCopy.forLocale(Locale(code));
      expect(copy.restored, isNotEmpty, reason: code);
      expect(copy.undo, isNotEmpty, reason: code);
      expect(copy.undone, isNotEmpty, reason: code);
      expect(copy.undoFailed, isNotEmpty, reason: code);
    }
  });
}
