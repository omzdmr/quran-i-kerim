import 'reading_plan.dart';
import 'reading_plan_redistribution.dart';

enum ReadingPlanRecoveryMode { catchUp, redistribute }

/// User-controlled recovery state for an active reading plan.
///
/// This model deliberately does not mutate [ActiveReadingPlan]. It describes
/// what the user can read next after missing days while completion remains an
/// explicit action in [ReadingPlanStore].
class ReadingPlanRecoverySession {
  const ReadingPlanRecoverySession._({
    required this.mode,
    required this.startPage,
    required this.endPage,
    required this.workDate,
    this.catchUpTarget,
    this.redistribution,
    this.redistributionDayIndex,
  });

  final ReadingPlanRecoveryMode mode;
  final int startPage;
  final int endPage;
  final DateTime workDate;
  final ReadingPlanCatchUpTarget? catchUpTarget;
  final ReadingPlanRedistributionProposal? redistribution;
  final int? redistributionDayIndex;

  int get pageCount => endPage - startPage + 1;

  factory ReadingPlanRecoverySession.catchUp({
    required ActiveReadingPlan active,
    required DateTime now,
  }) {
    final target = active.catchUpTarget(now);
    if (target == null) {
      throw StateError('Completed plans do not have a recovery session.');
    }
    return ReadingPlanRecoverySession._(
      mode: ReadingPlanRecoveryMode.catchUp,
      startPage: target.startPage,
      endPage: target.endPage,
      workDate: readingPlanDateOnly(now),
      catchUpTarget: target,
    );
  }

  factory ReadingPlanRecoverySession.redistributed({
    required ActiveReadingPlan active,
    required DateTime now,
    required DateTime targetEndDate,
    DateTime? forDate,
  }) {
    final proposal = proposeReadingPlanRedistribution(
      active: active,
      now: now,
      targetEndDate: targetEndDate,
    );
    if (proposal == null) {
      throw StateError('Completed plans do not have a recovery session.');
    }

    final date = readingPlanDateOnly(forDate ?? now);
    final index = date.difference(proposal.startDate).inDays;
    if (index < 0 || index >= proposal.availableDays) {
      throw RangeError.range(index, 0, proposal.availableDays - 1, 'forDate');
    }

    return ReadingPlanRecoverySession._(
      mode: ReadingPlanRecoveryMode.redistribute,
      startPage: proposal.startPageForDay(index),
      endPage: proposal.endPageForDay(index),
      workDate: date,
      redistribution: proposal,
      redistributionDayIndex: index,
    );
  }
}
