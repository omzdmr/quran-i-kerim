import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/prayer_models.dart';

class PrayerCalendarIcsExporter {
  const PrayerCalendarIcsExporter();

  String build({
    required List<PrayerDaySchedule> schedules,
    required String timeZoneId,
    required String calendarName,
    required String calendarId,
    required String Function(String prayerId) prayerLabel,
    DateTime? generatedAt,
  }) {
    final stamp = _utcStamp((generatedAt ?? DateTime.now()).toUtc());
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Quran i Kerim//Prayer Calendar//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:${_escape(calendarName)}',
      'X-WR-TIMEZONE:${_escape(timeZoneId)}',
    ];
    for (final schedule in schedules) {
      for (final row in schedule.rows.where((row) => row.id != 'sunrise')) {
        final start = row.time;
        final end = start.add(const Duration(minutes: 15));
        final date = _date(start);
        lines.addAll(<String>[
          'BEGIN:VEVENT',
          'UID:${Uri.encodeComponent(calendarId)}-${row.id}-$date@quran-i-kerim.local',
          'DTSTAMP:$stamp',
          'DTSTART:${_utcStamp(start)}',
          'DTEND:${_utcStamp(end)}',
          'SUMMARY:${_escape(prayerLabel(row.id))}',
          'TRANSP:TRANSPARENT',
          'STATUS:CONFIRMED',
          'END:VEVENT',
        ]);
      }
    }
    lines.add('END:VCALENDAR');
    return '${lines.join('\r\n')}\r\n';
  }

  String _escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';

  String _localStamp(DateTime value) =>
      '${_date(value)}T${value.hour.toString().padLeft(2, '0')}${value.minute.toString().padLeft(2, '0')}${value.second.toString().padLeft(2, '0')}';

  String _utcStamp(DateTime value) => '${_localStamp(value.toUtc())}Z';
}

class PrayerCalendarExportFileService {
  const PrayerCalendarExportFileService({
    this.exporter = const PrayerCalendarIcsExporter(),
    this.directoryProvider,
  });

  final PrayerCalendarIcsExporter exporter;
  final Future<Directory> Function()? directoryProvider;

  Future<File> createFile({
    required List<PrayerDaySchedule> schedules,
    required String timeZoneId,
    required String calendarName,
    required String calendarId,
    required String Function(String prayerId) prayerLabel,
    required DateTime month,
  }) async {
    final directory = await (directoryProvider ?? getTemporaryDirectory)();
    final monthKey =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final file = File('${directory.path}/prayer-times-$monthKey.ics');
    final content = exporter.build(
      schedules: schedules,
      timeZoneId: timeZoneId,
      calendarName: calendarName,
      calendarId: calendarId,
      prayerLabel: prayerLabel,
    );
    return file.writeAsString(content, flush: true);
  }
}
