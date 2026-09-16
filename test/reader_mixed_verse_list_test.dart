import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_mixed_verse_list.dart';
import 'package:quran_i_kerim/src/l10n/app_localizations.dart';
import 'package:quran_i_kerim/src/l10n/generated/generated_app_localizations.dart';
import 'package:quran_i_kerim/src/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    settings = AppSettings();
    await settings.load();
  });

  Widget localizedTestApp(Widget child) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      GeneratedAppLocalizations.delegate,
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );

  testWidgets('mixed verse renders Arabic then transliteration then translation', (
    tester,
  ) async {
    const arabic = 'نَصٌّ عَرَبِيٌّ';
    const transliteration = 'Arabic transliteration';
    const translation = 'Selected translation';

    await tester.pumpWidget(
      localizedTestApp(
        SingleChildScrollView(
          child: ReaderMixedVerseList(
            surahNumber: 1,
            verseCount: 1,
            arabicForAyah: (_) => arabic,
            transliterations: const <String, String>{
              '1:1': transliteration,
            },
            translations: const <String, String>{'1:1': translation},
            footnotes: const <String, String>{},
            translationLanguageCode: 'en',
            arabicTextSize: 28,
            translationTextSize: 18,
            arabicLineHeight: 1.8,
            translationLineHeight: 1.5,
            selectedAyahs: const <int>{},
            activeAudioAyah: null,
            settings: settings,
            onAyahTap: (_) {},
            onNoteTap: (_) {},
            onFootnoteTap: (_) {},
          ),
        ),
      ),
    );

    final arabicY = tester.getTopLeft(find.text(arabic)).dy;
    final transliterationY = tester.getTopLeft(find.text(transliteration)).dy;
    final translationY = tester.getTopLeft(find.text(translation)).dy;

    expect(arabicY, lessThan(transliterationY));
    expect(transliterationY, lessThan(translationY));
  });

  testWidgets('mixed verse keeps tap, note, footnote and bookmark affordances', (
    tester,
  ) async {
    await settings.bookmarkSelection(1, const <int>[1]);
    await settings.setNoteForSelection(
      1,
      const <int>[1],
      'note',
      sourceCode: 'RWD',
    );

    var tappedAyah = 0;
    var noteAyah = 0;
    var footnoteAyah = 0;
    await tester.pumpWidget(
      localizedTestApp(
        ReaderMixedVerseList(
          surahNumber: 1,
          verseCount: 1,
          arabicForAyah: (_) => 'Arabic',
          transliterations: const <String, String>{'1:1': 'Latin'},
          translations: const <String, String>{'1:1': 'Translation'},
          footnotes: const <String, String>{'1:1': 'Footnote'},
          translationLanguageCode: 'en',
          arabicTextSize: 28,
          translationTextSize: 18,
          arabicLineHeight: 1.8,
          translationLineHeight: 1.5,
          selectedAyahs: const <int>{},
          activeAudioAyah: null,
          settings: settings,
          onAyahTap: (ayah) => tappedAyah = ayah,
          onNoteTap: (ayah) => noteAyah = ayah,
          onFootnoteTap: (ayah) => footnoteAyah = ayah,
        ),
      ),
    );

    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pump();
    expect(footnoteAyah, 1);

    await tester.tap(find.byIcon(Icons.note_alt_outlined));
    await tester.pump();
    expect(noteAyah, 1);

    await tester.tap(find.text('Translation'));
    await tester.pump();
    expect(tappedAyah, 1);
  });

  testWidgets('state exposes stable ayah positions for reader scroll anchoring', (
    tester,
  ) async {
    final key = GlobalKey<ReaderMixedVerseListState>();
    await tester.pumpWidget(
      localizedTestApp(
        ReaderMixedVerseList(
          key: key,
          surahNumber: 1,
          verseCount: 2,
          arabicForAyah: (ayah) => 'Arabic $ayah',
          transliterations: const <String, String>{
            '1:1': 'Latin 1',
            '1:2': 'Latin 2',
          },
          translations: const <String, String>{
            '1:1': 'Translation 1',
            '1:2': 'Translation 2',
          },
          footnotes: const <String, String>{},
          translationLanguageCode: 'en',
          arabicTextSize: 28,
          translationTextSize: 18,
          arabicLineHeight: 1.8,
          translationLineHeight: 1.5,
          selectedAyahs: const <int>{},
          activeAudioAyah: null,
          settings: settings,
          onAyahTap: (_) {},
          onNoteTap: (_) {},
          onFootnoteTap: (_) {},
        ),
      ),
    );

    final firstY = key.currentState!.globalYForAyah(1);
    final secondY = key.currentState!.globalYForAyah(2);
    expect(firstY, isNotNull);
    expect(secondY, isNotNull);
    expect(secondY!, greaterThan(firstY!));
    expect(key.currentState!.ayahClosestToGlobalY(firstY), 1);
    expect(key.currentState!.ayahClosestToGlobalY(secondY), 2);
  });
}
