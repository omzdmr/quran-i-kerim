import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calendar_export.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

PrayerDaySchedule _day() => PrayerDaySchedule(
      localDate: DateTime.utc(2026, 9, 26),
      fajr: DateTime.utc(2026, 9, 26, 5, 12),
      sunrise: DateTime.utc(2026, 9, 26, 6, 31),
      dhuhr: DateTime.utc(2026, 9, 26, 12, 3),
      asr: DateTime.utc(2026, 9, 26, 15, 19),
      maghrib: DateTime.utc(2026, 9, 26, 18, 2),
      isha: DateTime.utc(2026, 9, 26, 19, 21),
      qiblaDegrees: 240,
    );

void main() {
  const exporter = PrayerCalendarIcsExporter();

  test('exports five prayers with timezone and excludes sunrise', () {
    final ics = exporter.build(
      schedules: <PrayerDaySchedule>[_day()],
      timeZoneId: 'Asia/Shanghai',
      calendarName: 'Prayer Times, Shanghai',
      calendarId: 'shanghai',
      prayerLabel: (id) => id.toUpperCase(),
      generatedAt: DateTime.utc(2026, 9, 25, 20),
    );

    expect(ics, contains('X-WR-TIMEZONE:Asia/Shanghai'));
    expect(ics, contains('X-WR-CALNAME:Prayer Times\\, Shanghai'));
    expect(ics, contains('DTSTART:20260926T051200Z'));
    expect(ics, contains('UID:shanghai-fajr-20260926@quran-i-kerim.local'));
    expect(ics, contains('SUMMARY:FAJR'));
    expect(RegExp('TRANSP:TRANSPARENT').allMatches(ics), hasLength(5));
    expect(ics, contains('DTSTAMP:20260925T200000Z'));
    expect(RegExp('BEGIN:VEVENT').allMatches(ics), hasLength(5));
    expect(ics, isNot(contains('SUMMARY:SUNRISE')));
  });

  test('file service writes an importable ics file without coordinates', () async {
    final directory = await Directory.systemTemp.createTemp('prayer-ics-test-');
    addTearDown(() => directory.delete(recursive: true));

    final service = PrayerCalendarExportFileService(
      directoryProvider: () async => directory,
    );
    final file = await service.createFile(
      schedules: <PrayerDaySchedule>[_day()],
      timeZoneId: 'Asia/Shanghai',
      calendarName: 'Monthly Prayer Times',
      calendarId: 'shanghai',
      prayerLabel: (id) => id,
      month: DateTime(2026, 9),
    );

    expect(file.path, endsWith('prayer-times-2026-09.ics'));
    final text = await file.readAsString();
    expect(text, startsWith('BEGIN:VCALENDAR\r\n'));
    expect(text, endsWith('END:VCALENDAR\r\n'));
    expect(text, isNot(contains('latitude')));
    expect(text, isNot(contains('longitude')));
  });

  test('location identity keeps imports from different cities distinct', () {
    final first = exporter.build(
      schedules: <PrayerDaySchedule>[_day()],
      timeZoneId: 'Europe/Istanbul',
      calendarName: 'Prayer Times',
      calendarId: 'istanbul',
      prayerLabel: (id) => id,
      generatedAt: DateTime.utc(2026, 9, 25, 20),
    );
    final second = exporter.build(
      schedules: <PrayerDaySchedule>[_day()],
      timeZoneId: 'Europe/Istanbul',
      calendarName: 'Prayer Times',
      calendarId: 'ankara',
      prayerLabel: (id) => id,
      generatedAt: DateTime.utc(2026, 9, 25, 20),
    );

    expect(first, contains('UID:istanbul-fajr-20260926@quran-i-kerim.local'));
    expect(second, contains('UID:ankara-fajr-20260926@quran-i-kerim.local'));
  });


  test('calendar identity is safe when a manual location id has separators', () {
    final ics = exporter.build(
      schedules: <PrayerDaySchedule>[_day()],
      timeZoneId: 'Asia/Shanghai',
      calendarName: 'Prayer Times',
      calendarId: 'manual location/1',
      prayerLabel: (id) => id,
      generatedAt: DateTime.utc(2026, 9, 25, 20),
    );

    expect(
      ics,
      contains('UID:manual%20location%2F1-fajr-20260926@quran-i-kerim.local'),
    );
  });

}
