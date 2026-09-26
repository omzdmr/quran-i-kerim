import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_connector.dart';
import 'package:quran_i_kerim/src/data/backup/backup_cloud_store.dart';
import 'package:quran_i_kerim/src/data/backup/backup_file_service.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/features/settings/google_drive_backup_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Drive restore previews changes, merges, then undoes to exact local state', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_surah': 2,
      'last_ayah': 255,
      'theme_mode': 'dark',
    });
    final tempRoot = await Directory.systemTemp.createTemp('quran_drive_widget_');
    addTearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });
    final store = _Store(
      BackupCloudObject(
        content: jsonEncode(<String, Object?>{
          'version': 3,
          'createdAt': '2026-09-22T00:00:00Z',
          'data': <String, Object?>{
            'reading': <String, Object?>{'last_surah': 36},
            'preferences': <String, Object?>{'app_locale': 'fr'},
          },
        }),
        revision: 'r1',
        updatedAt: DateTime.parse('2026-09-22T00:00:00Z'),
      ),
    );
    var restoredCallbacks = 0;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: GoogleDriveBackupSection(
            enabledOverride: true,
            connector: _Connector(store),
            restoreSafetyService: BackupFileService(
              directoryProvider: () async => tempRoot,
            ),
            onRestored: () async => restoredCallbacks += 1,
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Connect Google Drive'));
    await tester.pumpAndSettle();
    expect(find.text('Device data and cloud backup are different.'), findsOneWidget);

    await tester.tap(find.text('Restore from Drive'));
    await tester.pumpAndSettle();
    expect(find.text('How should this backup be restored?'), findsOneWidget);
    expect(find.textContaining('Backup:'), findsOneWidget);
    expect(find.text('Merge'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Backup restored.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(restoredCallbacks, 1);

    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 36);
    expect(prefs.getInt('last_ayah'), 255, reason: 'Merge keeps device-only reading state.');
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('app_locale'), 'fr');

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('last_surah'), 2);
    expect(prefs.getInt('last_ayah'), 255);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.containsKey('app_locale'), isFalse);
    expect(restoredCallbacks, 2);
  });
}

class _Connector implements BackupCloudConnector {
  _Connector(this.store);
  final BackupCloudStore store;

  @override
  Future<BackupCloudConnection> connect({bool interactive = true}) async =>
      BackupCloudConnection(accountLabel: 'reader@example.com', store: store, close: () {});

  @override
  Future<void> signOut() async {}
}

class _Store implements BackupCloudStore {
  _Store(this.object);
  final BackupCloudObject object;

  @override
  Future<BackupCloudObject?> read() async => object;

  @override
  Future<BackupCloudObject> write({required String content, required String? expectedRevision}) =>
      throw UnimplementedError();
}