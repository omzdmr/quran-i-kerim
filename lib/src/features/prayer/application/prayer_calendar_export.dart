import 'dart:convert';

import '../domain/prayer_models.dart';

/// RFC 5545 snapshot of calculated starts, not mosque iqamah times or windows.
/// UTC instants preserve each day's timezone/DST conversion from the calculator.
class PrayerCalendarExport {
  static const prayerIds = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  static String build({
    required List<PrayerDaySchedule> schedules,
    required String calendarId,
    required String cityLabel,
    required String description,
    required Map<String, String> labels,
    DateTime? generatedAt,
  }) {
    if (schedules.isEmpty || schedules.length > 31) {
      throw ArgumentError('Export one month at a time.');
    }
    if (prayerIds.any((id) => labels[id]?.trim().isNotEmpty != true)) {
      throw ArgumentError('All five prayer names are required.');
    }
    final stamp = _utc(generatedAt ?? DateTime.now());
    final identity = base64Url.encode(utf8.encode(calendarId));
    final days = <String>{};
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Quran-i-Kerim//Prayer Calendar//EN',
      'CALSCALE:GREGORIAN',
    ];
    for (final schedule in schedules) {
      final date = _date(schedule.localDate);
      if (!days.add(date)) throw ArgumentError('Duplicate calendar day.');
      for (final row in schedule.rows) {
        if (!prayerIds.contains(row.id)) continue;
        lines.addAll([
          'BEGIN:VEVENT',
          'UID:$identity-$date-${row.id}@quran-i-kerim.local',
          'DTSTAMP:$stamp',
          'DTSTART:${_utc(row.time)}',
          // No duration: a start marker, not a claimed prayer validity window.
          'SUMMARY:${_text(labels[row.id]!)}',
          'LOCATION:${_text(cityLabel)}',
          'DESCRIPTION:${_text(description)}',
          'CLASS:PRIVATE',
          'TRANSP:TRANSPARENT',
          // No VALARM: importing must not add another set of adhan reminders.
          'END:VEVENT',
        ]);
      }
    }
    lines.add('END:VCALENDAR');
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}';

  static String _utc(DateTime value) {
    final utc = value.toUtc();
    return '${_date(utc)}T'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}'
        '${utc.second.toString().padLeft(2, '0')}Z';
  }

  static String _text(String value) => value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', r'\n')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,');

  /// Fold at 75 UTF-8 octets, counting continuation whitespace, never inside
  /// a multi-byte character. Calendar readers unfold CRLF + SPACE.
  static String _fold(String line) {
    final result = StringBuffer();
    var bytes = 0;
    for (final rune in line.runes) {
      final character = String.fromCharCode(rune);
      final length = utf8.encode(character).length;
      if (bytes + length > 75) {
        result.write('\r\n ');
        bytes = 1;
      }
      result.write(character);
      bytes += length;
    }
    return result.toString();
  }
}
