import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/features/settings/backup_restore_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('stale Undo reports failure and leaves newer user data untouched', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 2});
    final tempRoot = await Directory.systemTemp.createTemp('quran_feedback_stale_');
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });
    final service = BackupFileService(directoryProvider: () async => tempRoot);
    final receipt = await service.restoreEncoded(jsonEncode(<String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-22T00:00:00Z',
      'data': <String, Object?>{
        'reading': <String, Object?>{'last_surah': 36},
      },
    }));

    late BuildContext pageContext;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      home: Scaffold(body: Builder(builder: (context) {
        pageContext = context;
        return const Text('ready');
      })),
    ));
    BackupRestoreFeedback.show(
      context: pageContext,
      service: service,
      receipt: receipt,
    );
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_surah', 18);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(prefs.getInt('last_surah'), 18);
    final failure = find.textContaining('Undo could not be completed');
    expect(failure, findsOneWidget);
    final semantics = tester.getSemantics(failure);
    expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
    expect(await receipt.safetySnapshot.exists(), isTrue);
  });
}
