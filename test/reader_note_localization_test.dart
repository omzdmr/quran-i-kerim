import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/strings/reader_note_strings.dart';

void main() {
  const locales = <String>['tr', 'en', 'ar', 'az', 'ru'];
  const requiredKeys = <String>{
    'readerPersonalNote',
    'readerEditNote',
    'readerOpenArchive',
    'readerVerseNoteTooltip',
    'readerVerseFootnoteTooltip',
  };

  test('reader note copy keeps five-locale key parity', () {
    for (final locale in locales) {
      final values = readerNoteStrings[locale];
      expect(values, isNotNull, reason: 'Missing reader note locale $locale');
      expect(
        values!.keys.toSet(),
        requiredKeys,
        reason: 'Reader note key drift for $locale',
      );
      for (final key in requiredKeys) {
        expect(values[key]!.trim(), isNotEmpty, reason: '$locale:$key is empty');
      }
    }
  });

  test('reader note copy resolves through AppLocalizations', () {
    expect(
      AppLocalizations(const Locale('tr')).readerPersonalNote,
      'Kişisel Not',
    );
    expect(
      AppLocalizations(const Locale('tr')).readerVerseFootnoteTooltip,
      'Dipnot',
    );
    expect(AppLocalizations(const Locale('en')).readerEditNote, 'Edit');
    expect(
      AppLocalizations(const Locale('ar')).readerOpenArchive,
      'فتح في ملفك',
    );
    expect(
      AppLocalizations(const Locale('ar')).readerVerseNoteTooltip,
      'ملاحظة',
    );
    expect(
      AppLocalizations(const Locale('az')).readerPersonalNote,
      'Şəxsi qeyd',
    );
    expect(
      AppLocalizations(const Locale('az')).readerVerseFootnoteTooltip,
      'Haşiyə',
    );
    expect(
      AppLocalizations(const Locale('ru')).readerEditNote,
      'Изменить',
    );
    expect(
      AppLocalizations(const Locale('ru')).readerVerseNoteTooltip,
      'Заметка',
    );
  });
}
