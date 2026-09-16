import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/backup_restore_coordinator.dart';

void main() {
  const coordinator = BackupRestoreCoordinator();

  test('validates before snapshot and restore', () async {
    final calls = <String>[];

    await coordinator.restore(
      validate: () async => calls.add('validate'),
      captureSnapshot: () async {
        calls.add('snapshot');
        return 'before';
      },
      applyRestore: () async => calls.add('apply'),
      rollback: (_) async => calls.add('rollback'),
    );

    expect(calls, ['validate', 'snapshot', 'apply']);
  });

  test('validation failure never mutates local storage', () async {
    final calls = <String>[];

    await expectLater(
      coordinator.restore(
        validate: () async => throw const FormatException('invalid backup'),
        captureSnapshot: () async {
          calls.add('snapshot');
          return null;
        },
        applyRestore: () async => calls.add('apply'),
        rollback: (_) async => calls.add('rollback'),
      ),
      throwsFormatException,
    );

    expect(calls, isEmpty);
  });

  test('apply failure restores captured snapshot', () async {
    final calls = <String>[];
    Object? rolledBackSnapshot;

    await expectLater(
      coordinator.restore(
        validate: () async => calls.add('validate'),
        captureSnapshot: () async {
          calls.add('snapshot');
          return {'saved': 4};
        },
        applyRestore: () async {
          calls.add('apply');
          throw StateError('write failed');
        },
        rollback: (snapshot) async {
          calls.add('rollback');
          rolledBackSnapshot = snapshot;
        },
      ),
      throwsStateError,
    );

    expect(calls, ['validate', 'snapshot', 'apply', 'rollback']);
    expect(rolledBackSnapshot, {'saved': 4});
  });

  test('reports restore and rollback failures together', () async {
    await expectLater(
      coordinator.restore(
        validate: () async {},
        captureSnapshot: () async => 'before',
        applyRestore: () async => throw StateError('write failed'),
        rollback: (_) async => throw StateError('rollback failed'),
      ),
      throwsA(
        isA<BackupRestoreRollbackException>()
            .having(
              (error) => error.restoreError.toString(),
              'restoreError',
              contains('write failed'),
            )
            .having(
              (error) => error.rollbackError.toString(),
              'rollbackError',
              contains('rollback failed'),
            ),
      ),
    );
  });
}
