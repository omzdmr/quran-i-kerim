import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/reading_streak.dart';

class MemorizationProgressSnapshot {
  const MemorizationProgressSnapshot({
    required this.memorizedPages,
    required this.practiceDays,
  });

  final Set<int> memorizedPages;
  final Set<String> practiceDays;

  int get memorizedCount => memorizedPages.length;

  int get practiceStreak => calculateReadingStreak(
    practiceDays,
    now: DateTime.now(),
  );

  int? get nextPage {
    for (var page = 1; page <= 604; page++) {
      if (!memorizedPages.contains(page)) return page;
    }
    return null;
  }

  bool containsPage(int page) => memorizedPages.contains(page);
}

class MemorizationProgressStore {
  const MemorizationProgressStore();

  static const _pagesKey = 'memorized_pages_v1';
  static const _daysKey = 'memorization_practice_days_v1';

  String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<MemorizationProgressSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final pages = (prefs.getStringList(_pagesKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .where((page) => page >= 1 && page <= 604)
        .toSet();
    final days = (prefs.getStringList(_daysKey) ?? const <String>[]).toSet();
    return MemorizationProgressSnapshot(
      memorizedPages: pages,
      practiceDays: days,
    );
  }

  Future<MemorizationProgressSnapshot> togglePage(
    int page, {
    DateTime? now,
  }) async {
    if (page < 1 || page > 604) return load();

    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final pages = <int>{...current.memorizedPages};
    final days = <String>{...current.practiceDays};

    if (!pages.remove(page)) {
      pages.add(page);
      days.add(_dayKey(now ?? DateTime.now()));
    }

    final orderedPages = pages.toList()..sort();
    final orderedDays = days.toList()..sort();
    await Future.wait([
      prefs.setStringList(
        _pagesKey,
        orderedPages.map((value) => '$value').toList(),
      ),
      prefs.setStringList(_daysKey, orderedDays),
    ]);

    return MemorizationProgressSnapshot(
      memorizedPages: pages,
      practiceDays: days,
    );
  }
}
