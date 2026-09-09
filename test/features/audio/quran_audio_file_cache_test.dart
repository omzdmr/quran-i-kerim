import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/audio/data/quran_audio_file_cache.dart';

void main() {
  late Directory root;
  late QuranAudioFileCache cache;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('quran-audio-cache-test-');
    cache = QuranAudioFileCache(rootDirectory: root);
  });

  tearDown(() async {
    cache.close();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('finds an existing cached ayah regardless of file extension', () async {
    final file = File('${root.path}/ar.alafasy/2/255.m4a');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(<int>[1, 2, 3]);

    final uri = await cache.cachedUri(
      sourceIdentifier: 'ar.alafasy',
      surah: 2,
      ayah: 255,
    );

    expect(uri, file.uri);
  });

  test('ignores empty and partial downloads', () async {
    final directory = Directory('${root.path}/ar.alafasy/1');
    await directory.create(recursive: true);
    await File('${directory.path}/1.mp3').writeAsBytes(const <int>[]);
    await File('${directory.path}/1.mp3.part').writeAsBytes(<int>[1, 2, 3]);

    final uri = await cache.cachedUri(
      sourceIdentifier: 'ar.alafasy',
      surah: 1,
      ayah: 1,
    );

    expect(uri, isNull);
  });

  test('remove deletes only the requested ayah', () async {
    final first = File('${root.path}/en.walk/36/1.mp3');
    final second = File('${root.path}/en.walk/36/2.mp3');
    await first.parent.create(recursive: true);
    await first.writeAsBytes(<int>[1]);
    await second.writeAsBytes(<int>[2]);

    await cache.remove(
      sourceIdentifier: 'en.walk',
      surah: 36,
      ayah: 1,
    );

    expect(await first.exists(), isFalse);
    expect(await second.exists(), isTrue);
  });

  test('clear removes the full audio cache tree', () async {
    final file = File('${root.path}/tr.example/112/1.mp3');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(<int>[1]);

    await cache.clear();

    expect(await root.exists(), isFalse);
  });
}
