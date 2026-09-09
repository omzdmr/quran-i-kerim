import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/audio/data/alquran_cloud_ayah_audio_resolver.dart';
import 'package:quran_i_kerim/src/features/audio/domain/quran_audio_source.dart';

void main() {
  final source = QuranAudioSource(
    identifier: 'ar.alafasy',
    languageCode: 'ar',
    name: 'Alafasy',
    englishName: 'Alafasy',
    kind: QuranAudioKind.quran,
    providerName: 'Al Quran Cloud / Islamic Network',
    providerUri: Uri.parse('https://alquran.cloud/'),
    termsUri: Uri.parse('https://alquran.cloud/terms-and-conditions'),
  );

  test('builds provider ayah endpoint from surah-relative reference', () {
    final uri = AlQuranCloudAyahAudioResolver.requestUri(
      source: source,
      surah: 2,
      ayah: 255,
    );

    expect(
      uri.toString(),
      'https://api.alquran.cloud/v1/ayah/2:255/ar.alafasy',
    );
  });

  test('prefers primary HTTPS audio URL', () {
    final uri = AlQuranCloudAyahAudioResolver.parseAudioUri('''
      {
        "data": {
          "audio": "https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/262",
          "audioSecondary": [
            "https://cdn.islamic.network/quran/audio/128/ar.alafasy/262.mp3"
          ]
        }
      }
    ''');

    expect(
      uri.toString(),
      'https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/262',
    );
  });

  test('falls back to secondary HTTPS URL', () {
    final uri = AlQuranCloudAyahAudioResolver.parseAudioUri('''
      {
        "data": {
          "audio": "http://legacy.example/audio.mp3",
          "audioSecondary": [
            "https://cdn.islamic.network/quran/audio/64/ar.alafasy/262.mp3"
          ]
        }
      }
    ''');

    expect(
      uri.toString(),
      'https://cdn.islamic.network/quran/audio/64/ar.alafasy/262.mp3',
    );
  });

  test('rejects responses without HTTPS audio', () {
    expect(
      () => AlQuranCloudAyahAudioResolver.parseAudioUri(
        '{"data":{"audio":"http://legacy.example/audio.mp3"}}',
      ),
      throwsFormatException,
    );
  });
}
