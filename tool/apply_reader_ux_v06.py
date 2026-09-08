from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly 1 match, found {count}')
    return text.replace(old, new, 1)


# ----- Localized surah names -----
Path('lib/src/data/surah_localization.dart').write_text("""import 'package:quran/quran.dart' as quran;

// Azerbaijani conventional display names, kept locally so the reader remains
// offline-first and does not depend on a network lookup for navigation labels.
const _azSurahNames = <String>[
  'Fatihə', 'Bəqərə', 'Ali-İmran', 'Nisa', 'Maidə', 'Ənam', 'Əraf', 'Ənfal',
  'Tövbə', 'Yunus', 'Hud', 'Yusuf', 'Rəd', 'İbrahim', 'Hicr', 'Nəhl', 'İsra',
  'Kəhf', 'Məryəm', 'Taha', 'Ənbiya', 'Həcc', 'Muminun', 'Nur', 'Fürqan',
  'Şüəra', 'Nəml', 'Qəsəs', 'Ənkəbut', 'Rum', 'Loğman', 'Səcdə', 'Əhzab',
  'Səbə', 'Fatir', 'Yasin', 'Saffat', 'Sad', 'Zümər', 'Mumin', 'Füssilət',
  'Şura', 'Züxrüf', 'Düxan', 'Casiyə', 'Əhqaf', 'Mühəmməd', 'Fəth',
  'Hücürat', 'Qaf', 'Zariyat', 'Tur', 'Nəcm', 'Qəmər', 'Rəhman', 'Vaqiə',
  'Hədid', 'Mücadilə', 'Həşr', 'Mümtəhinə', 'Səff', 'Cümə', 'Münafiqun',
  'Təğabün', 'Talaq', 'Təhrim', 'Mülk', 'Qələm', 'Haqqə', 'Məaric', 'Nuh',
  'Cinn', 'Müzzəmmil', 'Müddəssir', 'Qiyamət', 'İnsan', 'Mürsəlat', 'Nəbə',
  'Naziat', 'Əbəsə', 'Təkvir', 'İnfitar', 'Mütəffifin', 'İnşiqaq', 'Büruc',
  'Tariq', 'Əla', 'Ğaşiyə', 'Fəcr', 'Bələd', 'Şəms', 'Leyl', 'Züha',
  'İnşirah', 'Tin', 'Ələq', 'Qədr', 'Bəyyinə', 'Zilzal', 'Adiyat', 'Qariə',
  'Təkasür', 'Əsr', 'Hüməzə', 'Fil', 'Qüreyş', 'Maun', 'Kövsər', 'Kafirun',
  'Nəsr', 'Məsəd', 'İxlas', 'Fələq', 'Nas',
];

String localizedSurahName(int surahNumber, String languageCode) {
  final safe = surahNumber.clamp(1, 114).toInt();
  return switch (languageCode.toLowerCase()) {
    'ar' => quran.getSurahNameArabic(safe),
    'tr' => quran.getSurahNameTurkish(safe),
    'az' => _azSurahNames[safe - 1],
    'ru' => quran.getSurahNameRussian(safe),
    _ => quran.getSurahName(safe),
  };
}

List<String> surahSearchAliases(int surahNumber, String languageCode) {
  final safe = surahNumber.clamp(1, 114).toInt();
  return <String>{
    localizedSurahName(safe, languageCode),
    quran.getSurahName(safe),
    quran.getSurahNameEnglish(safe),
    quran.getSurahNameTurkish(safe),
    quran.getSurahNameRussian(safe),
    quran.getSurahNameArabic(safe),
    _azSurahNames[safe - 1],
  }.toList(growable: false);
}
""", encoding='utf-8')


