from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch target: {label}')
    return text.replace(old, new, 1)


prayer = Path('lib/src/features/prayer/presentation/prayer_screen.dart')
text = prayer.read_text(encoding='utf-8')
text = replace_once(
    text,
    '''                      AnimatedRotation(
                        turns: rawDelta / 360,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: Icon(
                          Icons.navigation_rounded,
                          size: 118,
                          color: scheme.primary,
                        ),
                      ),''',
    '''                      Transform.rotate(
                        angle: angle,
                        child: Icon(
                          Icons.navigation_rounded,
                          size: 118,
                          color: scheme.primary,
                        ),
                      ),''',
    'qibla transform rotation',
)
prayer.write_text(text, encoding='utf-8')


audio = Path('lib/src/features/reader/reader_audio_sheet.dart')
text = audio.read_text(encoding='utf-8')
text = replace_once(
    text,
    '''  Future<void> toggle() async {
    if (_config == null) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_loadedCacheKey != _cacheKeyForCurrent() ||
        _position == Duration.zero) {
      await _playCurrent();
      return;
    }
''',
    '''  Future<void> toggle() async {
    if (_config == null) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    final completedSurah = _ayah >= _verseCount &&
        _duration > Duration.zero &&
        _position >= _duration;
    if (completedSurah) {
      await _moveToAyah(1);
      await _playCurrent();
      return;
    }
    if (_loadedCacheKey != _cacheKeyForCurrent() ||
        _position == Duration.zero) {
      await _playCurrent();
      return;
    }
''',
    'replay completed surah from ayah one',
)
audio.write_text(text, encoding='utf-8')
