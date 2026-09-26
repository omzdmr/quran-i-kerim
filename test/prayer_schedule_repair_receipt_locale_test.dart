import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_schedule_repair_receipt_card.dart';

void main() {
  test('all supported locales explain repair outcomes and actionable triggers', () {
    for (final language in const <String>['tr', 'en', 'fr', 'ar', 'az', 'ru']) {
      final copy = PrayerScheduleRepairReceiptCopy.forLocale(Locale(language));
      expect(copy.title.trim(), isNotEmpty, reason: language);
      expect(copy.checked.trim(), isNotEmpty, reason: language);
      for (final outcome in PrayerScheduleRepairOutcome.values) {
        final message = copy.message(outcome);
        expect(message.trim(), isNotEmpty, reason: '$language ${outcome.name}');
        expect(message, isNot(contains(outcome.name)), reason: '$language ${outcome.name}');
      }
      for (final trigger in const <PrayerScheduleRepairTrigger>[
        PrayerScheduleRepairTrigger.configurationChanged,
        PrayerScheduleRepairTrigger.platformScheduleMissing,
        PrayerScheduleRepairTrigger.staleEvidence,
      ]) {
        final reason = copy.reason(trigger);
        expect(reason.trim(), isNotEmpty, reason: '$language ${trigger.name}');
        expect(reason, isNot(contains(trigger.name)), reason: '$language ${trigger.name}');
      }
    }
  });

  test('non-actionable internal triggers stay out of user copy', () {
    final copy = PrayerScheduleRepairReceiptCopy.forLocale(const Locale('en'));
    expect(copy.reason(PrayerScheduleRepairTrigger.unknown), isEmpty);
    expect(copy.reason(PrayerScheduleRepairTrigger.verifiedFresh), isEmpty);
    expect(copy.reason(PrayerScheduleRepairTrigger.noSchedulableConfiguration), isEmpty);
  });

  test('unsupported locale safely falls back to English', () {
    expect(PrayerScheduleRepairReceiptCopy.forLocale(const Locale('de')).title, 'Automatic check');
  });
}