# ----- Real reader audio controller + sheet -----
Path('lib/src/features/reader/reader_audio_sheet.dart').write_text("""import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/translation_catalog.dart';

class ReaderAudioSourceConfig {
  const ReaderAudioSourceConfig({
    required this.id,
    required this.code,
    required this.title,
    required this.urlForVerse,
  });

  final String id;
  final String code;
  final String title;
  final String Function(int surah, int ayah) urlForVerse;
}

ReaderAudioSourceConfig? readerAudioConfigFor(String sourceId) {
  if (sourceId == arabicOriginalSourceId) {
    return ReaderAudioSourceConfig(
      id: 'arabic_recitation_alafasy',
      code: 'AR',
      title: 'Mishary Rashid Alafasy',
      urlForVerse: (surah, ayah) => quran.getAudioURLByVerse(surah, ayah),
    );
  }

  final info = translationById(sourceId);
  if (info == null || !info.hasAudio || info.sourceKey != 'english_rwwad') {
    return null;
  }

  return ReaderAudioSourceConfig(
    id: info.id,
    code: info.code,
    title: info.name,
    urlForVerse: (surah, ayah) {
      final s = surah.toString().padLeft(3, '0');
      final a = ayah.toString().padLeft(3, '0');
      return 'https://d.quranenc.com/data/audio/${info.sourceKey}/$s$a.mp3';
    },
  );
}

class ReaderAudioController extends ChangeNotifier {
  ReaderAudioController() {
    _subscriptions.addAll([
      _player.onPositionChanged.listen((value) {
        _position = value;
        notifyListeners();
      }),
      _player.onDurationChanged.listen((value) {
        _duration = value;
        notifyListeners();
      }),
      _player.onPlayerStateChanged.listen((value) {
        _playing = value == PlayerState.playing;
        notifyListeners();
      }),
      _player.onPlayerComplete.listen((_) => _onComplete()),
    ]);
  }

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  ReaderAudioSourceConfig? _config;
  int _surah = 1;
  int _ayah = 1;
  int _verseCount = 1;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _rate = 1.0;
  bool _playing = false;
  String? _loadedUrl;
  String? _error;

  ReaderAudioSourceConfig? get config => _config;
  int get surahNumber => _surah;
  int get currentAyah => _ayah;
  int get verseCount => _verseCount;
  Duration get position => _position;
  Duration get duration => _duration;
  double get rate => _rate;
  bool get isPlaying => _playing;
  bool get isConfigured => _config != null;
  String? get error => _error;

  Future<void> configure({
    required ReaderAudioSourceConfig config,
    required int surah,
    required int initialAyah,
    required int verseCount,
  }) async {
    final safeAyah = initialAyah.clamp(1, verseCount).toInt();
    final sourceChanged = _config?.id != config.id || _surah != surah;
    if (sourceChanged) {
      await _player.stop();
      _loadedUrl = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      _playing = false;
    }
    _config = config;
    _surah = surah;
    _verseCount = verseCount;
    if (sourceChanged || !_playing) _ayah = safeAyah;
    _error = null;
    notifyListeners();
  }

  Future<void> toggle() async {
    if (_config == null) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    final url = _config!.urlForVerse(_surah, _ayah);
    if (_loadedUrl == url && _position > Duration.zero) {
      await _player.resume();
      await _player.setPlaybackRate(_rate);
      return;
    }
    await _playCurrent();
  }

  Future<void> previous() async {
    if (_config == null || _ayah <= 1) return;
    final wasPlaying = _playing;
    await _player.stop();
    _ayah--;
    _loadedUrl = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    if (wasPlaying) await _playCurrent();
  }

  Future<void> next() async {
    if (_config == null || _ayah >= _verseCount) return;
    final wasPlaying = _playing;
    await _player.stop();
    _ayah++;
    _loadedUrl = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    if (wasPlaying) await _playCurrent();
  }

  Future<void> seek(Duration value) => _player.seek(value);

  Future<void> setRate(double value) async {
    _rate = value.clamp(.5, 2.0).toDouble();
    if (_playing) await _player.setPlaybackRate(_rate);
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _playing = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _loadedUrl = null;
    notifyListeners();
  }

  Future<void> _playCurrent() async {
    final config = _config;
    if (config == null) return;
    final url = config.urlForVerse(_surah, _ayah);
    try {
      _error = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      _loadedUrl = url;
      notifyListeners();
      await _player.play(UrlSource(url));
      await _player.setPlaybackRate(_rate);
    } catch (_) {
      _playing = false;
      _loadedUrl = null;
      _error = 'audio';
      notifyListeners();
    }
  }

  Future<void> _onComplete() async {
    if (_ayah >= _verseCount) {
      _playing = false;
      _position = _duration;
      notifyListeners();
      return;
    }
    _ayah++;
    _loadedUrl = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    await _playCurrent();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}

class ReaderAudioSheet extends StatefulWidget {
  const ReaderAudioSheet({
    required this.controller,
    required this.surahLabel,
    required this.quickControlsVisible,
    required this.onQuickControlsVisibilityChanged,
    super.key,
  });

  final ReaderAudioController controller;
  final String surahLabel;
  final bool quickControlsVisible;
  final ValueChanged<bool> onQuickControlsVisibilityChanged;

  @override
  State<ReaderAudioSheet> createState() => _ReaderAudioSheetState();
}

class _ReaderAudioSheetState extends State<ReaderAudioSheet> {
  late bool _quickControlsVisible = widget.quickControlsVisible;

  @override
  Widget build(BuildContext context) {
    final copy = _AudioCopy(Localizations.localeOf(context).languageCode);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final durationMs = controller.duration.inMilliseconds;
          final positionMs = controller.position.inMilliseconds
              .clamp(0, durationMs <= 0 ? 0 : durationMs);
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.surahLabel} ${controller.surahNumber}:${controller.currentAyah}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${controller.config?.code ?? ''} · ${controller.config?.title ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: controller.currentAyah > 1
                          ? controller.previous
                          : null,
                      icon: const Icon(Icons.skip_previous_rounded, size: 30),
                      tooltip: copy.previous,
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: IconButton.filled(
                        onPressed: controller.toggle,
                        icon: Icon(
                          controller.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 40,
                        ),
                        tooltip: controller.isPlaying ? copy.pause : copy.play,
                      ),
                    ),
                    const SizedBox(width: 18),
                    IconButton.filledTonal(
                      onPressed: controller.currentAyah < controller.verseCount
                          ? controller.next
                          : null,
                      icon: const Icon(Icons.skip_next_rounded, size: 30),
                      tooltip: copy.next,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Slider(
                  value: durationMs <= 0 ? 0 : positionMs.toDouble(),
                  max: durationMs <= 0 ? 1 : durationMs.toDouble(),
                  onChanged: durationMs <= 0
                      ? null
                      : (value) => controller.seek(
                            Duration(milliseconds: value.round()),
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(_formatDuration(controller.position)),
                      const Spacer(),
                      Text(_formatDuration(controller.duration)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    PopupMenuButton<double>(
                      onSelected: controller.setRate,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: .75, child: Text('0.75x')),
                        PopupMenuItem(value: 1.0, child: Text('1x')),
                        PopupMenuItem(value: 1.25, child: Text('1.25x')),
                        PopupMenuItem(value: 1.5, child: Text('1.5x')),
                        PopupMenuItem(value: 2.0, child: Text('2x')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${controller.rate.toStringAsFixed(controller.rate % 1 == 0 ? 0 : 2)}x',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _quickControlsVisible = !_quickControlsVisible;
                        });
                        widget.onQuickControlsVisibilityChanged(
                          _quickControlsVisible,
                        );
                      },
                      icon: Icon(
                        _quickControlsVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(
                        _quickControlsVisible
                            ? copy.hideButtons
                            : copy.showButtons,
                      ),
                    ),
                  ],
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    copy.audioError,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _AudioCopy {
  const _AudioCopy(this.languageCode);
  final String languageCode;

  String get play =>
      _pick('Oynat', 'Play', 'تشغيل', 'Oxut', 'Воспроизвести');
  String get pause =>
      _pick('Duraklat', 'Pause', 'إيقاف مؤقت', 'Pauza', 'Пауза');
  String get previous => _pick('Önceki ayet', 'Previous verse',
      'الآية السابقة', 'Əvvəlki ayə', 'Предыдущий аят');
  String get next => _pick('Sonraki ayet', 'Next verse', 'الآية التالية',
      'Növbəti ayə', 'Следующий аят');
  String get hideButtons => _pick('Tuşları gizle', 'Hide controls',
      'إخفاء الأزرار', 'Düymələri gizlət', 'Скрыть кнопки');
  String get showButtons => _pick('Tuşları göster', 'Show controls',
      'إظهار الأزرار', 'Düymələri göstər', 'Показать кнопки');
  String get audioError => _pick(
      'Ses açılamadı. Bağlantıyı kontrol edip yeniden deneyin.',
      'Audio could not be opened. Check the connection and try again.',
      'تعذر تشغيل الصوت. تحقق من الاتصال وحاول مجدداً.',
      'Səs açıla bilmədi. Bağlantını yoxlayıb yenidən cəhd edin.',
      'Не удалось открыть аудио. Проверьте соединение и попробуйте снова.');

  String _pick(String tr, String en, String ar, String az, String ru) =>
      switch (languageCode) {
        'tr' => tr,
        'ar' => ar,
        'az' => az,
        'ru' => ru,
        _ => en,
      };
}
""", encoding='utf-8')


