import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calendar_export.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calculator.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/prayer_calendar_strings.dart';

void main() {
  const location = PrayerLocation(
    latitude: 40.7128, longitude: -74.0060, timeZoneId: 'America/New_York',
  );
  final calculator = PrayerCalculator();
  final stamp = DateTime.utc(2026, 1, 1);
  final labels = {for (final id in PrayerCalendarExport.prayerIds) id: id};
  PrayerDaySchedule day(int day, {PrayerPreferences preferences = const PrayerPreferences()}) =>
      calculator.calculate(location: location, date: DateTime(2026, 3, day), preferences: preferences);

  String export(List<PrayerDaySchedule> schedules, {String city = 'New York', DateTime? generatedAt}) =>
      PrayerCalendarExport.build(schedules: schedules, calendarId: 'new-york',
        cityLabel: city, description: 'Calculated start', labels: labels,
        generatedAt: generatedAt ?? stamp);

  String unfold(String value) => value.replaceAll('\r\n ', '');

  test('month produces five events per day and no sunrise or alarms', () {
    final text = unfold(export([for (var i = 1; i <= 31; i++) day(i)]));
    expect('BEGIN:VEVENT'.allMatches(text), hasLength(155));
    expect(text, startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'));
    expect(text, endsWith('END:VCALENDAR\r\n'));
    for (final forbidden in ['sunrise', 'VALARM', 'GEO:', 'ATTENDEE:', 'RRULE:', 'DTEND:']) {
      expect(text, isNot(contains(forbidden)));
    }
    expect('TRANSP:TRANSPARENT'.allMatches(text), hasLength(155));
    expect('CLASS:PRIVATE'.allMatches(text), hasLength(155));
  });

  test('DST is resolved per date rather than using one monthly offset', () {
    final before = day(7);
    final after = day(8);
    expect(before.fajr.timeZoneOffset, const Duration(hours: -5));
    expect(after.fajr.timeZoneOffset, const Duration(hours: -4));
    final text = unfold(export([before, after]));
    final starts = RegExp(r'DTSTART:(\d{8}T\d{6}Z)').allMatches(text)
        .map((m) => DateTime.parse(m.group(1)!)).toList();
    expect(starts.first, before.fajr.toUtc());
    expect(starts[5], after.fajr.toUtc());
    expect(text, isNot(contains('TZID=')));
  });

  test('exports calculator adjustments unchanged', () {
    final normal = day(10);
    final adjusted = day(10, preferences: const PrayerPreferences(
      adjustments: PrayerMinuteAdjustments(fajr: 7),
    ));
    expect(adjusted.fajr.difference(normal.fajr).inMinutes, 7);
    final text = unfold(export([adjusted]));
    final start = RegExp(r'DTSTART:(\d{8}T\d{6}Z)').firstMatch(text)!;
    expect(DateTime.parse(start.group(1)!), adjusted.fajr.toUtc());
  });

  test('stable UIDs across repeated exports but distinct by prayer and date', () {
    Set<String> ids(String text) => RegExp(r'UID:([^\r]+)').allMatches(unfold(text))
        .map((m) => m.group(1)!).toSet();
    final schedules = [day(7), day(8)];
    expect(ids(export(schedules)), hasLength(10));
    expect(ids(export(schedules)), ids(export(schedules, generatedAt: stamp.add(const Duration(days: 2)))));
  });

  test('UTF-8 folding and TEXT escaping prevent accidental extra properties', () {
    final city = '${List.filled(60, 'İstanbul العربية 🌙').join()}\\,;\r\nBEGIN:VALARM';
    final text = export([day(1)], city: city);
    for (final line in text.split('\r\n')) {
      expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      expect(utf8.decode(utf8.encode(line)), line);
    }
    final unfolded = unfold(text);
    expect(unfolded, contains(r'\\\,\;\nBEGIN:VALARM'));
    expect(unfolded, isNot(contains('\r\nBEGIN:VALARM')));
    expect(unfolded, contains('İstanbul العربية 🌙'));
  });

  test('rejects empty and duplicate dates and missing labels', () {
    expect(() => export([]), throwsArgumentError);
    expect(() => export([day(1), day(1)]), throwsArgumentError);
    expect(() => PrayerCalendarExport.build(schedules: [day(1)],
      calendarId: 'x', cityLabel: 'x', description: '', labels: {}), throwsArgumentError);
  });

  test('copy covers every supported locale', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final strings = prayerCalendarStrings[locale.languageCode]!;
      expect(strings.keys.toSet(), prayerCalendarStrings['en']!.keys.toSet());
      for (final entry in strings.entries) {
        expect(entry.value.trim(), isNotEmpty);
        expect(AppLocalizations(locale).calendarText(entry.key), entry.value);
      }
    }
  });
}
