import '../reader/reader_navigation.dart';
import 'reading_plan_recovery.dart';

/// Navigation-ready projection of a recovery session.
///
/// Keeps Plans UI independent from Mushaf page-to-ayah lookup details and
/// guarantees that a recovery action opens the first canonical ayah on the
/// selected work range. It never marks plan progress complete.
class ReadingPlanRecoveryDestination {
  const ReadingPlanRecoveryDestination({
    required this.mode,
    required this.startPage,
    required this.endPage,
    required this.surah,
    required this.ayah,
  });

  final ReadingPlanRecoveryMode mode;
  final int startPage;
  final int endPage;
  final int surah;
  final int ayah;

  int get pageCount => endPage - startPage + 1;
}

ReadingPlanRecoveryDestination? recoveryDestinationForSession(
  ReadingPlanRecoverySession? session,
) {
  if (session == null) return null;
  final verse = firstVerseForPage(session.startPage);
  if (verse == null) return null;
  return ReadingPlanRecoveryDestination(
    mode: session.mode,
    startPage: session.startPage,
    endPage: session.endPage,
    surah: verse.surah,
    ayah: verse.ayah,
  );
}