# ----- Personal note preview sheet -----
Path('lib/src/features/reader/reader_note_sheet.dart').write_text("""import 'package:flutter/material.dart';

Future<void> showReaderPersonalNotePreview({
  required BuildContext context,
  required String reference,
  required String note,
  required String sourceCode,
  required Future<void> Function() onEdit,
  required VoidCallback onOpenArchive,
}) async {
  final copy = _NoteCopy(Localizations.localeOf(context).languageCode);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    copy.personalNote,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$reference · $sourceCode',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                note,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onOpenArchive();
                    },
                    icon: const Icon(Icons.person_outline_rounded),
                    label: Text(copy.openArchive),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await onEdit();
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(copy.edit),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _NoteCopy {
  const _NoteCopy(this.languageCode);
  final String languageCode;

  String get personalNote => _pick('Kişisel Not', 'Personal Note',
      'ملاحظة شخصية', 'Şəxsi qeyd', 'Личная заметка');
  String get edit =>
      _pick('Düzenle', 'Edit', 'تعديل', 'Redaktə et', 'Изменить');
  String get openArchive => _pick("Siz'de Aç", 'Open in You', 'فتح في ملفك',
      'Siz bölməsində aç', 'Открыть в разделе «Вы»');

  String _pick(String tr, String en, String ar, String az, String ru) =>
      switch (languageCode) {
        'tr' => tr,
        'ar' => ar,
        'az' => az,
        'ru' => ru,
        _ => en,
      };
}
""", encoding='utf-8')


# ----- Translation catalog: only verified spoken translation audio -----
catalog_path = Path('lib/src/data/translation_catalog.dart')
catalog = catalog_path.read_text(encoding='utf-8')
catalog = replace_once(
    catalog,
    "    hasAudio: true,\n  ),\n  TranslationInfo(\n    id: englishTranslationId,",
    "    hasAudio: false,\n  ),\n  TranslationInfo(\n    id: englishTranslationId,",
    'Turkish audio truth',
)
catalog = replace_once(
    catalog,
    "    id: 'azeri_musayev',\n    code: 'MUS-AZ',\n    languageCode: 'az',\n    name: 'Azərbaycan dilinə tərcümə',\n    publisher: 'Əlixan Musayev · Rowwad Translation Center supervision',\n    source: 'QuranEnc.com',\n    sourceKey: 'azeri_musayev',\n    version: '1.0.4',\n    bundled: false,\n    available: true,\n    downloadable: true,\n    hasAudio: true,",
    "    id: 'azeri_musayev',\n    code: 'MUS-AZ',\n    languageCode: 'az',\n    name: 'Azərbaycan dilinə tərcümə',\n    publisher: 'Əlixan Musayev · Rowwad Translation Center supervision',\n    source: 'QuranEnc.com',\n    sourceKey: 'azeri_musayev',\n    version: '1.0.4',\n    bundled: false,\n    available: true,\n    downloadable: true,\n    hasAudio: false,",
    'Azeri audio truth',
)
catalog = replace_once(
    catalog,
    "    id: 'russian_rwwad',\n    code: 'RWD-RU',\n    languageCode: 'ru',\n    name: 'Русский перевод',\n    publisher: 'Rowwad Translation Center',\n    source: 'QuranEnc.com',\n    sourceKey: 'russian_rwwad',\n    version: '1.0.1',\n    bundled: false,\n    available: true,\n    downloadable: true,\n    hasAudio: true,",
    "    id: 'russian_rwwad',\n    code: 'RWD-RU',\n    languageCode: 'ru',\n    name: 'Русский перевод',\n    publisher: 'Rowwad Translation Center',\n    source: 'QuranEnc.com',\n    sourceKey: 'russian_rwwad',\n    version: '1.0.1',\n    bundled: false,\n    available: true,\n    downloadable: true,\n    hasAudio: false,",
    'Russian audio truth',
)
catalog_path.write_text(catalog, encoding='utf-8')


