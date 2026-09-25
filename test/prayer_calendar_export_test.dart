import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/application/prayer_calendar_export.dart';
import 'package:quran_i_kerim/src/features/prayer/domain/prayer_models.dart';

PrayerDaySchedule _day() => PrayerDaySchedule(
      localDate: DateTime(2026, 9, 26),
      fajr: DateTime(2026, 9, 26, 5, 12),
      sunrise: DateTime(2026, 9, 26, 6, 31),
      dhuhr: DateTime(2026, 9, 26, 12, 3),
      asr: DateTime(2026, 9, 26, 15, 19),
      maghrib: DateTime(2026, 9, 26, 18, 2),
      isha: DateTime(2026, 9, 26, 19, 21),
      qiblaDegrees: 240,
    );

void main() {
  const exporter = PrayerCalendarIcsExporter();

  test('exports five prayers with timezone and excludes sunrise', () {
    final ics = exporter.build(
      schedules: <PrayerDaySchedule>[_day()],
      timeZoneId: 'Asia/Shanghai',
      calendarName: 'Prayer Times, Shanghai',
      prayerLabel: (id) => id.toUpperCase(),
      generatedAt: DateTime.utc(2026, 9, 25, 20),
    );

    expect(ics, contains('X-WR-TIMEZONE:Asia/Shanghai'));
    expect(ics, contains('X-WR-CALNAME:Prayer Times\\, Shanghai'));
    expect(ics, contains('DTSTART;TZID=Asia/Shanghai:20260926T051200'));
    expect(ics, contains('SUMMARY:FAJR'));
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
}
