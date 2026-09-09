import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/audio/domain/quran_audio_track.dart';

void main() {
  test('builds lock-screen metadata for Quran ayah', () {
    final track = QuranAudioTrack(
      id: 'ar.reciter.2.255',
      uri: Uri.parse('https://example.test/002255.mp3'),
      surah: 2,
      ayah: 255,
      surahName: 'Bakara',
      voiceName: 'Test Reciter',
      languageCode: 'ar',
    );

    final item = track.toMediaItem();

    expect(item.title, 'Bakara 2:255');
    expect(item.artist, 'Test Reciter');
    expect(item.album, 'Kur’an-ı Kerim');
    expect(item.extras?['uri'], 'https://example.test/002255.mp3');
    expect(item.extras?['surah'], 2);
    expect(item.extras?['ayah'], 255);
    expect(item.extras?['languageCode'], 'ar');
    expect(item.extras?['translation'], false);
  });

  test('marks human translation audio distinctly in system metadata', () {
    final track = QuranAudioTrack(
      id: 'tr.reader.1.1',
      uri: Uri.parse('file:///cache/tr/001001.mp3'),
      surah: 1,
      ayah: 1,
      surahName: 'Fatiha',
      voiceName: 'Test Meal Reader',
      languageCode: 'tr',
      translation: true,
    );

    final item = track.toMediaItem();

    expect(item.album, 'Kuran Meali');
    expect(item.extras?['translation'], true);
  });
}