# ----- Persist whether Quran source was explicitly chosen -----
settings_path = Path('lib/src/settings/app_settings.dart')
settings = settings_path.read_text(encoding='utf-8')
settings = replace_once(
    settings,
    "  String _selectedQuranSourceId = bundledTurkishTranslationId;\n  ReaderLineSpacing _readerLineSpacing",
    "  String _selectedQuranSourceId = bundledTurkishTranslationId;\n  bool _quranSourceWasUserSelected = false;\n  ReaderLineSpacing _readerLineSpacing",
    'source explicit field',
)
settings = replace_once(
    settings,
    "  String get selectedQuranSourceId => _selectedQuranSourceId;\n  bool get readerUsesArabic",
    "  String get selectedQuranSourceId => _selectedQuranSourceId;\n  bool get quranSourceWasUserSelected => _quranSourceWasUserSelected;\n  bool get readerUsesArabic",
    'source explicit getter',
)
settings = replace_once(
    settings,
    "    final sourceWasExplicitlySelected =\n        prefs.getBool(_sourceUserSelectedKey) ?? false;\n\n    if (savedSource != null &&\n        savedSource.isNotEmpty &&\n        sourceWasExplicitlySelected) {",
    "    _quranSourceWasUserSelected =\n        prefs.getBool(_sourceUserSelectedKey) ?? false;\n\n    if (savedSource != null &&\n        savedSource.isNotEmpty &&\n        _quranSourceWasUserSelected) {",
    'source explicit load',
)
settings = replace_once(
    settings,
    "      await Future.wait([\n        prefs.setString(_selectedQuranSourceKey, _selectedQuranSourceId),\n        prefs.setBool(_sourceUserSelectedKey, false),\n      ]);",
    "      _quranSourceWasUserSelected = false;\n      await Future.wait([\n        prefs.setString(_selectedQuranSourceKey, _selectedQuranSourceId),\n        prefs.setBool(_sourceUserSelectedKey, false),\n      ]);",
    'source default flag',
)
settings = replace_once(
    settings,
    "    final changed = _selectedQuranSourceId != safe;\n    _selectedQuranSourceId = safe;\n    if (changed) notifyListeners();",
    "    final changed = _selectedQuranSourceId != safe ||\n        !_quranSourceWasUserSelected;\n    _selectedQuranSourceId = safe;\n    _quranSourceWasUserSelected = true;\n    if (changed) notifyListeners();",
    'source explicit selection',
)
settings_path.write_text(settings, encoding='utf-8')


# ----- Home daily verse follows explicit reader source, otherwise UI/device default -----
home_path = Path('lib/src/features/home/home_screen.dart')
home = home_path.read_text(encoding='utf-8')
home = replace_once(
    home,
    "import '../../data/surah_catalog.dart';\nimport '../../data/translation_catalog.dart';",
    "import '../../data/surah_catalog.dart';\nimport '../../data/surah_localization.dart';\nimport '../../data/translation_catalog.dart';",
    'home localized import',
)
home = replace_once(
    home,
    "  Future<String?> _preferredTranslationVerse(String languageCode) async {\n    final sourceId = defaultQuranSourceForLanguage(languageCode);\n    if (sourceId == arabicOriginalSourceId) return null;\n    final verses =\n        await TranslationRepository.instance.loadSourceVerses(sourceId);\n    return verses['${widget.reference.$1}:${widget.reference.$2}'];\n  }\n\n  String _surahNameForLanguage(int surahNumber, String languageCode) =>\n      switch (languageCode) {\n        'ar' => quran.getSurahNameArabic(surahNumber),\n        'tr' => quran.getSurahNameTurkish(surahNumber),\n        'ru' => quran.getSurahNameRussian(surahNumber),\n        _ => quran.getSurahNameEnglish(surahNumber),\n      };",
    "  Future<String?> _preferredTranslationVerse(String sourceId) async {\n    if (sourceId == arabicOriginalSourceId) return null;\n    final verses =\n        await TranslationRepository.instance.loadSourceVerses(sourceId);\n    return verses['${widget.reference.$1}:${widget.reference.$2}'];\n  }\n\n  String _surahNameForLanguage(int surahNumber, String languageCode) =>\n      localizedSurahName(surahNumber, languageCode);",
    'home preferred source helper',
)
home = replace_once(
    home,
    "    final languageCode = l10n.locale.languageCode;\n    final homeSourceId = defaultQuranSourceForLanguage(languageCode);\n    final translation = translationById(homeSourceId);",
    "    final languageCode = l10n.locale.languageCode;\n    final homeSourceId = settings.quranSourceWasUserSelected\n        ? settings.selectedQuranSourceId\n        : defaultQuranSourceForLanguage(languageCode);\n    final translation = translationById(homeSourceId);",
    'home selected source logic',
)
home = replace_once(
    home,
    "                  future: _preferredTranslationVerse(languageCode),",
    "                  future: _preferredTranslationVerse(homeSourceId),",
    'home source future',
)
home_path.write_text(home, encoding='utf-8')


