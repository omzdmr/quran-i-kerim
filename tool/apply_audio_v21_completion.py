from pathlib import Path
import subprocess

ROOT = Path('.')


def must_replace(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch anchor: {label}')
    return text.replace(old, new, 1)


def write(path: str, text: str) -> None:
    Path(path).write_text(text, encoding='utf-8')


def git_commit(message: str, *paths: str) -> None:
    subprocess.run(['git', 'add', *paths], check=True)
    result = subprocess.run(['git', 'diff', '--cached', '--quiet'])
    if result.returncode == 0:
        print(f'No changes for {message}')
        return
    subprocess.run(['git', 'commit', '-m', message], check=True)

# ---------------------------------------------------------------------------
# Commit 1: custom sleep timer UI + real system media controls integration.
# ---------------------------------------------------------------------------
media_path = 'lib/src/features/reader/reader_media_session.dart'
media = '''import 'package:audio_service/audio_service.dart';

/// Bridges the reader's existing audio engine to Android/iOS system media
/// controls. Audio files remain owned by ReaderAudioController, preserving the
/// local-first cache/offline architecture.
class ReaderMediaSession extends BaseAudioHandler {
  ReaderMediaSession._();

  static ReaderMediaSession? instance;

  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;
  Future<void> Function()? _onPrevious;
  Future<void> Function()? _onNext;
  Future<void> Function(Duration position)? _onSeek;
  Future<void> Function()? _onStop;
  String? _lastMediaKey;

  static Future<void> initialize() async {
    if (instance != null) return;
    await AudioService.init(
      builder: () {
        final handler = ReaderMediaSession._();
        instance = handler;
        return handler;
      },
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.omzdmr.quran_i_kerim.audio',
        androidNotificationChannelName: 'Kur’an sesi',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: false,
      ),
    );
  }

  void attach({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function() onPrevious,
    required Future<void> Function() onNext,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onStop,
  }) {
    _onPlay = onPlay;
    _onPause = onPause;
    _onPrevious = onPrevious;
    _onNext = onNext;
    _onSeek = onSeek;
    _onStop = onStop;
  }

  void clear() {
    _lastMediaKey = null;
    mediaItem.add(null);
    playbackState.add(
      playbackState.value.copyWith(
        controls: const <MediaControl>[],
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  void detach() {
    _onPlay = null;
    _onPause = null;
    _onPrevious = null;
    _onNext = null;
    _onSeek = null;
    _onStop = null;
    clear();
  }

  void publish({
    required int surah,
    required int ayah,
    required int verseCount,
    required String sourceTitle,
    required Duration position,
    required Duration duration,
    required bool playing,
    required bool loading,
    required double speed,
  }) {
    final mediaKey = '$surah:$ayah:$sourceTitle';
    if (_lastMediaKey != mediaKey) {
      _lastMediaKey = mediaKey;
      mediaItem.add(
        MediaItem(
          id: 'quran:$surah:$ayah',
          album: sourceTitle,
          title: 'Kur’an $surah:$ayah',
          artist: '$sourceTitle · Ayet $ayah/$verseCount',
          duration: duration > Duration.zero ? duration : null,
        ),
      );
    } else if (duration > Duration.zero && mediaItem.value?.duration != duration) {
      final current = mediaItem.value;
      if (current != null) mediaItem.add(current.copyWith(duration: duration));
    }

    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const <MediaAction>{MediaAction.seek},
        androidCompactActionIndices: const <int>[0, 1, 2],
        processingState:
            loading ? AudioProcessingState.loading : AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        bufferedPosition: duration,
        speed: speed,
      ),
    );
  }

  @override
  Future<void> play() async => _onPlay?.call();

  @override
  Future<void> pause() async => _onPause?.call();

  @override
  Future<void> skipToPrevious() async => _onPrevious?.call();

  @override
  Future<void> skipToNext() async => _onNext?.call();

  @override
  Future<void> seek(Duration position) async => _onSeek?.call(position);

  @override
  Future<void> stop() async {
    await _onStop?.call();
    clear();
    await super.stop();
  }
}
'''
write(media_path, media)

audio_path = 'lib/src/features/reader/reader_audio_sheet.dart'
audio = Path(audio_path).read_text(encoding='utf-8')
audio = must_replace(
    audio,
    "import 'reader_audio_cache.dart';\n",
    "import 'reader_audio_cache.dart';\nimport 'reader_media_session.dart';\nimport 'reader_sleep_timer.dart';\n",
    'reader imports',
)

audio = must_replace(
    audio,
    "  ReaderAudioController() {\n    _subscriptions.addAll([",
    "  ReaderAudioController() {\n    ReaderMediaSession.instance?.attach(\n      onPlay: () async {\n        if (!_playing) await toggle();\n      },\n      onPause: () async {\n        if (_playing) await _player.pause();\n      },\n      onPrevious: previous,\n      onNext: next,\n      onSeek: seek,\n      onStop: stop,\n    );\n    _subscriptions.addAll([",
    'media attach',
)

start = audio.index('class ReaderAudioController extends ChangeNotifier')
end = audio.index('class ReaderAudioSheet extends StatefulWidget')
controller = audio[start:end]
controller = controller.replace('notifyListeners();', '_notify();')

notify_method = '''  void _notify() {
    final config = _config;
    final session = ReaderMediaSession.instance;
    if (config != null && session != null) {
      session.publish(
        surah: _surah,
        ayah: _ayah,
        verseCount: _verseCount,
        sourceTitle: config.title,
        position: _position,
        duration: _duration,
        playing: _playing,
        loading: _loading,
        speed: _rate,
      );
    }
    notifyListeners();
  }

'''
controller = must_replace(
    controller,
    '  @override\n  void dispose() {',
    notify_method + '  @override\n  void dispose() {',
    'notify method',
)
controller = must_replace(
    controller,
    "    _loading = false;\n    _notify();\n  }\n\n  String _cacheKeyForCurrent()",
    "    _loading = false;\n    _notify();\n    ReaderMediaSession.instance?.clear();\n  }\n\n  String _cacheKeyForCurrent()",
    'clear media on stop',
)
controller = must_replace(
    controller,
    "    _sleepTimer?.cancel();\n    _player.dispose();",
    "    _sleepTimer?.cancel();\n    ReaderMediaSession.instance?.detach();\n    _player.dispose();",
    'detach media',
)
audio = audio[:start] + controller + audio[end:]

custom_method = '''  Future<void> _showCustomTimerDialog(_AudioCopy copy) async {
    final hoursController = TextEditingController(text: '0');
    final minutesController = TextEditingController(text: '30');
    String? validationError;
    final timer = await showDialog<ReaderSleepTimerValue>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(copy.customTimer),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: copy.hours),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: copy.minutesLong),
                    ),
                  ),
                ],
              ),
              if (validationError != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    validationError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(copy.cancel),
            ),
            FilledButton(
              onPressed: () {
                final hours = int.tryParse(hoursController.text.trim()) ?? 0;
                final minutes = int.tryParse(minutesController.text.trim()) ?? 0;
                try {
                  Navigator.pop(
                    dialogContext,
                    ReaderSleepTimerValue.custom(hours: hours, minutes: minutes),
                  );
                } on ArgumentError {
                  setDialogState(() => validationError = copy.invalidTimer);
                }
              },
              child: Text(copy.setTimer),
            ),
          ],
        ),
      ),
    );
    hoursController.dispose();
    minutesController.dispose();
    if (!mounted || timer == null) return;
    widget.controller.setSleepTimer(timer.duration);
  }

'''
audio = must_replace(
    audio,
    '  Future<void> _showNarratorPicker(_AudioCopy copy) async {',
    custom_method + '  Future<void> _showNarratorPicker(_AudioCopy copy) async {',
    'custom timer dialog method',
)

audio = must_replace(
    audio,
    "                      onSelected: (value) {\n                        if (value == 'end') {",
    "                      onSelected: (value) {\n                        if (value == 'custom') {\n                          unawaited(_showCustomTimerDialog(copy));\n                        } else if (value == 'end') {",
    'timer custom selection',
)
audio = must_replace(
    audio,
    "                        for (final minutes in const [10, 20, 30, 45])\n                          PopupMenuItem(\n                            value: '$minutes',\n                            child: Text('$minutes ${copy.minutes}'),\n                          ),\n                        PopupMenuItem(\n                          value: 'end',",
    "                        for (final minutes in const [10, 20, 30, 45])\n                          PopupMenuItem(\n                            value: '$minutes',\n                            child: Text('$minutes ${copy.minutes}'),\n                          ),\n                        PopupMenuItem(\n                          value: 'custom',\n                          child: Text(copy.customTimer),\n                        ),\n                        PopupMenuItem(\n                          value: 'end',",
    'timer custom menu item',
)
audio = must_replace(
    audio,
    "                            : '${controller.sleepMinutes} ${copy.minutes}',",
    "                            : _formatSleepTimer(\n                                controller.sleepMinutes!,\n                                copy,\n                              ),",
    'timer compact label',
)
audio = must_replace(
    audio,
    "String _formatDuration(Duration value) {\n  final minutes = value.inMinutes;\n  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');\n  return '$minutes:$seconds';\n}\n",
    "String _formatDuration(Duration value) {\n  final minutes = value.inMinutes;\n  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');\n  return '$minutes:$seconds';\n}\n\nString _formatSleepTimer(int totalMinutes, _AudioCopy copy) {\n  final hours = totalMinutes ~/ 60;\n  final minutes = totalMinutes % 60;\n  if (hours == 0) return '$minutes ${copy.minutes}';\n  if (minutes == 0) return '$hours ${copy.hoursShort}';\n  return '$hours ${copy.hoursShort} $minutes ${copy.minutes}';\n}\n",
    'sleep timer formatter',
)
audio = must_replace(
    audio,
    "  String get timer =>\n      _pick('Zamanlayıcı', 'Timer', 'المؤقت', 'Taymer', 'Таймер');\n  String get minutes => _pick('dk', 'min', 'د', 'dəq', 'мин');",
    "  String get timer =>\n      _pick('Zamanlayıcı', 'Timer', 'المؤقت', 'Taymer', 'Таймер');\n  String get customTimer => _pick(\n    'Özel süre…',\n    'Custom duration…',\n    'مدة مخصصة…',\n    'Xüsusi müddət…',\n    'Свое время…',\n  );\n  String get hours => _pick('Saat', 'Hours', 'ساعات', 'Saat', 'Часы');\n  String get hoursShort => _pick('sa', 'h', 'س', 's', 'ч');\n  String get minutesLong =>\n      _pick('Dakika', 'Minutes', 'دقائق', 'Dəqiqə', 'Минуты');\n  String get setTimer => _pick(\n    'Zamanlayıcıyı başlat',\n    'Start timer',\n    'بدء المؤقت',\n    'Taymeri başlat',\n    'Запустить таймер',\n  );\n  String get invalidTimer => _pick(\n    '1 dakika ile 24 saat arasında bir süre girin.',\n    'Enter a duration between 1 minute and 24 hours.',\n    'أدخل مدة بين دقيقة واحدة و24 ساعة.',\n    '1 dəqiqə ilə 24 saat arasında müddət daxil edin.',\n    'Введите время от 1 минуты до 24 часов.',\n  );\n  String get minutes => _pick('dk', 'min', 'د', 'dəq', 'мин');",
    'timer copy strings',
)
write(audio_path, audio)

git_commit(
    'Complete custom timer and system media controls',
    media_path,
    audio_path,
)

# ---------------------------------------------------------------------------
# Commit 2: verified human-audio catalog expansion.
# ---------------------------------------------------------------------------
catalog_path = 'lib/src/data/quran_audio_catalog.dart'
catalog = Path(catalog_path).read_text(encoding='utf-8')

replacements = [
    ("providerKey: 'ar.husary',\n    bitrate: 128,\n    style: 'Murattal',",
     "providerKey: 'ar.husary',\n    bitrate: 128,\n    availableBitrates: <int>[64, 128],\n    style: 'Murattal',", 'husary bitrates'),
    ("providerKey: 'ar.sudais',\n    bitrate: 192,",
     "providerKey: 'ar.abdurrahmaansudais',\n    bitrate: 192,\n    availableBitrates: <int>[64, 192],", 'sudais key'),
    ("attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',\n    kind: QuranAudioKind.recitation,\n    provider: QuranAudioProvider.islamicNetwork,\n    providerKey: 'ar.shuraim',\n    bitrate: 128,\n    style: 'Murattal',",
     "attribution: 'Islamic Network · Al Quran Cloud · 64 kbps',\n    kind: QuranAudioKind.recitation,\n    provider: QuranAudioProvider.islamicNetwork,\n    providerKey: 'ar.saoodshuraym',\n    bitrate: 64,\n    style: 'Murattal',", 'shuraim key'),
    ("providerKey: 'ar.abdulbasit',\n    bitrate: 192,\n    style: 'Murattal',",
     "providerKey: 'ar.abdulbasitmurattal',\n    bitrate: 192,\n    availableBitrates: <int>[64, 192],\n    style: 'Murattal',", 'abdul basit key'),
    ("providerKey: 'ar.ajamy',\n    bitrate: 128,",
     "providerKey: 'ar.ahmedajamy',\n    bitrate: 128,\n    availableBitrates: <int>[64, 128],", 'ajamy key'),
    ("providerKey: 'ar.muhammadayoub',\n    bitrate: 128,",
     "providerKey: 'ar.muhammadayyoub',\n    bitrate: 128,", 'ayyoub key'),
    ("providerKey: 'ar.hudhaify',\n    bitrate: 128,",
     "providerKey: 'ar.hudhaify',\n    bitrate: 128,\n    availableBitrates: <int>[32, 64, 128],", 'hudhaify bitrates'),
]
for old, new, label in replacements:
    catalog = must_replace(catalog, old, new, label)

new_reciters = '''  QuranAudioInfo(
    id: 'arabic_recitation_husary_mujawwad',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Mahmoud Khalil Al-Husary',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.husarymujawwad',
    bitrate: 128,
    availableBitrates: <int>[64, 128],
    style: 'Mujawwad',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_maher_muaiqly',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Maher Al Muaiqly',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.mahermuaiqly',
    bitrate: 128,
    availableBitrates: <int>[64, 128],
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_shatri',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Abu Bakr Al-Shatri',
    attribution: 'Islamic Network · Al Quran Cloud · 128 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.shaatree',
    bitrate: 128,
    availableBitrates: <int>[64, 128],
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_abdullah_basfar',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Abdullah Basfar',
    attribution: 'Islamic Network · Al Quran Cloud · 192 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.abdullahbasfar',
    bitrate: 192,
    availableBitrates: <int>[32, 64, 192],
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_hani_rifai',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Hani Ar-Rifai',
    attribution: 'Islamic Network · Al Quran Cloud · 192 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.hanirifai',
    bitrate: 192,
    availableBitrates: <int>[64, 192],
    style: 'Murattal',
  ),
  QuranAudioInfo(
    id: 'arabic_recitation_ayman_sowaid',
    sourceId: arabicOriginalSourceId,
    languageCode: 'ar',
    code: 'AR',
    title: 'Ayman Sowaid',
    attribution: 'Islamic Network · Al Quran Cloud · 64 kbps',
    kind: QuranAudioKind.recitation,
    provider: QuranAudioProvider.islamicNetwork,
    providerKey: 'ar.aymanswoaid',
    bitrate: 64,
    style: 'Murattal',
  ),
'''
catalog = must_replace(
    catalog,
    "  QuranAudioInfo(\n    id: 'english_rwwad_audio',",
    new_reciters + "  QuranAudioInfo(\n    id: 'english_rwwad_audio',",
    'new Arabic reciters',
)

tamil_audio = '''  QuranAudioInfo(
    id: 'tamil_omar_brief_audio',
    sourceId: 'tamil_omar_brief',
    languageCode: 'ta',
    code: 'OMR-TA',
    title: 'தமிழ் மொழிபெயர்ப்பு',
    attribution: 'Shaykh Omar Sharif ibn Abdussalam · QuranEnc.com',
    kind: QuranAudioKind.translation,
    provider: QuranAudioProvider.quranEnc,
    providerKey: 'tamil_omar_brief',
  ),
'''
catalog = must_replace(
    catalog,
    "  QuranAudioInfo(\n    id: 'sinhalese_mahir_audio',",
    tamil_audio + "  QuranAudioInfo(\n    id: 'sinhalese_mahir_audio',",
    'Tamil audio',
)
write(catalog_path, catalog)

translation_path = 'lib/src/data/translation_catalog.dart'
translations = Path(translation_path).read_text(encoding='utf-8')
tamil_translation = '''  TranslationInfo(
    id: 'tamil_omar_brief',
    code: 'OMR-TA',
    languageCode: 'ta',
    name: 'தமிழ் மொழிபெயர்ப்பு - உமர் ஷரீப் - சுருக்கப்பட்ட பதிப்பு',
    publisher: 'Shaykh Omar Sharif ibn Abdussalam',
    source: 'QuranEnc.com',
    sourceKey: 'tamil_omar_brief',
    version: '1.0.2',
    bundled: false,
    available: true,
    downloadable: true,
    hasAudio: true,
  ),
'''
translations = must_replace(
    translations,
    "  TranslationInfo(\n    id: 'sinhalese_mahir',",
    tamil_translation + "  TranslationInfo(\n    id: 'sinhalese_mahir',",
    'Tamil translation',
)
write(translation_path, translations)

test_path = 'test/audio_v2_catalog_test.dart'
tests = Path(test_path).read_text(encoding='utf-8')
tests = must_replace(
    tests,
    "  test('selected bitrate changes URL and persistent storage identity', () {",
    "  test('current Islamic Network reciter keys and qualities are exposed', () {\n    final sudais = quranAudioById('arabic_recitation_sudais');\n    final shuraim = quranAudioById('arabic_recitation_shuraim');\n    final basfar = quranAudioById('arabic_recitation_abdullah_basfar');\n\n    expect(sudais?.providerKey, 'ar.abdurrahmaansudais');\n    expect(quranAudioBitrates(sudais!), <int>[64, 192]);\n    expect(shuraim?.providerKey, 'ar.saoodshuraym');\n    expect(quranAudioBitrates(shuraim!), <int>[64]);\n    expect(quranAudioBitrates(basfar!), <int>[32, 64, 192]);\n  });\n\n  test('Tamil human audio is tied to its exact QuranEnc text source', () {\n    final audio = quranAudioById('tamil_omar_brief_audio');\n    final translation = translationById('tamil_omar_brief');\n\n    expect(audio, isNotNull);\n    expect(audio?.provider, QuranAudioProvider.quranEnc);\n    expect(audio?.providerKey, 'tamil_omar_brief');\n    expect(audio?.sourceId, translation?.id);\n    expect(translation?.hasAudio, isTrue);\n  });\n\n  test('selected bitrate changes URL and persistent storage identity', () {",
    'catalog tests',
)
write(test_path, tests)

git_commit(
    'Expand verified human audio catalog',
    catalog_path,
    translation_path,
    test_path,
)

subprocess.run(['git', 'push', 'origin', 'HEAD:feature/localization-v01'], check=True)
print('Audio v2.1 completion patches pushed.')
