import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_connector.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_store.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:quran_i_kerim/src/features/settings/google_drive_backup_section.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('remote change after preview is announced and nothing is restored', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 2});
    final root = await Directory.systemTemp.createTemp('quran_drive_conflict_ui_');
    addTearDown(() async { if (await root.exists()) await root.delete(recursive: true); });
    final store = _Store(_backup('r1', 36));

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[AppLocalizations.delegate],
      home: Scaffold(body: GoogleDriveBackupSection(
        enabledOverride: true,
        connector: _Connector(store),
        restoreSafetyService: BackupFileService(directoryProvider: () async => root),
        onRestored: () async {},
      )),
    ));
    await tester.tap(find.text('Connect Google Drive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore from Drive'));
    await tester.pumpAndSettle();
    expect(find.text('How should this backup be restored?'), findsOneWidget);

    store.object = _backup('r2', 18);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    const message = 'Device data and cloud backup are different. Check again';
    final feedback = find.text(message);
    expect(feedback, findsOneWidget);
    final semantics = tester.getSemantics(feedback);
    expect(semantics.label, contains(message));
    expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(await Directory('${root.path}${Platform.pathSeparator}quran_backups').exists(), isFalse);
  });
}

BackupCloudObject _backup(String revision, int surah) => BackupCloudObject(
  content: jsonEncode(<String, Object?>{
    'version': 3,
    'createdAt': '2026-09-22T00:00:00Z',
    'data': <String, Object?>{'reading': <String, Object?>{'last_surah': surah}},
  }),
  revision: revision,
  updatedAt: DateTime.parse('2026-09-22T00:00:00Z'),
);
class _Connector implements BackupCloudConnector {
  _Connector(this.store); final BackupCloudStore store;
  @override Future<BackupCloudConnection> connect({bool interactive = true}) async => BackupCloudConnection(accountLabel: 'test', store: store, close: () {});
  @override Future<void> signOut() async {}
}
class _Store implements BackupCloudStore {
  _Store(this.object); BackupCloudObject object;
  @override Future<BackupCloudObject?> read() async => object;
  @override Future<BackupCloudObject> write({required String content, required String? expectedRevision}) => throw UnimplementedError();
}