# ----- Reader behavior -----
reader_path = Path('lib/src/features/reader/quran_reader_screen.dart')
reader = reader_path.read_text(encoding='utf-8')
reader = replace_once(
    reader,
    "import '../../data/surah_catalog.dart';\nimport '../../data/translation_catalog.dart';",
    "import '../../data/surah_catalog.dart';\nimport '../../data/surah_localization.dart';\nimport '../../data/translation_catalog.dart';",
    'reader localized import',
)
reader = replace_once(
    reader,
    "import '../settings/quran_translation_catalog_screen.dart';",
    "import '../settings/quran_translation_catalog_screen.dart';\nimport 'reader_audio_sheet.dart';\nimport 'reader_note_sheet.dart';",
    'reader helper imports',
)
reader = replace_once(
    reader,
    "  bool _readerChromeVisible = true;\n  final Set<int> _selectedAyahs",
    "  bool _readerChromeVisible = true;\n  bool _audioQuickControlsVisible = true;\n  double _horizontalDragDistance = 0;\n  int? _lastAudioAyah;\n  late final ReaderAudioController _audioController;\n  final Set<int> _selectedAyahs",
    'reader state',
)
reader = replace_once(
    reader,
    "  void initState() {\n    super.initState();\n    AppNavigation.instance.readerRequest.addListener(_handleReaderRequest);\n  }",
    "  void initState() {\n    super.initState();\n    _audioController = ReaderAudioController();\n    _audioController.addListener(_handleAudioChanged);\n    AppNavigation.instance.readerRequest.addListener(_handleReaderRequest);\n  }\n\n  void _handleAudioChanged() {\n    if (!mounted) return;\n    if (_audioController.isConfigured &&\n        _audioController.surahNumber == _surahNumber &&\n        _lastAudioAyah != _audioController.currentAyah) {\n      _lastAudioAyah = _audioController.currentAyah;\n      WidgetsBinding.instance.addPostFrameCallback((_) {\n        if (!mounted) return;\n        _scheduleScrollToAyah(_audioController.currentAyah);\n        AppSettingsScope.of(context).saveReadingPosition(\n          surah: _surahNumber,\n          ayah: _audioController.currentAyah,\n        );\n      });\n    }\n    setState(() {});\n  }",
    'reader audio init',
)
reader = replace_once(
    reader,
    "    AppNavigation.instance.readerRequest.removeListener(_handleReaderRequest);\n    _scrollController.dispose();",
    "    AppNavigation.instance.readerRequest.removeListener(_handleReaderRequest);\n    _audioController.removeListener(_handleAudioChanged);\n    _audioController.dispose();\n    _scrollController.dispose();",
    'reader audio dispose',
)
reader = replace_once(
    reader,
    "  String _surahName(SurahInfo surah) => switch (_readerLanguageCode()) {\n        'ar' => quran.getSurahNameArabic(surah.number),\n        'tr' => quran.getSurahNameTurkish(surah.number),\n        'ru' => quran.getSurahNameRussian(surah.number),\n        _ => quran.getSurahNameEnglish(surah.number),\n      };",
    "  String _surahName(SurahInfo surah) =>\n      localizedSurahName(surah.number, _readerLanguageCode());",
    'reader localized name',
)
reader = replace_once(
    reader,
    "  String _sourceIdForCode(String code) {\n    if (code == 'AR') return arabicOriginalSourceId;\n    for (final info in translationCatalog) {\n      if (info.code == code) return info.id;\n    }\n    return bundledTurkishTranslationId;\n  }",
    "  String _sourceIdForCode(String code) {\n    if (code == 'AR') return arabicOriginalSourceId;\n    for (final info in translationCatalog) {\n      if (info.code == code) return info.id;\n    }\n    return bundledTurkishTranslationId;\n  }\n\n  ReaderAudioSourceConfig? _audioConfig(AppSettings settings) =>\n      readerAudioConfigFor(settings.selectedQuranSourceId);\n\n  Future<void> _prepareAudio(ReaderAudioSourceConfig config) async {\n    final surah = surahByNumber(_surahNumber);\n    final settings = AppSettingsScope.of(context);\n    await _audioController.configure(\n      config: config,\n      surah: _surahNumber,\n      initialAyah: settings.lastAyah.clamp(1, surah.verseCount).toInt(),\n      verseCount: surah.verseCount,\n    );\n  }\n\n  Future<void> _toggleAudio(ReaderAudioSourceConfig config) async {\n    await _prepareAudio(config);\n    await _audioController.toggle();\n  }\n\n  Future<void> _skipAudio(ReaderAudioSourceConfig config, int delta) async {\n    await _prepareAudio(config);\n    if (delta < 0) {\n      await _audioController.previous();\n    } else {\n      await _audioController.next();\n    }\n  }\n\n  Future<void> _showAudioPlayer(ReaderAudioSourceConfig config) async {\n    await _prepareAudio(config);\n    if (!mounted) return;\n    await showModalBottomSheet<void>(\n      context: context,\n      isScrollControlled: true,\n      showDragHandle: true,\n      builder: (sheetContext) => ReaderAudioSheet(\n        controller: _audioController,\n        surahLabel: _surahName(surahByNumber(_surahNumber)),\n        quickControlsVisible: _audioQuickControlsVisible,\n        onQuickControlsVisibilityChanged: (visible) {\n          if (mounted) setState(() => _audioQuickControlsVisible = visible);\n        },\n      ),\n    );\n  }\n\n  void _setReaderChromeVisible(bool visible) {\n    if (!mounted || _readerChromeVisible == visible) return;\n    final previousOffset =\n        _scrollController.hasClients ? _scrollController.offset : null;\n    setState(() => _readerChromeVisible = visible);\n    if (previousOffset == null) return;\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n      if (!mounted || !_scrollController.hasClients) return;\n      const chromeHeight = 69.0;\n      final adjusted = previousOffset + (visible ? chromeHeight : -chromeHeight);\n      _scrollController.jumpTo(\n        adjusted.clamp(0.0, _scrollController.position.maxScrollExtent),\n      );\n    });\n  }",
    'reader audio/chrome helpers',
)
reader = replace_once(
    reader,
    "    final settings = AppSettingsScope.of(context);\n\n    return SafeArea(",
    "    final settings = AppSettingsScope.of(context);\n    final audioConfig = _audioConfig(settings);\n\n    return SafeArea(",
    'reader audio config build',
)
reader = replace_once(
    reader,
    "                          const SizedBox(width: 4),\n                          IconButton(\n                            onPressed: _showSearch,",
    "                          const SizedBox(width: 4),\n                          if (audioConfig != null)\n                            IconButton(\n                              visualDensity: VisualDensity.compact,\n                              onPressed: () => _showAudioPlayer(audioConfig),\n                              icon: const Icon(Icons.volume_up_outlined, size: 27),\n                              tooltip: l10n.text('listen'),\n                            ),\n                          IconButton(\n                            visualDensity: VisualDensity.compact,\n                            onPressed: _showSearch,",
    'reader speaker button',
)
reader = replace_once(
    reader,
    "                          IconButton(\n                            onPressed: _showReaderMenu,",
    "                          IconButton(\n                            visualDensity: VisualDensity.compact,\n                            onPressed: _showReaderMenu,",
    'reader menu compact',
)
reader = replace_once(
    reader,
    "          Positioned(\n            left: 10,\n            right: 10,\n            bottom: 8,\n            child: IgnorePointer(",
    "          if (_selectedAyahs.isEmpty &&\n              _readerChromeVisible &&\n              audioConfig != null &&\n              _audioQuickControlsVisible)\n            Positioned(\n              left: 74,\n              right: 74,\n              bottom: 82,\n              child: Material(\n                elevation: 8,\n                color: scheme.surfaceContainerHigh,\n                borderRadius: BorderRadius.circular(28),\n                child: SizedBox(\n                  height: 56,\n                  child: Row(\n                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,\n                    children: [\n                      IconButton(\n                        onPressed: () => _skipAudio(audioConfig, -1),\n                        icon: const Icon(Icons.skip_previous_rounded),\n                      ),\n                      IconButton.filled(\n                        onPressed: () => _toggleAudio(audioConfig),\n                        icon: Icon(\n                          _audioController.isPlaying\n                              ? Icons.pause_rounded\n                              : Icons.play_arrow_rounded,\n                        ),\n                      ),\n                      IconButton(\n                        onPressed: () => _skipAudio(audioConfig, 1),\n                        icon: const Icon(Icons.skip_next_rounded),\n                      ),\n                    ],\n                  ),\n                ),\n              ),\n            ),\n          Positioned(\n            left: 10,\n            right: 10,\n            bottom: 8,\n            child: IgnorePointer(",
    'reader quick audio controls',
)
reader = replace_once(
    reader,
    "              if (_readerChromeVisible != shouldShow) {\n                setState(() => _readerChromeVisible = shouldShow);\n              }",
    "              if (_readerChromeVisible != shouldShow) {\n                _setReaderChromeVisible(shouldShow);\n              }",
    'reader chrome setter',
)
reader = replace_once(
    reader,
    "        behavior: HitTestBehavior.translucent,\n        onHorizontalDragEnd: _handleHorizontalReaderSwipe,\n        child: SingleChildScrollView(",
    "        behavior: HitTestBehavior.translucent,\n        onHorizontalDragStart: (_) => _horizontalDragDistance = 0,\n        onHorizontalDragUpdate: (details) {\n          _horizontalDragDistance += details.primaryDelta ?? 0;\n        },\n        onHorizontalDragEnd: _handleHorizontalReaderSwipe,\n        child: SingleChildScrollView(",
    'reader swipe tracking',
)
reader = replace_once(
    reader,
    "  void _handleHorizontalReaderSwipe(DragEndDetails details) {\n    if (_selectedAyahs.isNotEmpty) return;\n    final velocity = details.primaryVelocity ?? 0;\n    if (velocity.abs() < 450) return;\n    if (velocity < 0 && _surahNumber < 114) {",
    "  void _handleHorizontalReaderSwipe(DragEndDetails details) {\n    if (_selectedAyahs.isNotEmpty) return;\n    final distance = _horizontalDragDistance;\n    _horizontalDragDistance = 0;\n    final velocity = details.primaryVelocity ?? 0;\n    if (distance.abs() < 72) return;\n    if (velocity.abs() < 250 && distance.abs() < 110) return;\n    if (distance < 0 && _surahNumber < 114) {",
    'reader swipe threshold',
)
reader = replace_once(
    reader,
    "    } else if (velocity > 0 && _surahNumber > 1) {",
    "    } else if (distance > 0 && _surahNumber > 1) {",
    'reader swipe direction',
)
reader = replace_once(
    reader,
    "    for (final surah in surahCatalog) {\n      final normalizedTr = _normalizeSearch(surah.nameTr);\n      final normalizedAr = _normalizeSearch(surah.nameAr);\n      if (normalizedTr.contains(query) || normalizedAr.contains(query)) {",
    "    for (final surah in surahCatalog) {\n      final normalizedAliases = surahSearchAliases(\n        surah.number,\n        _readerLanguageCode(),\n      ).map(_normalizeSearch).toList(growable: false);\n      if (normalizedAliases.any((name) => name.contains(query))) {",
    'reader search aliases',
)
reader = replace_once(
    reader,
    "      if (query.startsWith('$normalizedTr ')) {\n        final possibleAyah =\n            int.tryParse(query.substring(normalizedTr.length).trim());\n        if (possibleAyah != null &&\n            possibleAyah >= 1 &&\n            possibleAyah <= surah.verseCount) {\n          addResult(\n            _SearchResult(\n              surah: surah.number,\n              ayah: possibleAyah,\n              title: '${_surahName(surah)} ${surah.number}:$possibleAyah',\n              subtitle: searchArabic\n                  ? quran.getVerse(surah.number, possibleAyah)\n                  : translations['${surah.number}:$possibleAyah'] ?? '',\n            ),\n          );\n        }\n      }",
    "      for (final alias in normalizedAliases) {\n        if (!query.startsWith('$alias ')) continue;\n        final possibleAyah =\n            int.tryParse(query.substring(alias.length).trim());\n        if (possibleAyah != null &&\n            possibleAyah >= 1 &&\n            possibleAyah <= surah.verseCount) {\n          addResult(\n            _SearchResult(\n              surah: surah.number,\n              ayah: possibleAyah,\n              title: '${_surahName(surah)} ${surah.number}:$possibleAyah',\n              subtitle: searchArabic\n                  ? quran.getVerse(surah.number, possibleAyah)\n                  : translations['${surah.number}:$possibleAyah'] ?? '',\n            ),\n          );\n        }\n        break;\n      }",
    'reader alias verse search',
)
reader = replace_once(
    reader,
    "              final normalized = query.trim().toLowerCase();\n              final filtered = normalized.isEmpty\n                  ? surahCatalog\n                  : surahCatalog.where((surah) {\n                      final currentName = _surahName(surah).toLowerCase();\n                      return currentName.contains(normalized) ||\n                          quran.getSurahNameEnglish(surah.number)\n                              .toLowerCase()\n                              .contains(normalized) ||\n                          quran.getSurahNameTurkish(surah.number)\n                              .toLowerCase()\n                              .contains(normalized) ||\n                          quran.getSurahNameRussian(surah.number)\n                              .toLowerCase()\n                              .contains(normalized) ||\n                          surah.nameAr.contains(normalized) ||\n                          surah.number.toString() == normalized;\n                    }).toList(growable: false);",
    "              final normalized = _normalizeSearch(query);\n              final filtered = normalized.isEmpty\n                  ? surahCatalog\n                  : surahCatalog.where((surah) {\n                      final aliases = surahSearchAliases(\n                        surah.number,\n                        _readerLanguageCode(),\n                      );\n                      return aliases.any(\n                            (name) => _normalizeSearch(name).contains(normalized),\n                          ) ||\n                          surah.number.toString() == normalized;\n                    }).toList(growable: false);",
    'surah picker localized search',
)
reader = replace_once(
    reader,
    "  Future<void> _openNoteForAyah(int ayah) async {\n    final settings = AppSettingsScope.of(context);\n    final key = settings.noteKeyForAyah(_surahNumber, ayah);\n    if (key == null) return;\n    final ayahs = settings.selectionAyahs(key, _surahNumber);\n    if (ayahs == null || ayahs.isEmpty) return;\n    setState(() {\n      _selectedAyahs\n        ..clear()\n        ..addAll(ayahs);\n    });\n    HapticFeedback.selectionClick();\n    await _editSelectionNote(\n      sourceOverride: settings.noteSourceForKey(key),\n    );\n  }",
    "  Future<void> _openNoteForAyah(int ayah) async {\n    final settings = AppSettingsScope.of(context);\n    final key = settings.noteKeyForAyah(_surahNumber, ayah);\n    if (key == null) return;\n    final ayahs = settings.selectionAyahs(key, _surahNumber);\n    if (ayahs == null || ayahs.isEmpty) return;\n    final sourceCode = settings.noteSourceForKey(key);\n    final note = settings.noteEntries[key] ?? '';\n    final ayahPart = ayahs.length == 1\n        ? '${ayahs.single}'\n        : ayahs.join(',');\n    final reference =\n        '${_surahName(surahByNumber(_surahNumber))} $_surahNumber:$ayahPart';\n    HapticFeedback.selectionClick();\n    await showReaderPersonalNotePreview(\n      context: context,\n      reference: reference,\n      note: note,\n      sourceCode: sourceCode,\n      onOpenArchive: () {\n        AppNavigation.instance.tabRequest.value = 4;\n      },\n      onEdit: () async {\n        if (!mounted) return;\n        setState(() {\n          _selectedAyahs\n            ..clear()\n            ..addAll(ayahs);\n        });\n        AppNavigation.instance.setReaderSelectionActive(true);\n        await _editSelectionNote(sourceOverride: sourceCode);\n      },\n    );\n  }",
    'personal note preview',
)
reader = replace_once(
    reader,
    "          WidgetSpan(\n            alignment: PlaceholderAlignment.baseline,\n            baseline: TextBaseline.alphabetic,\n            child: GestureDetector(\n              behavior: HitTestBehavior.opaque,\n              onTap: () => widget.onNoteTap(ayah),\n              child: Padding(\n                padding: const EdgeInsets.symmetric(horizontal: 4),\n                child: Icon(\n                  Icons.note_alt_outlined,\n                  size: 16,",
    "          WidgetSpan(\n            alignment: PlaceholderAlignment.middle,\n            child: GestureDetector(\n              behavior: HitTestBehavior.opaque,\n              onTap: () => widget.onNoteTap(ayah),\n              child: Padding(\n                padding: const EdgeInsets.symmetric(horizontal: 4),\n                child: Icon(\n                  Icons.note_alt_outlined,\n                  size: 17,",
    'note marker layout',
)
reader = replace_once(
    reader,
    "    final displayName = switch (languageCode) {\n      'ar' => quran.getSurahNameArabic(surah.number),\n      'tr' => quran.getSurahNameTurkish(surah.number),\n      'ru' => quran.getSurahNameRussian(surah.number),\n      _ => quran.getSurahNameEnglish(surah.number),\n    };",
    "    final displayName = localizedSurahName(surah.number, languageCode);",
    'surah row localized name',
)
reader_path.write_text(reader, encoding='utf-8')

