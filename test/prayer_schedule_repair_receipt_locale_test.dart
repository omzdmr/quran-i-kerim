import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_schedule_repair_receipt_store.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/prayer_schedule_repair_receipt_card.dart';

void main() {
  test('all supported locales explain every repair outcome without raw enum text', () {
    for (final language in const <String>['tr', 'en', 'fr', 'ar', 'az', 'ru']) {
      final copy = PrayerScheduleRepairReceiptCopy.forLocale(Locale(language));
      expect(copy.title.trim(), isNotEmpty, reason: language);
      expect(copy.checked.trim(), isNotEmpty, reason: language);
      for (final outcome in PrayerScheduleRepairOutcome.values) {
        final message = copy.message(outcome);
        expect(message.trim(), isNotEmpty, reason: '$language ${outcome.name}');
        expect(message, isNot(contains(outcome.name)), reason: '$language ${outcome.name}');
      }
    }
  });

  test('unsupported locale safely falls back to English', () {
    final copy = PrayerScheduleRepairReceiptCopy.forLocale(const Locale('de'));
    expect(copy.title, 'Automatic check');
  });
}
