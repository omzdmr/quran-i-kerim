import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = LocalBackupService();
  setUp(() { SharedPreferences.setMockInitialValues(<String, Object>{}); });

  test('merge keeps local keys absent from import and applies imported keys', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 9, 'last_ayah': 4, 'theme_mode': 'dark', 'unrelated': 'never managed by backup'});
    await service.restoreDecoded(<String, Object?>{'version': BackupManifest.schemaVersion, 'createdAt': '2026-09-21T14:00:00Z', 'data': <String, Object?>{'reading': <String, Object?>{'last_surah': 36}, 'preferences': <String, Object?>{}}}, mode: BackupRestoreMode.merge);
    final prefs = await SharedPreferences.getInstance(); expect(prefs.getInt('last_surah'), 36); expect(prefs.getInt('last_ayah'), 4); expect(prefs.getString('theme_mode'), 'dark'); expect(prefs.getString('unrelated'), 'never managed by backup');
  });

  test('replace removes managed keys that are absent from import', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{'last_surah': 9, 'last_ayah': 4, 'theme_mode': 'dark', 'unrelated': 'never managed by backup'});
    await service.restoreDecoded(<String, Object?>{'version': BackupManifest.schemaVersion, 'createdAt': '2026-09-21T14:00:00Z', 'data': <String, Object?>{'reading': <String, Object?>{'last_surah': 36}, 'preferences': <String, Object?>{}}}, mode: BackupRestoreMode.replace);
    final prefs = await SharedPreferences.getInstance(); expect(prefs.getInt('last_surah'), 36); expect(prefs.containsKey('last_ayah'), isFalse); expect(prefs.containsKey('theme_mode'), isFalse); expect(prefs.getString('unrelated'), 'never managed by backup');
  });

  test('qada merge keeps local history and adds remote-only events', () async {
    final local = QadaFastingLedger().addDebt(days: 3, occurredOn: DateTime(2025, 3, 1), createdAt: DateTime.utc(2026, 1, 1), sourceRamadanYear: 1446, id: 'local-debt');
    final remote = QadaFastingLedger().addDebt(days: 2, occurredOn: DateTime(2026, 3, 1), createdAt: DateTime.utc(2026, 2, 1), sourceRamadanYear: 1447, id: 'remote-debt');
    SharedPreferences.setMockInitialValues(<String, Object>{QadaFastingStore.preferenceKey: local.encode()});
    await service.restoreDecoded(<String, Object?>{'version': BackupManifest.schemaVersion, 'createdAt': '2026-09-21T14:00:00Z', 'data': <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: remote.encode()}}}, mode: BackupRestoreMode.merge);
    final restored = await const QadaFastingStore().load(); expect(restored.entries.map((entry) => entry.id), <String>['local-debt', 'remote-debt']); expect(restored.remainingDays, 5); expect(restored.debtByRamadan[1446], 3); expect(restored.debtByRamadan[1447], 2);
  });

  test('qada merge keeps local event on immutable id collision', () async {
    final local = QadaFastingLedger().addDebt(days: 3, occurredOn: DateTime(2025, 3, 1), createdAt: DateTime.utc(2026, 1, 1), sourceRamadanYear: 1446, note: 'local private note', id: 'same');
    final remote = QadaFastingLedger().addDebt(days: 99, occurredOn: DateTime(2025, 3, 1), createdAt: DateTime.utc(2026, 1, 1), sourceRamadanYear: 1446, note: 'remote rewrite', id: 'same');
    SharedPreferences.setMockInitialValues(<String, Object>{QadaFastingStore.preferenceKey: local.encode()});
    await service.restoreDecoded(<String, Object?>{'version': BackupManifest.schemaVersion, 'createdAt': '2026-09-21T14:00:00Z', 'data': <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: remote.encode()}}}, mode: BackupRestoreMode.merge);
    final restored = await const QadaFastingStore().load(); expect(restored.entries, hasLength(1)); expect(restored.entries.single.days, 3); expect(restored.entries.single.note, 'local private note');
  });

  test('malformed qada import is rejected before it can erase local history', () async {
    final local = QadaFastingLedger().addDebt(days: 4, occurredOn: DateTime(2025, 3, 1), createdAt: DateTime.utc(2026, 1, 1), id: 'safe-local');
    SharedPreferences.setMockInitialValues(<String, Object>{QadaFastingStore.preferenceKey: local.encode()});
    final malformed = jsonEncode(<String, Object?>{'formatVersion': 1, 'entries': <Object?>[<String, Object?>{'id': '', 'kind': 'debt', 'days': 10}]});
    final import = <String, Object?>{'version': BackupManifest.schemaVersion, 'createdAt': '2026-09-21T14:00:00Z', 'data': <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: malformed}}};

    await expectLater(service.restoreDecoded(import, mode: BackupRestoreMode.merge), throwsFormatException);
    final restored = await const QadaFastingStore().load(); expect(restored.entries.single.id, 'safe-local'); expect(restored.remainingDays, 4);
  });

  test('malformed qada replace is rejected before deleting local history', () async {
    final local = QadaFastingLedger().addDebt(days: 6, occurredOn: DateTime(2025, 3, 1), createdAt: DateTime.utc(2026, 1, 1), id: 'safe-local');
    SharedPreferences.setMockInitialValues(<String, Object>{QadaFastingStore.preferenceKey: local.encode()});
    final import = <String, Object?>{'version': BackupManifest.schemaVersion, 'createdAt': '2026-09-21T14:00:00Z', 'data': <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: '{broken'}}};

    await expectLater(service.restoreDecoded(import, mode: BackupRestoreMode.replace), throwsFormatException);
    final restored = await const QadaFastingStore().load(); expect(restored.entries.single.id, 'safe-local'); expect(restored.remainingDays, 6);
  });
}
