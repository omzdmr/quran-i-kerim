import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_manifest.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = LocalBackupService();

  test('merge aborts and rolls back when same-id conflict would overdraw a Ramadan', () async {
    final local = QadaFastingLedger().addDebt(
      days: 1,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 1, 1),
      sourceRamadanYear: 1447,
      note: 'local canonical event',
      id: 'shared-debt',
    );
    final remote = QadaFastingLedger()
        .addDebt(
          days: 2,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: DateTime.utc(2026, 1, 1),
          sourceRamadanYear: 1447,
          note: 'conflicting remote event',
          id: 'shared-debt',
        )
        .complete(
          days: 2,
          occurredOn: DateTime(2026, 9, 1),
          createdAt: DateTime.utc(2026, 2, 1),
          sourceRamadanYear: 1447,
          id: 'remote-completion',
        );
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: local.encode(),
    });

    final incoming = <String, Object?>{
      'version': BackupManifest.schemaVersion,
      'createdAt': '2026-09-21T14:00:00Z',
      'data': <String, Object?>{
        'fasting': <String, Object?>{
          QadaFastingStore.preferenceKey: remote.encode(),
        },
      },
    };

    await expectLater(
      service.restoreDecoded(incoming, mode: BackupRestoreMode.merge),
      throwsFormatException,
    );
    final restored = await const QadaFastingStore().load();
    expect(restored.entries, hasLength(1));
    expect(restored.entries.single.id, 'shared-debt');
    expect(restored.entries.single.note, 'local canonical event');
    expect(restored.remainingDays, 1);
  });
}
