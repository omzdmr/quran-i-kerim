import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/download_storage_budget.dart';

void main() {
  test('keeps at least 256 MiB as download safety reserve', () {
    final budget = DownloadStorageBudget.evaluate(
      availableBytes: 1024 * 1024 * 1024,
      requiredBytes: 800 * 1024 * 1024,
    );
    expect(budget.reserveBytes, 256 * 1024 * 1024);
    expect(budget.canStart, isFalse);
    expect(budget.shortfallBytes, 32 * 1024 * 1024);
  });

  test('keeps ten percent on very large volumes', () {
    final budget = DownloadStorageBudget.evaluate(
      availableBytes: 10 * 1024 * 1024 * 1024,
      requiredBytes: 8 * 1024 * 1024 * 1024,
    );
    expect(budget.reserveBytes, 1024 * 1024 * 1024);
    expect(budget.canStart, isTrue);
  });

  test('negative platform values fail closed to zero capacity', () {
    final budget = DownloadStorageBudget.evaluate(
      availableBytes: -1,
      requiredBytes: 1,
    );
    expect(budget.availableBytes, 0);
    expect(budget.canStart, isFalse);
    expect(budget.shortfallBytes, 1);
  });
}
