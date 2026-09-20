import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/strings/backup_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/home_quick_action_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/home_recent_reading_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/home_verse_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/learn_catalog_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/learn_reference_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/learn_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/prayer_notification_diagnostics_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/prayer_notification_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/reader_audio_transport_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/reader_media_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/reader_navigation_strings.dart';
import 'package:quran_i_kerim/src/l10n/strings/reader_note_strings.dart';

void main() {
  const locales = <String>['tr', 'en', 'ar', 'az', 'ru', 'fr'];
  const catalogs = <String, Map<String, Map<String, String>>>{
    'backup': backupStrings,
    'home quick actions': homeQuickActionStrings,
    'home recent reading': homeRecentReadingStrings,
    'home verse': homeVerseStrings,
    'learn catalog': learnCatalogStrings,
    'learn reference': learnReferenceStrings,
    'learn': learnStrings,
    'prayer notification diagnostics': prayerNotificationDiagnosticsStrings,
    'prayer notifications': prayerNotificationStrings,
    'reader audio transport': readerAudioTransportStrings,
    'reader media': readerMediaStrings,
    'reader navigation': readerNavigationStrings,
    'reader notes': readerNoteStrings,
  };

  for (final entry in catalogs.entries) {
    test('${entry.key} keeps French and core locale key parity', () {
      final catalog = entry.value;
      final expected = catalog['en']!.keys.toSet();

      expect(catalog.keys, containsAll(locales));

      for (final locale in locales) {
        final values = catalog[locale];
        expect(
          values,
          isNotNull,
          reason: 'Missing ${entry.key} strings for $locale',
        );
        expect(
          values!.keys.toSet(),
          expected,
          reason: '${entry.key} key mismatch for $locale',
        );
        expect(
          values.values.every((value) => value.trim().isNotEmpty),
          isTrue,
          reason: '${entry.key} contains an empty value for $locale',
        );
      }
    });
  }
}
