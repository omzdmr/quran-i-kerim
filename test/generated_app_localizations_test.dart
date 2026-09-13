import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';

void main() {
  test('generated app title preserves all supported locale values', () async {
    const expected = <String, String>{
      'tr': 'Kur’an-ı Kerim',
      'en': 'Quran',
      'ar': 'القرآن الكريم',
      'az': 'Qurani-Kərim',
      'ru': 'Коран',
    };

    for (final entry in expected.entries) {
      final copy = await GeneratedAppLocalizations.delegate.load(
        Locale(entry.key),
      );
      expect(copy.appTitle, entry.value, reason: entry.key);
    }
  });

  test('generated home prayer units preserve all supported locale values', () async {
    const expected = <String, ({String hour, String minute})>{
      'tr': (hour: 'sa', minute: 'dk'),
      'en': (hour: 'h', minute: 'm'),
      'ar': (hour: 'س', minute: 'د'),
      'az': (hour: 's', minute: 'dəq'),
      'ru': (hour: 'ч', minute: 'мин'),
    };

    for (final entry in expected.entries) {
      final copy = await GeneratedAppLocalizations.delegate.load(
        Locale(entry.key),
      );
      expect(copy.homePrayerHourShort, entry.value.hour, reason: '${entry.key} hour');
      expect(copy.homePrayerMinuteShort, entry.value.minute, reason: '${entry.key} minute');
    }
  });

  test('generated prayer times label preserves all supported locale values', () async {
    const expected = <String, String>{
      'tr': 'Namaz Vakitleri',
      'en': 'Prayer Times',
      'ar': 'مواقيت الصلاة',
      'az': 'Namaz vaxtları',
      'ru': 'Время намаза',
    };

    for (final entry in expected.entries) {
      final copy = await GeneratedAppLocalizations.delegate.load(
        Locale(entry.key),
      );
      expect(copy.prayerTimes, entry.value, reason: entry.key);
    }
  });

  test('generated next prayer label preserves all supported locale values', () async {
    const expected = <String, String>{
      'tr': 'Sıradaki',
      'en': 'Next',
      'ar': 'التالي',
      'az': 'Növbəti',
      'ru': 'Следующий',
    };

    for (final entry in expected.entries) {
      final copy = await GeneratedAppLocalizations.delegate.load(
        Locale(entry.key),
      );
      expect(copy.nextPrayer, entry.value, reason: entry.key);
    }
  });

  test('generated remaining label preserves all supported locale values', () async {
    const expected = <String, String>{
      'tr': 'kaldı',
      'en': 'remaining',
      'ar': 'متبقي',
      'az': 'qalıb',
      'ru': 'осталось',
    };

    for (final entry in expected.entries) {
      final copy = await GeneratedAppLocalizations.delegate.load(
        Locale(entry.key),
      );
      expect(copy.remaining, entry.value, reason: entry.key);
    }
  });

  test('generated passage copy preserves all supported locale values', () async {
    const expected = <String, ({String invalid, String title, String read, String source, String unavailable})>{
      'tr': (
        invalid: 'Geçersiz ayet seçimi',
        title: 'Ayet görünümü',
        read: 'Surenin tamamını oku',
        source: 'Metin kaynağı',
        unavailable: 'Bu metin şu anda cihazda kullanılamıyor.',
      ),
      'en': (
        invalid: 'Invalid passage',
        title: 'Passage',
        read: 'Read the full surah',
        source: 'Text source',
        unavailable: 'This text is not available on this device right now.',
      ),
      'ar': (
        invalid: 'مقطع غير صالح',
        title: 'المقطع',
        read: 'قراءة السورة كاملة',
        source: 'مصدر النص',
        unavailable: 'هذا النص غير متاح على الجهاز حالياً.',
      ),
      'az': (
        invalid: 'Yanlış ayə seçimi',
        title: 'Ayə görünüşü',
        read: 'Surəni tam oxu',
        source: 'Mətn mənbəyi',
        unavailable: 'Bu mətn hazırda cihazda mövcud deyil.',
      ),
      'ru': (
        invalid: 'Недопустимый отрывок',
        title: 'Отрывок',
        read: 'Читать суру полностью',
        source: 'Источник текста',
        unavailable: 'Этот текст сейчас недоступен на устройстве.',
      ),
    };

    for (final entry in expected.entries) {
      final copy = await GeneratedAppLocalizations.delegate.load(
        Locale(entry.key),
      );
      expect(copy.invalidPassage, entry.value.invalid, reason: '${entry.key} invalid');
      expect(copy.passageTitle, entry.value.title, reason: '${entry.key} title');
      expect(copy.passageReadFullSurah, entry.value.read, reason: '${entry.key} read');
      expect(copy.passageTextSource, entry.value.source, reason: '${entry.key} source');
      expect(copy.passageUnavailable, entry.value.unavailable, reason: '${entry.key} unavailable');
    }
  });
}
