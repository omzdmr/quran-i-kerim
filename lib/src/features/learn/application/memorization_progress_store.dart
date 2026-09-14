import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/reading_streak.dart';

enum MemorizationSelfAssessment {
  struggled,
  assisted,
  independent,
}

class MemorizationPageProgress {
  const MemorizationPageProgress({
    this.memorizedAt,
    this.lastReviewedAt,
    this.selfAssessment,
  });

  final DateTime? memorizedAt;
  final DateTime? lastReviewedAt;
  final MemorizationSelfAssessment? selfAssessment;

  MemorizationPageProgress copyWith({
    DateTime? memorizedAt,
    DateTime? lastReviewedAt,
    MemorizationSelfAssessment? selfAssessment,
  }) {
    return MemorizationPageProgress(
      memorizedAt: memorizedAt ?? this.memorizedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      selfAssessment: selfAssessment ?? this.selfAssessment,
    );
  }
}

class MemorizationProgressSnapshot {
  const MemorizationProgressSnapshot({
    required this.memorizedPages,
    required this.practiceDays,
    this.pageProgress = const <int, MemorizationPageProgress>{},
  });

  final Set<int> memorizedPages;
  final Set<String> practiceDays;
  final Map<int, MemorizationPageProgress> pageProgress;

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

  MemorizationPageProgress? progressForPage(int page) => pageProgress[page];
}

class MemorizationProgressStore {
  const MemorizationProgressStore();

  static const _pagesKey = 'memorized_pages_v1';
  static const _daysKey = 'memorization_practice_days_v1';
  static const _pageProgressKey = 'memorization_page_progress_v1';

  String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _parseDateTime(Object? raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  MemorizationSelfAssessment? _parseAssessment(Object? raw) {
    if (raw is! String) return null;
    for (final value in MemorizationSelfAssessment.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  Map<int, MemorizationPageProgress> _decodePageProgress(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <int, MemorizationPageProgress>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <int, MemorizationPageProgress>{};
      }

      final result = <int, MemorizationPageProgress>{};
      for (final entry in decoded.entries) {
        final page = int.tryParse(entry.key);
        final value = entry.value;
        if (page == null || page < 1 || page > 604 || value is! Map) {
          continue;
        }
        result[page] = MemorizationPageProgress(
          memorizedAt: _parseDateTime(value['memorizedAt']),
          lastReviewedAt: _parseDateTime(value['lastReviewedAt']),
          selfAssessment: _parseAssessment(value['selfAssessment']),
        );
      }
      return result;
    } on FormatException {
      return <int, MemorizationPageProgress>{};
    }
  }

  String _encodePageProgress(
    Map<int, MemorizationPageProgress> pageProgress,
  ) {
    final encoded = <String, Object?>{};
    final pages = pageProgress.keys.toList()..sort();
    for (final page in pages) {
      final progress = pageProgress[page]!;
      encoded['$page'] = <String, Object?>{
        'memorizedAt': progress.memorizedAt?.toIso8601String(),
        'lastReviewedAt': progress.lastReviewedAt?.toIso8601String(),
        'selfAssessment': progress.selfAssessment?.name,
      };
    }
    return jsonEncode(encoded);
  }

  Future<MemorizationProgressSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final pages = (prefs.getStringList(_pagesKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .where((page) => page >= 1 && page <= 604)
        .toSet();
    final days = (prefs.getStringList(_daysKey) ?? const <String>[]).toSet();
    final rawPageProgress = prefs.getString(_pageProgressKey);
    final pageProgress = _decodePageProgress(rawPageProgress)
      ..removeWhere((page, _) => !pages.contains(page));
    if (rawPageProgress != null) {
      final normalizedPageProgress = _encodePageProgress(pageProgress);
      if (rawPageProgress != normalizedPageProgress) {
        await prefs.setString(_pageProgressKey, normalizedPageProgress);
      }
    }
    return MemorizationProgressSnapshot(
      memorizedPages: pages,
      practiceDays: days,
      pageProgress: pageProgress,
    );
  }

  Future<MemorizationProgressSnapshot> togglePage(
    int page, {
    DateTime? now,
  }) async {
    if (page < 1 || page > 604) return load();

    final current = await load();
    final pages = <int>{...current.memorizedPages};
    final days = <String>{...current.practiceDays};
    final pageProgress = <int, MemorizationPageProgress>{
      ...current.pageProgress,
    };
    final effectiveNow = now ?? DateTime.now();

    if (!pages.remove(page)) {
      pages.add(page);
      days.add(_dayKey(effectiveNow));
      pageProgress[page] = MemorizationPageProgress(
        memorizedAt: effectiveNow,
      );
    } else {
      pageProgress.remove(page);
    }

    return _save(
      pages: pages,
      days: days,
      pageProgress: pageProgress,
    );
  }

  Future<MemorizationProgressSnapshot> recordReview(
    int page, {
    required MemorizationSelfAssessment selfAssessment,
    DateTime? now,
  }) async {
    final current = await load();
    if (page < 1 || page > 604 || !current.memorizedPages.contains(page)) {
      return current;
    }

    final effectiveNow = now ?? DateTime.now();
    final days = <String>{...current.practiceDays}..add(_dayKey(effectiveNow));
    final pageProgress = <int, MemorizationPageProgress>{
      ...current.pageProgress,
    };
    final existing = pageProgress[page] ?? const MemorizationPageProgress();
    pageProgress[page] = existing.copyWith(
      lastReviewedAt: effectiveNow,
      selfAssessment: selfAssessment,
    );

    return _save(
      pages: current.memorizedPages,
      days: days,
      pageProgress: pageProgress,
    );
  }

  Future<MemorizationProgressSnapshot> recordSelfAssessment(
    int page, {
    required MemorizationSelfAssessment selfAssessment,
    DateTime? now,
  }) async {
    final current = await load();
    if (page < 1 || page > 604 || !current.memorizedPages.contains(page)) {
      return current;
    }

    final effectiveNow = now ?? DateTime.now();
    final days = <String>{...current.practiceDays}..add(_dayKey(effectiveNow));
    final pageProgress = <int, MemorizationPageProgress>{
      ...current.pageProgress,
    };
    final existing = pageProgress[page] ?? const MemorizationPageProgress();
    pageProgress[page] = existing.copyWith(selfAssessment: selfAssessment);

    return _save(
      pages: current.memorizedPages,
      days: days,
      pageProgress: pageProgress,
    );
  }

  Future<MemorizationProgressSnapshot> _save({
    required Set<int> pages,
    required Set<String> days,
    required Map<int, MemorizationPageProgress> pageProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final orderedPages = pages.toList()..sort();
    final orderedDays = days.toList()..sort();
    await Future.wait([
      prefs.setStringList(
        _pagesKey,
        orderedPages.map((value) => '$value').toList(),
      ),
      prefs.setStringList(_daysKey, orderedDays),
      prefs.setString(_pageProgressKey, _encodePageProgress(pageProgress)),
    ]);

    return MemorizationProgressSnapshot(
      memorizedPages: Set<int>.unmodifiable(pages),
      practiceDays: Set<String>.unmodifiable(days),
      pageProgress: Map<int, MemorizationPageProgress>.unmodifiable(
        pageProgress,
      ),
    );
  }
}
