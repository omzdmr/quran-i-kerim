import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/discover/qada_fasting_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = LocalBackupService();

  test('restoring a pre-qada v8 backup does not erase newer local qada history', () async {
    final local = QadaFastingLedger().addDebt(
      days: 3,
      occurredOn: DateTime(2026, 3, 1),
      createdAt: DateTime.utc(2026, 9, 21),
      sourceRamadanYear: 1447,
      note: 'must survive legacy restore',
      id: 'local-qada',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      QadaFastingStore.preferenceKey: local.encode(),
      'theme_mode': 'dark',
    });

    await service.restoreDecoded(<String, Object?>{
      'version': 8,
      'createdAt': '2026-08-01T00:00:00Z',
      'data': <String, Object?>{
        'preferences': <String, Object?>{'theme_mode': 'light'},
      },
    }, mode: BackupRestoreMode.replace);

    final restored = await const QadaFastingStore().load();
    expect(restored.entries, hasLength(1));
    expect(restored.entries.single.id, 'local-qada');
    expect(restored.entries.single.note, 'must survive legacy restore');
    expect(restored.remainingDays, 3);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });
}
