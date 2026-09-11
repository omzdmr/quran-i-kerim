class DhikrDailySnapshot {
  const DhikrDailySnapshot({required this.dateKey, required this.counts});

  final String dateKey;
  final Map<String, int> counts;
}

DhikrDailySnapshot normalizeDhikrDailySnapshot({
  required String? storedDateKey,
  required String todayDateKey,
  required Map<String, int> counts,
}) {
  if (storedDateKey == todayDateKey) {
    return DhikrDailySnapshot(
      dateKey: todayDateKey,
      counts: Map<String, int>.from(counts),
    );
  }

  return DhikrDailySnapshot(
    dateKey: todayDateKey,
    counts: <String, int>{},
  );
}
