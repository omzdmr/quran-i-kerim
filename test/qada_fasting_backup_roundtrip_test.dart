import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = LocalBackupService();

  test('portable backup round trip preserves qada event identity and private note', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = QadaFastingStore();
    final original = QadaFastingLedger()
        .addDebt(
          days: 3,
          occurredOn: DateTime(2026, 3, 1),
          createdAt: DateTime.utc(2026, 9, 21, 8),
          sourceRamadanYear: 1447,
          note: 'private provenance',
          id: 'debt-1447',
        )
        .complete(
          occurredOn: DateTime(2026, 9, 21),
          createdAt: DateTime.utc(2026, 9, 21, 8, 1),
          id: 'done-1447',
        );
    await store.save(original);

    final encoded = await service.exportJson(now: DateTime.utc(2026, 9, 21, 9));
    final plan = await service.planImportJson(encoded);
    expect(plan.incomingRecords, greaterThanOrEqualTo(2));

    SharedPreferences.setMockInitialValues(<String, Object>{});
    await service.restoreJson(encoded, mode: BackupRestoreMode.replace);
    final restored = await store.load();

    expect(restored.entries.map((entry) => entry.id), <String>['debt-1447', 'done-1447']);
    expect(restored.entries.first.note, 'private provenance');
    expect(restored.entries.last.sourceRamadanYear, 1447);
    expect(restored.remainingDays, 2);
    expect(restored.remainingForRamadan(1447), 2);
  });

  test('merge round trip does not duplicate qada events already on device', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = QadaFastingStore();
    final original = QadaFastingLedger().addDebt(
      days: 2,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21, 8),
      sourceRamadanYear: 1447,
      id: 'stable-event',
    );
    await store.save(original);
    final encoded = await service.exportJson(now: DateTime.utc(2026, 9, 21, 9));

    await service.restoreJson(encoded, mode: BackupRestoreMode.merge);
    await service.restoreJson(encoded, mode: BackupRestoreMode.merge);
    final restored = await store.load();

    expect(restored.entries, hasLength(1));
    expect(restored.entries.single.id, 'stable-event');
    expect(restored.remainingDays, 2);
  });
}
