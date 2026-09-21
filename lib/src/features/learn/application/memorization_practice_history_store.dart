import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'memorization_page_catalog.dart';

enum MemorizationPracticeContext { soloReview, prayer, recitedToSomeone }

class MemorizationPracticeEvent {
  const MemorizationPracticeEvent({
    required this.id,
    required this.page,
    required this.context,
    required this.occurredAt,
  });
  final String id;
  final int page;
  final MemorizationPracticeContext context;
  final DateTime occurredAt;
}

class MemorizationPracticeHistorySnapshot {
  const MemorizationPracticeHistorySnapshot(this.events);
  final List<MemorizationPracticeEvent> events;

  List<MemorizationPracticeEvent> eventsForPage(int page) =>
      List<MemorizationPracticeEvent>.unmodifiable(events.where((event) => event.page == page));

  int countForPage(int page, {MemorizationPracticeContext? context}) =>
      events.where((event) {
        if (event.page != page) return false;
        return context == null || event.context == context;
      }).length;

  MemorizationPracticeEvent? latestForPage(int page) {
    for (final event in events) {
      if (event.page == page) return event;
    }
    return null;
  }
}

class MemorizationPracticeHistoryStore {
  const MemorizationPracticeHistoryStore();

  static const _key = 'memorization_practice_history_v1';

  /// Detailed history is intentionally bounded, but 400 events was too small:
  /// a user reviewing 15-20 pages daily could lose a full month of context.
  /// 4000 remains compact enough for the local JSON preference while preserving
  /// months of detailed review activity. Older app data remains compatible.
  static const maxEvents = 4000;

  MemorizationPracticeContext? _parseContext(Object? raw) {
    if (raw is! String) return null;
    for (final value in MemorizationPracticeContext.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  List<MemorizationPracticeEvent> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <MemorizationPracticeEvent>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <MemorizationPracticeEvent>[];
      final byId = <String, MemorizationPracticeEvent>{};
      for (final value in decoded) {
        if (value is! Map) continue;
        final id = value['id'];
        final page = value['page'];
        final context = _parseContext(value['context']);
        final occurredAtRaw = value['occurredAt'];
        final occurredAt = occurredAtRaw is String ? DateTime.tryParse(occurredAtRaw) : null;
        if (id is! String || id.trim().isEmpty || page is! int ||
            memorizationPageInfo(page) == null || context == null || occurredAt == null) {
          continue;
        }
        byId[id] = MemorizationPracticeEvent(
          id: id,
          page: page,
          context: context,
          occurredAt: occurredAt,
        );
      }
      final events = byId.values.toList(growable: false)
        ..sort((a, b) {
          final byDate = b.occurredAt.compareTo(a.occurredAt);
          return byDate != 0 ? byDate : b.id.compareTo(a.id);
        });
      return events.length <= maxEvents
          ? events
          : events.take(maxEvents).toList(growable: false);
    } on FormatException {
      return <MemorizationPracticeEvent>[];
    }
  }

  String _encode(List<MemorizationPracticeEvent> events) => jsonEncode(
        events.map((event) => <String, Object>{
          'id': event.id,
          'page': event.page,
          'context': event.context.name,
          'occurredAt': event.occurredAt.toIso8601String(),
        }).toList(growable: false),
      );

  Future<MemorizationPracticeHistorySnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final events = _decode(prefs.getString(_key));
    return MemorizationPracticeHistorySnapshot(
      List<MemorizationPracticeEvent>.unmodifiable(events),
    );
  }

  Future<MemorizationPracticeHistorySnapshot> record({
    required int page,
    required MemorizationPracticeContext context,
    DateTime? now,
  }) async {
    if (memorizationPageInfo(page) == null) return load();
    final occurredAt = now ?? DateTime.now();
    final current = await load();
    final id = '${occurredAt.toUtc().microsecondsSinceEpoch}:$page:${context.name}';
    final events = <MemorizationPracticeEvent>[
      MemorizationPracticeEvent(id: id, page: page, context: context, occurredAt: occurredAt),
      ...current.events.where((event) => event.id != id),
    ]
      ..sort((a, b) {
        final byDate = b.occurredAt.compareTo(a.occurredAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
    final limited = events.length <= maxEvents
        ? events
        : events.take(maxEvents).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _encode(limited));
    return MemorizationPracticeHistorySnapshot(
      List<MemorizationPracticeEvent>.unmodifiable(limited),
    );
  }

  Future<MemorizationPracticeHistorySnapshot> remove(String eventId) async {
    if (eventId.trim().isEmpty) return load();
    final current = await load();
    final events = current.events.where((event) => event.id != eventId).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _encode(events));
    return MemorizationPracticeHistorySnapshot(
      List<MemorizationPracticeEvent>.unmodifiable(events),
    );
  }
}