reader = reader_path.read_text(encoding='utf-8')
reader = replace_once(
    reader,
    "  void _openSurahAtStart(int surahNumber) {\n    final surah = surahByNumber(surahNumber);",
    "  void _openSurahAtStart(int surahNumber) {\n    _audioController.stop();\n    _lastAudioAyah = null;\n    final surah = surahByNumber(surahNumber);",
    'stop audio on surah swipe',
)
reader = replace_once(
    reader,
    "    if (!mounted || settings.selectedQuranSourceId == before) return;\n    _invalidateTranslationFuture();",
    "    if (!mounted || settings.selectedQuranSourceId == before) return;\n    await _audioController.stop();\n    _lastAudioAyah = null;\n    _invalidateTranslationFuture();",
    'stop audio on source change',
)
reader_path.write_text(reader, encoding='utf-8')


# ----- Dependency -----
pubspec_path = Path('pubspec.yaml')
pubspec = pubspec_path.read_text(encoding='utf-8')
pubspec = replace_once(
    pubspec,
    "  flutter_localizations:\n    sdk: flutter\n  adhan_dart:",
    "  flutter_localizations:\n    sdk: flutter\n  audioplayers: ^6.8.1\n  adhan_dart:",
    'audio dependency',
)
pubspec_path.write_text(pubspec, encoding='utf-8')


