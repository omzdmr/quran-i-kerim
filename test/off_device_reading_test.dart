import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/data/backup/local_backup_service.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan.dart';
import 'package:quran_i_kerim/src/features/plans/reading_plan_store.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/off_device_reading_strings.dart';

void main() {
  const store = ReadingPlanStore();
  final today = DateTime(2026, 9, 20);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> add() => store.addOffDeviceSession(
    readAt: today, startPage: 2, endPage: 5, note: ' Paper ', now: today,
  );

  test('persists inclusive range, date and trimmed private note', () async {
    await add();
    final item = (await const ReadingPlanStore().load()).offDeviceSessions.single;
    expect(item.pageCount, 4);
    expect(item.readAt, today);
    expect(item.note, 'Paper');
  });

  test('does not advance active plan or annual khatm count', () async {
    await store.start(ReadingPlanPreset.quran30, now: today);
    await store.setYearlyKhatmTarget(2);
    await add();
    final snapshot = await store.load();
    expect(snapshot.active!.completedDays, isEmpty);
    expect(snapshot.completedInYear(2026), 0);
    expect(snapshot.yearlyKhatmTarget, 2);
  });

  test('all common plan mutations preserve reading sessions', () async {
    await add();
    await store.start(ReadingPlanPreset.quran30, now: today);
    await store.toggleSaved(ReadingPlanPreset.quran90);
    await store.pauseActive(now: today);
    await store.resumeActive(now: today);
    await store.setYearlyKhatmTarget(3);
    await store.setRedistributionTargetEndDate(today, now: today);
    await store.clearRedistributionTargetEndDate();
    await store.completeNextDay(now: today);
    await store.completeThroughDay(30, now: today);
    await store.addManualCompletedKhatm(completedAt: today, now: today);
    await store.updateManualCompletedKhatmAt(0, completedAt: today, now: today);
    await store.removeCompletedAt(0);
    await store.start(ReadingPlanPreset.quran90, now: today);
    await store.stopActive();
    expect((await store.load()).offDeviceSessions.single.pageCount, 4);
  });

  test('repeats stay separate and deletion removes only one', () async {
    await add(); await add();
    expect((await store.load()).offDeviceSessions, hasLength(2));
    await store.removeOffDeviceSessionAt(0);
    expect((await store.load()).offDeviceSessions, hasLength(1));
    await expectLater(store.removeOffDeviceSessionAt(2), throwsRangeError);
  });

  test('rejects invalid ranges and future dates without writing', () async {
    for (final range in [(0, 1), (4, 3), (604, 605)]) {
      await expectLater(store.addOffDeviceSession(readAt: today,
        startPage: range.$1, endPage: range.$2, now: today), throwsArgumentError);
    }
    await expectLater(store.addOffDeviceSession(
      readAt: today.add(const Duration(days: 1)), startPage: 1, endPage: 1,
      now: today), throwsArgumentError);
    expect((await store.load()).offDeviceSessions, isEmpty);
  });

  test('malformed session does not discard active plan or good sessions', () async {
    await store.start(ReadingPlanPreset.quran30, now: today);
    await add();
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonDecode(prefs.getString(ReadingPlanStore.preferenceKey)!) as Map;
    (raw['offDeviceSessions'] as List).add({'startPage': 'bad'});
    await prefs.setString(ReadingPlanStore.preferenceKey, jsonEncode(raw));
    final snapshot = await store.load();
    expect(snapshot.active, isNotNull);
    expect(snapshot.offDeviceSessions, hasLength(1));
  });

  test('sessions round-trip through existing backup unit', () async {
    await add();
    const backup = LocalBackupService();
    final exported = await backup.exportJson(now: today);
    SharedPreferences.setMockInitialValues({});
    await backup.restoreDecoded(jsonDecode(exported) as Map<String, dynamic>);
    expect((await store.load()).offDeviceSessions.single.pageCount, 4);
  });

  test('all supported locales resolve every new label', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final strings = offDeviceReadingStrings[locale.languageCode]!;
      expect(strings.keys.toSet(), offDeviceReadingStrings['en']!.keys.toSet());
      for (final entry in strings.entries) {
        expect(entry.value.trim(), isNotEmpty);
        expect(AppLocalizations(Locale(locale.languageCode)).text(entry.key), entry.value);
      }
    }
  });
}
