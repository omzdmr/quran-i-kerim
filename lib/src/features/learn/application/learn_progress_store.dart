import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only progress for one curated learning lesson.
///
/// This deliberately stores only opaque lesson/step identifiers. Religious
/// copy stays in separately sourced content packages and is never invented by
/// the progress layer.
class LearnProgressSnapshot {
  const LearnProgressSnapshot({
    required this.lessonId,
    required this.completedStepIds,
    required this.updatedAtMs,
    this.currentStepId,
  });

  final String lessonId;
  final Set<String> completedStepIds;
  final String? currentStepId;
  final int updatedAtMs;

  bool isCompleted(String stepId) => completedStepIds.contains(stepId);

  String? nextPendingStep(List<String> orderedStepIds) {
    for (final stepId in orderedStepIds) {
      if (!completedStepIds.contains(stepId)) return stepId;
    }
    return null;
  }

  LearnProgressSnapshot completeStep(
    String stepId, {
    String? nextStepId,
    required int updatedAtMs,
  }) {
    final nextCompleted = <String>{...completedStepIds, stepId};
    return LearnProgressSnapshot(
      lessonId: lessonId,
      completedStepIds: nextCompleted,
      currentStepId: nextStepId,
      updatedAtMs: updatedAtMs,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'lessonId': lessonId,
    'completedStepIds': completedStepIds.toList()..sort(),
    'currentStepId': currentStepId,
    'updatedAtMs': updatedAtMs,
  };

  static LearnProgressSnapshot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final lessonId = raw['lessonId'];
    final completed = raw['completedStepIds'];
    final current = raw['currentStepId'];
    final updated = raw['updatedAtMs'];
    if (lessonId is! String || lessonId.trim().isEmpty) return null;
    if (completed is! List || updated is! int || updated < 0) return null;
    if (current != null && current is! String) return null;

    final completedIds = <String>{};
    for (final value in completed) {
      if (value is! String || value.trim().isEmpty) return null;
      completedIds.add(value);
    }

    return LearnProgressSnapshot(
      lessonId: lessonId,
      completedStepIds: completedIds,
      currentStepId: current as String?,
      updatedAtMs: updated,
    );
  }
}

class LearnProgressStore {
  const LearnProgressStore();

  static const _prefix = 'learn_progress_v1:';

  /// Process-local signal used only when SharedPreferences changes outside the
  /// normal lesson flow, currently backup/cloud restore.
  ///
  /// Normal lesson writes deliberately do not fire this notifier because the
  /// lesson list already reloads when a lesson route closes. Firing on every
  /// step would make the hidden overview reread all lesson progress repeatedly.
  static final ValueNotifier<int> externalChanges = ValueNotifier<int>(0);

  static void notifyExternalChange() {
    externalChanges.value += 1;
  }

  String _key(String lessonId) => '$_prefix$lessonId';

  Future<LearnProgressSnapshot?> load(String lessonId) async {
    if (lessonId.trim().isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key(lessonId));
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return LearnProgressSnapshot.fromJson(jsonDecode(encoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(LearnProgressSnapshot snapshot) async {
    if (snapshot.lessonId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(snapshot.lessonId), jsonEncode(snapshot.toJson()));
  }

  Future<LearnProgressSnapshot> completeStep({
    required String lessonId,
    required String stepId,
    required int updatedAtMs,
    String? nextStepId,
  }) async {
    final existing = await load(lessonId);
    final base = existing ??
        LearnProgressSnapshot(
          lessonId: lessonId,
          completedStepIds: const <String>{},
          updatedAtMs: updatedAtMs,
        );
    final updated = base.completeStep(
      stepId,
      nextStepId: nextStepId,
      updatedAtMs: updatedAtMs,
    );
    await save(updated);
    return updated;
  }
}