# ----- Tests -----
source_test_path = Path('test/app_settings_source_test.dart')
source_test = source_test_path.read_text(encoding='utf-8')
source_test = replace_once(
    source_test,
    "    expect(restored.selectedQuranSourceId, bundledTurkishTranslationId);\n    expect(restored.readerUsesArabic, isFalse);",
    "    expect(restored.selectedQuranSourceId, bundledTurkishTranslationId);\n    expect(restored.quranSourceWasUserSelected, isTrue);\n    expect(restored.readerUsesArabic, isFalse);",
    'explicit source test',
)
source_test_path.write_text(source_test, encoding='utf-8')

Path('test/surah_localization_test.dart').write_text("""import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/surah_localization.dart';

void main() {
  test('reader surah names follow source language', () {
    expect(localizedSurahName(33, 'tr'), 'Ahzâb');
    expect(localizedSurahName(31, 'az'), 'Loğman');
    expect(localizedSurahName(33, 'en').toLowerCase(), contains('ahzab'));
    expect(localizedSurahName(1, 'ar'), 'الفاتحة');
    expect(localizedSurahName(74, 'ru'), isNotEmpty);
  });

  test('search aliases include active and cross-language names', () {
    final aliases = surahSearchAliases(33, 'en').map((e) => e.toLowerCase());
    expect(aliases.any((value) => value.contains('ahzab')), isTrue);
    expect(surahSearchAliases(33, 'az'), contains('Əhzab'));
    expect(surahSearchAliases(33, 'tr'), contains('Ahzâb'));
  });
}
""", encoding='utf-8')


# Restore normal Android CI after the one-off patch, and remove temporary files.
android_path = Path('.github/workflows/android.yml')
android = android_path.read_text(encoding='utf-8')
android = replace_once(
    android,
    "  build:\n    if: github.event.head_commit.message != 'Prepare reader UX v06 patch'\n    runs-on: ubuntu-latest",
    "  build:\n    runs-on: ubuntu-latest",
    'restore Android workflow',
)
android_path.write_text(android, encoding='utf-8')

Path('.github/workflows/oneoff-reader-ux-v06.yml').unlink()
Path('tool/apply_reader_ux_v06.py').unlink()
