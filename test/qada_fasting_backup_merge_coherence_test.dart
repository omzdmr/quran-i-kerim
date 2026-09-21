import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, Object?> _backup(QadaFastingLedger ledger) => <String, Object?>{
  'version': BackupManifest.schemaVersion,
  'createdAt': '2026-09-21T14:00:00Z',
  'data': <String, Object?>{'fasting': <String, Object?>{QadaFastingStore.preferenceKey: ledger.encode()}},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = LocalBackupService();

  test('merge aborts and rolls back when same-id conflict would overdraw a Ramadan', () async {
    final local = QadaFastingLedger().addDebt(days: 1, occurredOn: DateTime(2026, 3, 1), createdAt: DateTime.utc(2026, 1, 1), sourceRamadanYear: 1447, note: 'local canonical event', id: 'shared-debt');
    final remote = QadaFastingLedger()
        .addDebt(days: 2, occurredOn: DateTime(2026, 3, 1), createdAt: DateTime.utc(2026, 1, 1), sourceRamadanYear: 1447, note: 'conflicting remote event', id: 'shared-debt')
        .complete(days: 2, occurredOn: DateTime(2026, 9, 1), createdAt: DateTime.utc(2026, 2, 1), sourceRamadanYear: 1447, id: 'remote-completion');
    SharedPreferences.setMockInitialValues(<String, Object>{QadaFastingStore.preferenceKey: local.encode()});
    await expectLater(service.restoreDecoded(_backup(remote), mode: BackupRestoreMode.merge), throwsFormatException);
    final restored = await const QadaFastingStore().load();
    expect(restored.entries, hasLength(1)); expect(restored.entries.single.id, 'shared-debt'); expect(restored.entries.single.note, 'local canonical event'); expect(restored.remainingDays, 1);
  });

  test('valid cross-device merge survives createdAt reordering without dropping completion', () async {
    final local = QadaFastingLedger().addDebt(days: 2, occurredOn: DateTime(2026, 3, 1), createdAt: DateTime.utc(2026, 3, 1), sourceRamadanYear: 1447, note: 'local version', id: 'shared-debt');
    final remote = QadaFastingLedger()
        .addDebt(days: 2, occurredOn: DateTime(2026, 3, 1), createdAt: DateTime.utc(2025, 12, 1), sourceRamadanYear: 1447, note: 'remote version', id: 'shared-debt')
        .complete(occurredOn: DateTime(2026, 1, 10), createdAt: DateTime.utc(2026, 1, 10), sourceRamadanYear: 1447, id: 'remote-completion');
    SharedPreferences.setMockInitialValues(<String, Object>{QadaFastingStore.preferenceKey: local.encode()});

    await service.restoreDecoded(_backup(remote), mode: BackupRestoreMode.merge);
    final restored = await const QadaFastingStore().load();

    expect(restored.entries.map((entry) => entry.id).toSet(), <String>{'shared-debt', 'remote-completion'});
    expect(restored.entries.where((entry) => entry.kind == QadaFastingEntryKind.completion), hasLength(1));
    expect(restored.remainingDays, 1);
    expect(restored.remainingForRamadan(1447), 1);
    expect(restored.entries.firstWhere((entry) => entry.id == 'shared-debt').note, 'local version');
  });
}
