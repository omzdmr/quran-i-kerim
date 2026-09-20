String readingDayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

int calculateReadingStreak(
  Set<String> readingDays, {
  required DateTime now,
}) {
  if (readingDays.isEmpty) return 0;

  final today = DateTime(now.year, now.month, now.day);
  var cursor = readingDays.contains(readingDayKey(today))
      ? today
      : DateTime(today.year, today.month, today.day - 1);

  if (!readingDays.contains(readingDayKey(cursor))) return 0;

  var streak = 0;
  while (readingDays.contains(readingDayKey(cursor))) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
}
