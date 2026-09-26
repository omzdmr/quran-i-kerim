import 'qada_fasting_ledger.dart';

/// Derived-only summary. It does not mutate the ledger or infer fiqh rules.
class QadaFastingBalanceSummary {
  const QadaFastingBalanceSummary({
    required this.knownRamadanRemainingDays,
    required this.unknownYearDebtDays,
    required this.unattributedCompletedDays,
    required this.correctionDeltaDays,
    required this.totalRemainingDays,
  });

  final int knownRamadanRemainingDays;
  final int unknownYearDebtDays;
  final int unattributedCompletedDays;
  final int correctionDeltaDays;
  final int totalRemainingDays;

  /// Balance that cannot honestly be assigned to a known Ramadan year.
  int get unallocatedBalanceDays =>
      unknownYearDebtDays - unattributedCompletedDays + correctionDeltaDays;

  bool get reconciles =>
      knownRamadanRemainingDays + unallocatedBalanceDays == totalRemainingDays;

  factory QadaFastingBalanceSummary.fromLedger(QadaFastingLedger ledger) {
    final knownYears = ledger.debtByRamadan.keys.whereType<int>();
    final knownRemaining = knownYears.fold<int>(
      0,
      (sum, year) => sum + ledger.remainingForRamadan(year),
    );
    final attributedCompleted = ledger.attributedCompletionsByRamadan.values
        .fold<int>(0, (sum, value) => sum + value);
    final correctionDelta = ledger.entries
        .where((entry) => entry.kind == QadaFastingEntryKind.correction)
        .fold<int>(0, (sum, entry) => sum + entry.balanceDelta);
    return QadaFastingBalanceSummary(
      knownRamadanRemainingDays: knownRemaining,
      unknownYearDebtDays: ledger.debtByRamadan[null] ?? 0,
      unattributedCompletedDays: ledger.completedDays - attributedCompleted,
      correctionDeltaDays: correctionDelta,
      totalRemainingDays: ledger.remainingDays,
    );
  }
}
