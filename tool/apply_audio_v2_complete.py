from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch target: {label}')
    return text.replace(old, new, 1)


def regex_once(text: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise SystemExit(f'bad regex patch count {count}: {label}')
    return updated


# pubspec: network transport detection for user-controlled large downloads.
path = Path('pubspec.yaml')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '  audioplayers: ^6.8.1\n',
    '  audioplayers: ^6.8.1\n  connectivity_plus: ^6.1.5\n',
    'connectivity_plus dependency',
)
path.write_text(text, encoding='utf-8')


# Audio catalog: optional verified bitrates + lookup helpers.
path = Path('lib/src/data/quran_audio_catalog.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '    this.bitrate,\n    this.style,\n  });',
    '    this.bitrate,\n    this.availableBitrates = const <int>[],\n    this.style,\n  });',
    'audio constructor bitrates',
)
text = replace_once(
    text,
    '  final int? bitrate;\n  final String? style;',
    '  final int? bitrate;\n  final List<int> availableBitrates;\n  final String? style;',
    'audio field bitrates',
)
text = replace_once(
    text,
    "    providerKey: 'ar.alafasy',\n    bitrate: 128,\n    style: 'Murattal',",
    "    providerKey: 'ar.alafasy',\n    bitrate: 128,\n    availableBitrates: <int>[64, 128],\n    style: 'Murattal',",
    'alafasy verified bitrates',
)
text += """

QuranAudioInfo? quranAudioById(String id) {
  for (final audio in quranAudioCatalog) {
    if (audio.id == id) return audio;
  }
  return null;
}

List<int> quranAudioBitrates(QuranAudioInfo audio) {
  if (audio.availableBitrates.isNotEmpty) {
    final values = audio.availableBitrates.toSet().toList()..sort();
    return values;
  }
  return audio.bitrate == null ? const <int>[] : <int>[audio.bitrate!];
}
"""
path.write_text(text, encoding='utf-8')


# Translation downloader: Al Quran Cloud complete edition = one request, plus bounded 429 retry.
path = Path('lib/src/data/translation_repository.dart')
text = path.read_text(encoding='utf-8')
marker = "class TranslationRepository {"
text = replace_once(
    text,
    marker,
    "Uri islamicNetworkTranslationPackageUri(TranslationInfo info) => Uri.https(\n  'api.alquran.cloud',\n  '/v1/quran/${info.sourceKey}',\n);\n\n" + marker,
    'single package URI helper',
)
new_islamic = r'''  Future<void> _downloadIslamicNetworkTranslation(
    TranslationInfo info, {
    ValueChanged<double>? onProgress,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25)
      ..idleTimeout = const Duration(seconds: 30);
    try {
      onProgress?.call(.03);
      final payload = await _getJson(
        client,
        islamicNetworkTranslationPackageUri(info),
      );
      onProgress?.call(.82);
      if (payload is! Map || payload['data'] is! Map) {
        throw const FormatException('Unexpected Islamic Network Quran response.');
      }
      final data = Map<String, dynamic>.from(payload['data'] as Map);
      final surahs = data['surahs'];
      if (surahs is! List) {
        throw const FormatException('Islamic Network surah list is missing.');
      }

      final items = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final rawSurah in surahs) {
        if (rawSurah is! Map) continue;
        final surah = int.tryParse('${rawSurah['number']}');
        final ayahs = rawSurah['ayahs'];
        if (surah == null || surah < 1 || surah > 114 || ayahs is! List) {
          throw const FormatException('Islamic Network returned an invalid surah.');
        }
        for (final rawAyah in ayahs) {
          if (rawAyah is! Map) continue;
          final ayah = int.tryParse('${rawAyah['numberInSurah']}');
          final translation = rawAyah['text'];
          if (ayah == null || ayah < 1 || translation is! String || translation.trim().isEmpty) {
            throw const FormatException('Islamic Network returned an invalid verse.');
          }
          final key = '$surah:$ayah';
          if (!seen.add(key)) {
            throw FormatException('Islamic Network returned duplicate verse $key.');
          }
          items.add(<String, dynamic>{
            'sura': surah,
            'aya': ayah,
            'translation': translation,
          });
        }
      }

      if (items.length < 6000) {
        throw FormatException(
          'Downloaded translation looks incomplete: ${items.length} verses.',
        );
      }
      onProgress?.call(.92);
      final edition = data['edition'];
      final package = <String, dynamic>{
        'schema_version': 1,
        'source': info.source,
        'source_key': info.sourceKey,
        'language_iso_code': info.languageCode,
        'version': info.version,
        'title': edition is Map ? edition['name'] ?? info.name : info.name,
        'description': info.publisher,
        'terms': const <String, dynamic>{
          'provider': 'Islamic Network / Al Quran Cloud',
          'attribution_required': true,
          'preserve_translation_identity': true,
        },
        'items': items,
      };
      final encoded = utf8.encode(jsonEncode(package));
      final compressed = Uint8List.fromList(gzip.encode(encoded));
      decodeGzipPack(
        compressed,
        fallbackTranslationId: info.id,
        fallbackLanguageCode: info.languageCode,
        fallbackVersion: info.version,
        fallbackSource: info.source,
      );
      final file = await _downloadFile(info.id);
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(compressed, flush: true);
      if (await file.exists()) await file.delete();
      await temp.rename(file.path);
      _downloadedPackFutures.remove(info.id);
      onProgress?.call(1);
    } finally {
      client.close(force: true);
    }
  }

'''
text = regex_once(
    text,
    r'  Future<void> _downloadIslamicNetworkTranslation\(.*?\n  Future<List<Map<String, dynamic>>> _fetchSurah\(',
    new_islamic + '  Future<List<Map<String, dynamic>>> _fetchSurah(',
    'replace Islamic Network multi-surah downloader',
)
new_get_json = r'''  Future<dynamic> _getJson(HttpClient client, Uri uri) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.userAgentHeader, _userAgent)
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set(HttpHeaders.acceptEncodingHeader, 'gzip');
      final response = await request.close();
      if (response.statusCode == HttpStatus.tooManyRequests && attempt < 2) {
        final retryAfter = int.tryParse(
          response.headers.value(HttpHeaders.retryAfterHeader) ?? '',
        );
        await response.drain<void>();
        await Future<void>.delayed(
          Duration(seconds: (retryAfter ?? (attempt + 1) * 2).clamp(1, 8)),
        );
        continue;
      }
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException(
          '${uri.host} returned HTTP ${response.statusCode}.',
          uri: uri,
        );
      }
      final bytes = await response.fold<List<int>>(
        <int>[],
        (buffer, data) => buffer..addAll(data),
      );
      return jsonDecode(utf8.decode(bytes));
    }
    throw HttpException('${uri.host} temporarily rate limited the request.', uri: uri);
  }

'''
text = regex_once(
    text,
    r'  Future<dynamic> _getJson\(.*?\n  List<Map<String, dynamic>> _resultList\(',
    new_get_json + '  List<Map<String, dynamic>> _resultList(',
    'retrying json fetch',
)
text = replace_once(
    text,
    "  Future<void> deleteInstalledTranslation(String sourceId) async {",
    "  Future<int> installedTranslationBytes(String sourceId) async {\n    final info = translationById(sourceId);\n    if (info == null || info.bundled) return 0;\n    final file = await _downloadFile(sourceId);\n    return await file.exists() ? file.length() : 0;\n  }\n\n  Future<void> deleteInstalledTranslation(String sourceId) async {",
    'translation size method',
)
path.write_text(text, encoding='utf-8')


# App settings for quality, network policy and end-of-surah behavior.
path = Path('lib/src/settings/app_settings.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    'enum VerseHighlightColor { yellow, green, blue, orange, pink }\n',
    'enum VerseHighlightColor { yellow, green, blue, orange, pink }\n\nenum AudioAfterSurahBehavior { continueNext, stop }\n',
    'audio behavior enum',
)
text = replace_once(
    text,
    "  static const _selectedAudioBySourceKey = 'selected_audio_by_source_v1';\n",
    "  static const _selectedAudioBySourceKey = 'selected_audio_by_source_v1';\n  static const _selectedAudioBitrateKey = 'selected_audio_bitrate_v1';\n  static const _audioWifiOnlyKey = 'audio_download_wifi_only_v1';\n  static const _audioAskMobileKey = 'audio_download_ask_mobile_v1';\n  static const _audioAfterSurahKey = 'audio_after_surah_v1';\n",
    'audio setting keys',
)
text = replace_once(
    text,
    '  Map<String, String> _selectedAudioBySource = <String, String>{};\n',
    "  Map<String, String> _selectedAudioBySource = <String, String>{};\n  Map<String, String> _selectedAudioBitrate = <String, String>{};\n  bool _audioDownloadWifiOnly = true;\n  bool _audioDownloadAskOnMobile = true;\n  AudioAfterSurahBehavior _audioAfterSurahBehavior =\n      AudioAfterSurahBehavior.continueNext;\n",
    'audio setting fields',
)
text = replace_once(
    text,
    "  String? selectedAudioSourceFor(String sourceId) =>\n      _selectedAudioBySource[sourceId];\n",
    "  String? selectedAudioSourceFor(String sourceId) =>\n      _selectedAudioBySource[sourceId];\n\n  int? selectedAudioBitrateFor(String audioId) =>\n      int.tryParse(_selectedAudioBitrate[audioId] ?? '');\n  bool get audioDownloadWifiOnly => _audioDownloadWifiOnly;\n  bool get audioDownloadAskOnMobile => _audioDownloadAskOnMobile;\n  AudioAfterSurahBehavior get audioAfterSurahBehavior =>\n      _audioAfterSurahBehavior;\n",
    'audio setting getters',
)
text = replace_once(
    text,
    "    _selectedAudioBySource = _decodeStringMap(\n      prefs.getString(_selectedAudioBySourceKey),\n    );\n",
    "    _selectedAudioBySource = _decodeStringMap(\n      prefs.getString(_selectedAudioBySourceKey),\n    );\n    _selectedAudioBitrate = _decodeStringMap(\n      prefs.getString(_selectedAudioBitrateKey),\n    );\n    _audioDownloadWifiOnly = prefs.getBool(_audioWifiOnlyKey) ?? true;\n    _audioDownloadAskOnMobile = prefs.getBool(_audioAskMobileKey) ?? true;\n    _audioAfterSurahBehavior =\n        prefs.getString(_audioAfterSurahKey) == 'stop'\n        ? AudioAfterSurahBehavior.stop\n        : AudioAfterSurahBehavior.continueNext;\n",
    'load audio settings',
)
text = replace_once(
    text,
    "  Future<void> setReaderMode(ReaderDisplayMode mode) => setSelectedQuranSource(\n",
    r'''  Future<void> setSelectedAudioBitrate(String audioId, int bitrate) async {
    final id = audioId.trim();
    if (id.isEmpty || bitrate <= 0) return;
    final value = '$bitrate';
    if (_selectedAudioBitrate[id] == value) return;
    _selectedAudioBitrate[id] = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAudioBitrateKey, jsonEncode(_selectedAudioBitrate));
  }

  Future<void> setAudioDownloadWifiOnly(bool value) async {
    if (_audioDownloadWifiOnly == value) return;
    _audioDownloadWifiOnly = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_audioWifiOnlyKey, value);
  }

  Future<void> setAudioDownloadAskOnMobile(bool value) async {
    if (_audioDownloadAskOnMobile == value) return;
    _audioDownloadAskOnMobile = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_audioAskMobileKey, value);
  }

  Future<void> setAudioAfterSurahBehavior(AudioAfterSurahBehavior value) async {
    if (_audioAfterSurahBehavior == value) return;
    _audioAfterSurahBehavior = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _audioAfterSurahKey,
      value == AudioAfterSurahBehavior.stop ? 'stop' : 'continue',
    );
  }

  Future<void> setReaderMode(ReaderDisplayMode mode) => setSelectedQuranSource(
''',
    'audio setting setters',
)
path.write_text(text, encoding='utf-8')


# Persistent, user-owned offline audio store.
Path('lib/src/features/reader/offline_audio_manager.dart').write_text(r'''import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum AudioNetworkKind { wifi, mobile, offline, other }

enum AudioDownloadStatus { downloading, paused, completed, failed }

class AudioDownloadProgress {
  const AudioDownloadProgress({
    required this.storageKey,
    required this.surah,
    required this.verseCount,
    required this.downloadedAyahs,
    required this.bytes,
    required this.status,
    this.error,
  });

  final String storageKey;
  final int surah;
  final int verseCount;
  final int downloadedAyahs;
  final int bytes;
  final AudioDownloadStatus status;
  final String? error;

  double get fraction => verseCount <= 0 ? 0 : downloadedAyahs / verseCount;
}

class AudioSurahStats {
  const AudioSurahStats({
    required this.storageKey,
    required this.surah,
    required this.verseCount,
    required this.downloadedAyahs,
    required this.bytes,
  });

  final String storageKey;
  final int surah;
  final int verseCount;
  final int downloadedAyahs;
  final int bytes;

  bool get complete => verseCount > 0 && downloadedAyahs >= verseCount;
  bool get partial => downloadedAyahs > 0 && !complete;
}

class OfflineAudioSurah {
  const OfflineAudioSurah({
    required this.storageKey,
    required this.surah,
    required this.downloadedAyahs,
    required this.bytes,
  });

  final String storageKey;
  final int surah;
  final int downloadedAyahs;
  final int bytes;
}

class OfflineAudioManager extends ChangeNotifier {
  OfflineAudioManager._();

  static final OfflineAudioManager instance = OfflineAudioManager._();

  final Map<String, AudioDownloadProgress> _progress =
      <String, AudioDownloadProgress>{};
  final Map<String, _DownloadJob> _jobs = <String, _DownloadJob>{};
  Directory? _rootDirectory;

  String _jobKey(String storageKey, int surah) => '$storageKey|$surah';

  AudioDownloadProgress? progressFor(String storageKey, int surah) =>
      _progress[_jobKey(storageKey, surah)];

  Future<AudioNetworkKind> currentNetworkKind() async {
    final values = await Connectivity().checkConnectivity();
    if (values.contains(ConnectivityResult.wifi) ||
        values.contains(ConnectivityResult.ethernet)) {
      return AudioNetworkKind.wifi;
    }
    if (values.contains(ConnectivityResult.mobile)) {
      return AudioNetworkKind.mobile;
    }
    if (values.isEmpty ||
        values.every((value) => value == ConnectivityResult.none)) {
      return AudioNetworkKind.offline;
    }
    return AudioNetworkKind.other;
  }

  Future<File?> offlineFile({
    required String storageKey,
    required int surah,
    required int ayah,
  }) async {
    final file = await _verseFile(storageKey, surah, ayah);
    if (!await file.exists()) return null;
    if (await file.length() <= 0) {
      await file.delete();
      return null;
    }
    return file;
  }

  Future<bool> isVerseDownloaded({
    required String storageKey,
    required int surah,
    required int ayah,
  }) async =>
      await offlineFile(storageKey: storageKey, surah: surah, ayah: ayah) != null;

  Future<AudioSurahStats> surahStats({
    required String storageKey,
    required int surah,
    required int verseCount,
  }) async {
    final directory = await _surahDirectory(storageKey, surah, create: false);
    if (!await directory.exists()) {
      return AudioSurahStats(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
        downloadedAyahs: 0,
        bytes: 0,
      );
    }
    var count = 0;
    var bytes = 0;
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.mp3')) continue;
      try {
        final length = await entity.length();
        if (length <= 0) continue;
        count++;
        bytes += length;
      } catch (_) {}
    }
    return AudioSurahStats(
      storageKey: storageKey,
      surah: surah,
      verseCount: verseCount,
      downloadedAyahs: count,
      bytes: bytes,
    );
  }

  Future<void> downloadSurah({
    required String storageKey,
    required int surah,
    required int verseCount,
    required String Function(int ayah) urlForAyah,
  }) async {
    final key = _jobKey(storageKey, surah);
    if (_jobs.containsKey(key)) return;
    final job = _DownloadJob();
    _jobs[key] = job;
    var stats = await surahStats(
      storageKey: storageKey,
      surah: surah,
      verseCount: verseCount,
    );
    _progress[key] = AudioDownloadProgress(
      storageKey: storageKey,
      surah: surah,
      verseCount: verseCount,
      downloadedAyahs: stats.downloadedAyahs,
      bytes: stats.bytes,
      status: AudioDownloadStatus.downloading,
    );
    notifyListeners();

    try {
      for (var ayah = 1; ayah <= verseCount; ayah++) {
        if (job.cancelRequested || job.pauseRequested) break;
        final existing = await offlineFile(
          storageKey: storageKey,
          surah: surah,
          ayah: ayah,
        );
        if (existing == null) {
          await _downloadOne(
            file: await _verseFile(storageKey, surah, ayah),
            url: urlForAyah(ayah),
          );
        }
        stats = await surahStats(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
        );
        _progress[key] = AudioDownloadProgress(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
          downloadedAyahs: stats.downloadedAyahs,
          bytes: stats.bytes,
          status: AudioDownloadStatus.downloading,
        );
        notifyListeners();
      }

      if (job.cancelRequested) {
        await _deleteSurahInternal(storageKey, surah);
        _progress.remove(key);
      } else if (job.pauseRequested) {
        stats = await surahStats(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
        );
        _progress[key] = AudioDownloadProgress(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
          downloadedAyahs: stats.downloadedAyahs,
          bytes: stats.bytes,
          status: AudioDownloadStatus.paused,
        );
      } else {
        stats = await surahStats(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
        );
        _progress[key] = AudioDownloadProgress(
          storageKey: storageKey,
          surah: surah,
          verseCount: verseCount,
          downloadedAyahs: stats.downloadedAyahs,
          bytes: stats.bytes,
          status: AudioDownloadStatus.completed,
        );
      }
    } catch (error) {
      stats = await surahStats(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
      );
      _progress[key] = AudioDownloadProgress(
        storageKey: storageKey,
        surah: surah,
        verseCount: verseCount,
        downloadedAyahs: stats.downloadedAyahs,
        bytes: stats.bytes,
        status: AudioDownloadStatus.failed,
        error: '$error',
      );
    } finally {
      _jobs.remove(key);
      notifyListeners();
    }
  }

  void pauseDownload(String storageKey, int surah) {
    _jobs[_jobKey(storageKey, surah)]?.pauseRequested = true;
  }

  void cancelDownload(String storageKey, int surah) {
    _jobs[_jobKey(storageKey, surah)]?.cancelRequested = true;
  }

  Future<void> deleteSurah(String storageKey, int surah) async {
    final job = _jobs[_jobKey(storageKey, surah)];
    if (job != null) job.cancelRequested = true;
    await _deleteSurahInternal(storageKey, surah);
    _progress.remove(_jobKey(storageKey, surah));
    notifyListeners();
  }

  Future<void> deleteSource(String storageKey) async {
    final root = await _root();
    final directory = Directory('${root.path}/${_safe(storageKey)}');
    if (await directory.exists()) await directory.delete(recursive: true);
    _progress.removeWhere((key, _) => key.startsWith('$storageKey|'));
    notifyListeners();
  }

  Future<List<OfflineAudioSurah>> downloadedSurahs() async {
    final root = await _root();
    final result = <OfflineAudioSurah>[];
    await for (final sourceEntity in root.list()) {
      if (sourceEntity is! Directory) continue;
      final storageKey = sourceEntity.path.split(Platform.pathSeparator).last;
      await for (final surahEntity in sourceEntity.list()) {
        if (surahEntity is! Directory) continue;
        final name = surahEntity.path.split(Platform.pathSeparator).last;
        final surah = int.tryParse(name);
        if (surah == null) continue;
        var count = 0;
        var bytes = 0;
        await for (final file in surahEntity.list()) {
          if (file is! File || !file.path.endsWith('.mp3')) continue;
          try {
            final length = await file.length();
            if (length <= 0) continue;
            count++;
            bytes += length;
          } catch (_) {}
        }
        if (count > 0) {
          result.add(
            OfflineAudioSurah(
              storageKey: storageKey,
              surah: surah,
              downloadedAyahs: count,
              bytes: bytes,
            ),
          );
        }
      }
    }
    result.sort((a, b) {
      final source = a.storageKey.compareTo(b.storageKey);
      return source != 0 ? source : a.surah.compareTo(b.surah);
    });
    return result;
  }

  Future<int> totalBytes() async {
    var bytes = 0;
    for (final item in await downloadedSurahs()) {
      bytes += item.bytes;
    }
    return bytes;
  }

  int estimateSurahBytes({required int verseCount, int? bitrate}) {
    final kbps = bitrate ?? 96;
    const averageSecondsPerAyah = 10;
    return ((verseCount * averageSecondsPerAyah * kbps * 1000) / 8).round();
  }

  Future<void> _downloadOne({required File file, required String url}) async {
    final part = File('${file.path}.part');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 20);
    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        final request = await client.getUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.acceptHeader, 'audio/mpeg,*/*;q=0.8');
        final response = await request.close();
        if ((response.statusCode == 429 || response.statusCode >= 500) && attempt < 2) {
          await response.drain<void>();
          await Future<void>.delayed(Duration(seconds: 1 << attempt));
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          await response.drain<void>();
          throw HttpException('Audio download failed with ${response.statusCode}', uri: Uri.parse(url));
        }
        final sink = part.openWrite();
        try {
          await response.pipe(sink);
        } finally {
          await sink.close();
        }
        if (await part.length() <= 0) {
          throw const FileSystemException('Downloaded audio file is empty');
        }
        if (await file.exists()) await file.delete();
        await part.rename(file.path);
        return;
      }
    } finally {
      if (await part.exists()) {
        try {
          await part.delete();
        } catch (_) {}
      }
      client.close(force: true);
    }
  }

  Future<void> _deleteSurahInternal(String storageKey, int surah) async {
    final directory = await _surahDirectory(storageKey, surah, create: false);
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<File> _verseFile(String storageKey, int surah, int ayah) async {
    final directory = await _surahDirectory(storageKey, surah, create: true);
    return File('${directory.path}/${ayah.toString().padLeft(3, '0')}.mp3');
  }

  Future<Directory> _surahDirectory(
    String storageKey,
    int surah, {
    required bool create,
  }) async {
    final root = await _root();
    final directory = Directory(
      '${root.path}/${_safe(storageKey)}/${surah.toString().padLeft(3, '0')}',
    );
    if (create && !await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _safe(String value) => value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<Directory> _root() async {
    final cached = _rootDirectory;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/offline_audio_v1');
    await directory.create(recursive: true);
    _rootDirectory = directory;
    return directory;
  }
}

class _DownloadJob {
  bool pauseRequested = false;
  bool cancelRequested = false;
}
''', encoding='utf-8')


# Temporary cache exposes size and skips prefetch when a permanent offline copy exists.
path = Path('lib/src/features/reader/reader_audio_cache.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    '    required String Function(int ayah) urlForAyah,\n    int windowSize = 4,\n  }) async {',
    '    required String Function(int ayah) urlForAyah,\n    Future<bool> Function(int ayah)? isOfflineAvailable,\n    int windowSize = 4,\n  }) async {',
    'prefetch offline callback signature',
)
text = replace_once(
    text,
    '      final key = cacheKeyFor(sourceId, surah, ayah);\n      final existing = await cachedFile(key);',
    '      if (isOfflineAvailable != null && await isOfflineAvailable(ayah)) {\n        continue;\n      }\n      final key = cacheKeyFor(sourceId, surah, ayah);\n      final existing = await cachedFile(key);',
    'prefetch skip offline',
)
text = replace_once(
    text,
    '  Future<void> clearTemporaryCache() async {',
    r'''  Future<int> temporaryCacheBytes() async {
    final directory = await _directory();
    var total = 0;
    if (!await directory.exists()) return total;
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.mp3')) continue;
      try {
        total += await entity.length();
      } catch (_) {}
    }
    return total;
  }

  Future<void> clearTemporaryCache() async {''',
    'cache size method',
)
path.write_text(text, encoding='utf-8')


# Reader audio: quality-aware config, offline-first playback, sleep timer, next-surah callback.
path = Path('lib/src/features/reader/reader_audio_sheet.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../data/quran_audio_catalog.dart';\nimport 'reader_audio_cache.dart';",
    "import '../../data/quran_audio_catalog.dart';\nimport '../../data/translation_catalog.dart';\nimport '../../data/translation_repository.dart';\nimport '../../settings/app_settings.dart';\nimport 'offline_audio_manager.dart';\nimport 'reader_audio_cache.dart';",
    'audio sheet imports',
)
text = replace_once(
    text,
    '    required this.id,\n    required this.code,\n    required this.title,\n    required this.urlForVerse,\n  });\n\n  final String id;\n  final String code;\n  final String title;\n  final String Function(int surah, int ayah) urlForVerse;',
    '    required this.id,\n    required this.cacheId,\n    required this.sourceId,\n    required this.code,\n    required this.title,\n    required this.urlForVerse,\n    required this.availableBitrates,\n    this.bitrate,\n  });\n\n  final String id;\n  final String cacheId;\n  final String sourceId;\n  final String code;\n  final String title;\n  final int? bitrate;\n  final List<int> availableBitrates;\n  final String Function(int surah, int ayah) urlForVerse;',
    'expanded audio config',
)
text = replace_once(
    text,
    'ReaderAudioSourceConfig? readerAudioConfigFor(\n  String sourceId, {\n  String? audioId,\n}) {',
    'ReaderAudioSourceConfig? readerAudioConfigFor(\n  String sourceId, {\n  String? audioId,\n  int? bitrate,\n}) {',
    'config bitrate parameter',
)
text = replace_once(
    text,
    '  return ReaderAudioSourceConfig(\n    id: audio.id,\n    code: audio.code,',
    "  final bitrates = quranAudioBitrates(audio);\n  final selectedBitrate = bitrate != null && bitrates.contains(bitrate)\n      ? bitrate\n      : audio.bitrate;\n  return ReaderAudioSourceConfig(\n    id: audio.id,\n    cacheId: selectedBitrate == null ? audio.id : '${audio.id}_$selectedBitrate',\n    sourceId: sourceId,\n    code: audio.code,",
    'build bitrate config',
)
text = replace_once(
    text,
    '    title: audio.style == null\n        ? audio.title\n        : \'${audio.title} · ${audio.style}\',\n    urlForVerse: (surah, ayah) {',
    '    title: audio.style == null\n        ? audio.title\n        : \'${audio.title} · ${audio.style}\',\n    bitrate: selectedBitrate,\n    availableBitrates: bitrates,\n    urlForVerse: (surah, ayah) {',
    'config bitrate fields',
)
text = replace_once(
    text,
    '      final bitrate = audio.bitrate ?? 128;\n      return \'https://cdn.islamic.network/quran/audio/$bitrate/${audio.providerKey}/$absolute.mp3\';',
    "      final resolvedBitrate = selectedBitrate ?? audio.bitrate ?? 128;\n      return 'https://cdn.islamic.network/quran/audio/$resolvedBitrate/${audio.providerKey}/$absolute.mp3';",
    'bitrate URL',
)
text = replace_once(
    text,
    '  String? _error;\n',
    '  String? _error;\n  bool _continueAfterSurah = true;\n  Future<bool> Function()? _onRequestNextSurah;\n  Timer? _sleepTimer;\n  int? _sleepMinutes;\n  bool _sleepAtSurahEnd = false;\n',
    'controller new fields',
)
text = replace_once(
    text,
    '  String? get error => _error;\n',
    '  String? get error => _error;\n  int? get sleepMinutes => _sleepMinutes;\n  bool get sleepAtSurahEnd => _sleepAtSurahEnd;\n',
    'controller timer getters',
)
text = replace_once(
    text,
    '    required int verseCount,\n  }) async {',
    '    required int verseCount,\n    bool continueAfterSurah = true,\n    Future<bool> Function()? onRequestNextSurah,\n  }) async {',
    'configure continuation args',
)
text = replace_once(
    text,
    '    final sourceChanged = _config?.id != config.id || _surah != surah;\n',
    '    final sourceChanged = _config?.cacheId != config.cacheId || _surah != surah;\n',
    'config cache identity',
)
text = replace_once(
    text,
    '    _verseCount = verseCount;\n    _error = null;\n',
    '    _verseCount = verseCount;\n    _continueAfterSurah = continueAfterSurah;\n    _onRequestNextSurah = onRequestNextSurah;\n    _error = null;\n',
    'store continuation',
)
text = replace_once(
    text,
    '      sourceId: config.id,\n      surah: _surah,',
    '      sourceId: config.cacheId,\n      surah: _surah,',
    'prefetch cache key',
)
text = replace_once(
    text,
    '      urlForAyah: (ayah) => config.urlForVerse(_surah, ayah),\n      windowSize: 4,',
    '      urlForAyah: (ayah) => config.urlForVerse(_surah, ayah),\n      isOfflineAvailable: (ayah) => OfflineAudioManager.instance.isVerseDownloaded(\n        storageKey: config.cacheId,\n        surah: _surah,\n        ayah: ayah,\n      ),\n      windowSize: 4,',
    'prefetch permanent skip',
)
text = replace_once(
    text,
    '  Future<void> seek(Duration value) => _player.seek(value);\n',
    r'''  Future<void> seek(Duration value) => _player.seek(value);

  void setContinueAfterSurah(bool value) {
    _continueAfterSurah = value;
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepMinutes = null;
    _sleepAtSurahEnd = false;
    if (duration != null && duration > Duration.zero) {
      _sleepMinutes = duration.inMinutes;
      _sleepTimer = Timer(duration, () {
        _sleepTimer = null;
        _sleepMinutes = null;
        _sleepAtSurahEnd = false;
        unawaited(stop());
      });
    }
    notifyListeners();
  }

  void setSleepAtSurahEnd() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepMinutes = null;
    _sleepAtSurahEnd = true;
    notifyListeners();
  }
''',
    'sleep methods',
)
text = replace_once(
    text,
    '    return ReaderAudioCache.instance.cacheKeyFor(config.id, _surah, _ayah);',
    '    return ReaderAudioCache.instance.cacheKeyFor(config.cacheId, _surah, _ayah);',
    'cache key bitrate',
)
text = replace_once(
    text,
    '      config.id,\n      _surah,\n      ayah,',
    '      config.cacheId,\n      _surah,\n      ayah,',
    'play cache key bitrate',
)
text = replace_once(
    text,
    '      final file = await ReaderAudioCache.instance.ensureCached(\n        cacheKey: cacheKey,\n        url: config.urlForVerse(_surah, ayah),\n      );',
    r'''      final offline = await OfflineAudioManager.instance.offlineFile(
        storageKey: config.cacheId,
        surah: _surah,
        ayah: ayah,
      );
      final file = offline ??
          await ReaderAudioCache.instance.ensureCached(
            cacheKey: cacheKey,
            url: config.urlForVerse(_surah, ayah),
          );''',
    'offline-first playback',
)
old_complete = r'''  Future<void> _onComplete() async {
    if (_ayah >= _verseCount) {
      _playing = false;
      _position = _duration;
      notifyListeners();
      return;
    }
'''
new_complete = r'''  Future<void> _onComplete() async {
    if (_ayah >= _verseCount) {
      if (_sleepAtSurahEnd) {
        _sleepAtSurahEnd = false;
        _sleepMinutes = null;
        _playing = false;
        _position = _duration;
        notifyListeners();
        return;
      }
      if (_continueAfterSurah && _onRequestNextSurah != null) {
        final handled = await _onRequestNextSurah!();
        if (handled) return;
      }
      _playing = false;
      _position = _duration;
      notifyListeners();
      return;
    }
'''
text = replace_once(text, old_complete, new_complete, 'surah completion behavior')
text = replace_once(
    text,
    '    _player.dispose();\n    super.dispose();',
    '    _sleepTimer?.cancel();\n    _player.dispose();\n    super.dispose();',
    'dispose sleep timer',
)
text = replace_once(
    text,
    '    required this.onSourceSelected,\n    super.key,\n  });',
    '    required this.onSourceSelected,\n    required this.onBitrateSelected,\n    super.key,\n  });',
    'sheet bitrate callback constructor',
)
text = replace_once(
    text,
    '  final Future<void> Function(String audioId) onSourceSelected;\n',
    '  final Future<void> Function(String audioId) onSourceSelected;\n  final Future<void> Function(int bitrate) onBitrateSelected;\n',
    'sheet bitrate callback field',
)
text = replace_once(
    text,
    'class _ReaderAudioSheetState extends State<ReaderAudioSheet> {\n  late bool _quickControlsVisible = widget.quickControlsVisible;\n',
    r'''class _ReaderAudioSheetState extends State<ReaderAudioSheet> {
  late bool _quickControlsVisible = widget.quickControlsVisible;
  String? _statsKey;
  Future<AudioSurahStats>? _statsFuture;
  bool _installingText = false;
  double _textProgress = 0;

  @override
  void initState() {
    super.initState();
    OfflineAudioManager.instance.addListener(_handleOfflineChanged);
  }

  @override
  void dispose() {
    OfflineAudioManager.instance.removeListener(_handleOfflineChanged);
    super.dispose();
  }

  void _handleOfflineChanged() {
    if (mounted) setState(() {});
  }

  Future<AudioSurahStats> _statsFor(ReaderAudioSourceConfig config) {
    final key = '${config.cacheId}|${widget.controller.surahNumber}|${widget.controller.verseCount}';
    if (_statsKey != key || _statsFuture == null) {
      _statsKey = key;
      _statsFuture = OfflineAudioManager.instance.surahStats(
        storageKey: config.cacheId,
        surah: widget.controller.surahNumber,
        verseCount: widget.controller.verseCount,
      );
    }
    return _statsFuture!;
  }

  void _refreshStats() {
    _statsKey = null;
    _statsFuture = null;
    if (mounted) setState(() {});
  }

  Future<bool> _allowLargeDownload(AppSettings settings, _AudioCopy copy) async {
    final kind = await OfflineAudioManager.instance.currentNetworkKind();
    if (!mounted) return false;
    if (kind == AudioNetworkKind.offline) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.noConnection)));
      return false;
    }
    if (settings.audioDownloadWifiOnly && kind != AudioNetworkKind.wifi) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.wifiRequired)));
      return false;
    }
    if (kind == AudioNetworkKind.mobile && settings.audioDownloadAskOnMobile) {
      return await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(copy.mobileDataTitle),
              content: Text(copy.mobileDataBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(copy.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(copy.download),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  Future<bool> _ensureLinkedTranslation(
    ReaderAudioSourceConfig config,
    _AudioCopy copy,
  ) async {
    final info = translationById(config.sourceId);
    if (info == null || info.bundled || await TranslationRepository.instance.isInstalled(info.id)) {
      return true;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(copy.translationRequiredTitle),
        content: Text('${info.name}\n\n${copy.translationRequiredBody}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(copy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(copy.downloadTranslation),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return false;
    setState(() {
      _installingText = true;
      _textProgress = 0;
    });
    try {
      await TranslationRepository.instance.downloadTranslation(
        info,
        onProgress: (value) {
          if (mounted) setState(() => _textProgress = value);
        },
      );
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(copy.translationDownloadFailed)),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _installingText = false);
    }
  }

  Future<void> _startDownload(
    ReaderAudioSourceConfig config,
    _AudioCopy copy,
  ) async {
    final settings = AppSettingsScope.of(context);
    if (!await _ensureLinkedTranslation(config, copy)) return;
    if (!await _allowLargeDownload(settings, copy)) return;
    _refreshStats();
    unawaited(
      OfflineAudioManager.instance.downloadSurah(
        storageKey: config.cacheId,
        surah: widget.controller.surahNumber,
        verseCount: widget.controller.verseCount,
        urlForAyah: (ayah) => config.urlForVerse(widget.controller.surahNumber, ayah),
      ),
    );
  }
''',
    'sheet state download helpers',
)
# Insert offline/quality controls before playback buttons.
needle = '                const SizedBox(height: 16),\n                Row(\n                  mainAxisAlignment: MainAxisAlignment.center,\n'
insert = r'''                const SizedBox(height: 12),
                if (_installingText) ...[
                  LinearProgressIndicator(value: _textProgress <= 0 ? null : _textProgress),
                  const SizedBox(height: 8),
                  Text(copy.downloadingTranslation),
                  const SizedBox(height: 10),
                ],
                if (controller.config != null)
                  _AudioOfflineSection(
                    config: controller.config!,
                    statsFuture: _statsFor(controller.config!),
                    progress: OfflineAudioManager.instance.progressFor(
                      controller.config!.cacheId,
                      controller.surahNumber,
                    ),
                    estimateBytes: OfflineAudioManager.instance.estimateSurahBytes(
                      verseCount: controller.verseCount,
                      bitrate: controller.config!.bitrate,
                    ),
                    copy: copy,
                    onDownload: () => _startDownload(controller.config!, copy),
                    onPause: () => OfflineAudioManager.instance.pauseDownload(
                      controller.config!.cacheId,
                      controller.surahNumber,
                    ),
                    onCancel: () => OfflineAudioManager.instance.cancelDownload(
                      controller.config!.cacheId,
                      controller.surahNumber,
                    ),
                    onDelete: () async {
                      await OfflineAudioManager.instance.deleteSurah(
                        controller.config!.cacheId,
                        controller.surahNumber,
                      );
                      _refreshStats();
                    },
                  ),
                if (controller.config != null && controller.config!.availableBitrates.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(copy.audioQuality, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      PopupMenuButton<int>(
                        initialValue: controller.config!.bitrate,
                        onSelected: (value) => unawaited(widget.onBitrateSelected(value)),
                        itemBuilder: (_) => [
                          for (final bitrate in controller.config!.availableBitrates)
                            PopupMenuItem<int>(
                              value: bitrate,
                              child: Text(copy.qualityLabel(bitrate)),
                            ),
                        ],
                        child: Chip(label: Text(copy.qualityLabel(controller.config!.bitrate ?? 128))),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
'''
text = replace_once(text, needle, insert, 'offline controls insert')
# Replace bottom utility row with rate + timer + after-surah + visibility in wrap.
old_row = r'''                Row(
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
'''
new_row = r'''                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                      child: Chip(
                        avatar: const Icon(Icons.speed_rounded, size: 17),
                        label: Text('${controller.rate.toStringAsFixed(controller.rate % 1 == 0 ? 0 : 2)}x'),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'end') {
                          controller.setSleepAtSurahEnd();
                        } else if (value == 'off') {
                          controller.setSleepTimer(null);
                        } else {
                          controller.setSleepTimer(Duration(minutes: int.parse(value)));
                        }
                      },
                      itemBuilder: (_) => [
                        for (final minutes in const [10, 20, 30, 45])
                          PopupMenuItem(value: '$minutes', child: Text('$minutes ${copy.minutes}')),
                        PopupMenuItem(value: 'end', child: Text(copy.endOfSurah)),
                        PopupMenuItem(value: 'off', child: Text(copy.off)),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.bedtime_outlined, size: 17),
                        label: Text(
                          controller.sleepAtSurahEnd
                              ? copy.endOfSurah
                              : controller.sleepMinutes == null
                                  ? copy.timer
                                  : '${controller.sleepMinutes} ${copy.minutes}',
                        ),
                      ),
                    ),
                    PopupMenuButton<AudioAfterSurahBehavior>(
                      initialValue: AppSettingsScope.of(context).audioAfterSurahBehavior,
                      onSelected: (value) async {
                        final settings = AppSettingsScope.of(context);
                        await settings.setAudioAfterSurahBehavior(value);
                        controller.setContinueAfterSurah(value == AudioAfterSurahBehavior.continueNext);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: AudioAfterSurahBehavior.continueNext,
                          child: Text(copy.continueNextSurah),
                        ),
                        PopupMenuItem(
                          value: AudioAfterSurahBehavior.stop,
                          child: Text(copy.stopAtSurahEnd),
                        ),
                      ],
                      child: Chip(
                        avatar: const Icon(Icons.queue_music_rounded, size: 17),
                        label: Text(
                          AppSettingsScope.of(context).audioAfterSurahBehavior == AudioAfterSurahBehavior.continueNext
                              ? copy.continueNext
                              : copy.stop,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _quickControlsVisible = !_quickControlsVisible);
                        widget.onQuickControlsVisibilityChanged(_quickControlsVisible);
                      },
                      icon: Icon(
                        _quickControlsVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(_quickControlsVisible ? copy.hideButtons : copy.showButtons),
                    ),
                  ],
                ),
'''
text = replace_once(text, old_row, new_row, 'player utility controls')
# Add offline section widget before duration formatter.
needle = '\nString _formatDuration(Duration value) {'
widget_code = r'''
class _AudioOfflineSection extends StatelessWidget {
  const _AudioOfflineSection({
    required this.config,
    required this.statsFuture,
    required this.progress,
    required this.estimateBytes,
    required this.copy,
    required this.onDownload,
    required this.onPause,
    required this.onCancel,
    required this.onDelete,
  });

  final ReaderAudioSourceConfig config;
  final Future<AudioSurahStats> statsFuture;
  final AudioDownloadProgress? progress;
  final int estimateBytes;
  final _AudioCopy copy;
  final VoidCallback onDownload;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final live = progress;
    if (live != null && live.status == AudioDownloadStatus.downloading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('${copy.downloading} ${live.downloadedAyahs}/${live.verseCount}', style: const TextStyle(fontWeight: FontWeight.w800))),
                IconButton(onPressed: onPause, icon: const Icon(Icons.pause_rounded), tooltip: copy.pauseDownload),
                IconButton(onPressed: onCancel, icon: const Icon(Icons.close_rounded), tooltip: copy.cancel),
              ],
            ),
            LinearProgressIndicator(value: live.fraction.clamp(0, 1)),
          ],
        ),
      );
    }
    return FutureBuilder<AudioSurahStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final complete = live?.status == AudioDownloadStatus.completed || (stats?.complete ?? false);
        final partial = live?.status == AudioDownloadStatus.paused ||
            live?.status == AudioDownloadStatus.failed ||
            (stats?.partial ?? false);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(complete ? Icons.offline_pin_rounded : Icons.download_for_offline_outlined, color: complete ? scheme.primary : null),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? copy.offline : partial ? copy.resumeDownload : copy.downloadSurah,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      complete
                          ? _formatBytes(stats?.bytes ?? live?.bytes ?? 0)
                          : partial
                              ? '${stats?.downloadedAyahs ?? live?.downloadedAyahs ?? 0}/${stats?.verseCount ?? live?.verseCount ?? 0} · ${copy.resumeHint}'
                              : '${copy.estimated} ${_formatBytes(estimateBytes)}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (complete)
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded), tooltip: copy.delete)
              else
                FilledButton.tonal(onPressed: onDownload, child: Text(partial ? copy.resume : copy.download)),
            ],
          ),
        );
      },
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
'''
text = replace_once(text, needle, widget_code + needle, 'offline widget')
# Extend copy.
text = replace_once(
    text,
    '  String get audioError => _pick(',
    r'''  String get downloadSurah => _pick('Bu sureyi indir', 'Download this surah', 'تنزيل هذه السورة', 'Bu surəni endir', 'Скачать эту суру');
  String get download => _pick('İndir', 'Download', 'تنزيل', 'Endir', 'Скачать');
  String get downloading => _pick('İndiriliyor', 'Downloading', 'جارٍ التنزيل', 'Endirilir', 'Загрузка');
  String get offline => _pick('Offline hazır', 'Available offline', 'متاح دون اتصال', 'Oflayn hazırdır', 'Доступно офлайн');
  String get resume => _pick('Devam et', 'Resume', 'متابعة', 'Davam et', 'Продолжить');
  String get resumeDownload => _pick('İndirmeye devam et', 'Resume download', 'متابعة التنزيل', 'Endirməyə davam et', 'Продолжить загрузку');
  String get resumeHint => _pick('kaldığı yerden devam eder', 'continues where it stopped', 'يتابع من حيث توقف', 'qaldığı yerdən davam edir', 'продолжит с места остановки');
  String get pauseDownload => _pick('İndirmeyi duraklat', 'Pause download', 'إيقاف التنزيل مؤقتًا', 'Endirməni dayandır', 'Приостановить загрузку');
  String get delete => _pick('Sil', 'Delete', 'حذف', 'Sil', 'Удалить');
  String get cancel => _pick('İptal', 'Cancel', 'إلغاء', 'Ləğv et', 'Отмена');
  String get estimated => _pick('Yaklaşık', 'About', 'تقريبًا', 'Təxminən', 'Примерно');
  String get audioQuality => _pick('Ses kalitesi', 'Audio quality', 'جودة الصوت', 'Səs keyfiyyəti', 'Качество аудио');
  String qualityLabel(int bitrate) => bitrate <= 64
      ? _pick('Veri tasarrufu · $bitrate kbps', 'Data saver · $bitrate kbps', 'توفير البيانات · $bitrate kbps', 'Məlumat qənaəti · $bitrate kbps', 'Экономия данных · $bitrate kbps')
      : _pick('Standart · $bitrate kbps', 'Standard · $bitrate kbps', 'قياسي · $bitrate kbps', 'Standart · $bitrate kbps', 'Стандарт · $bitrate kbps');
  String get timer => _pick('Zamanlayıcı', 'Timer', 'المؤقت', 'Taymer', 'Таймер');
  String get minutes => _pick('dk', 'min', 'د', 'dəq', 'мин');
  String get endOfSurah => _pick('Sure bitince', 'End of surah', 'عند نهاية السورة', 'Surə bitəndə', 'В конце суры');
  String get off => _pick('Kapalı', 'Off', 'إيقاف', 'Söndürülüb', 'Выкл.');
  String get continueNext => _pick('Devam', 'Continue', 'متابعة', 'Davam', 'Продолжить');
  String get stop => _pick('Dur', 'Stop', 'توقف', 'Dayan', 'Стоп');
  String get continueNextSurah => _pick('Sonraki sureye devam et', 'Continue to next surah', 'المتابعة إلى السورة التالية', 'Növbəti surəyə davam et', 'Продолжить следующую суру');
  String get stopAtSurahEnd => _pick('Sure bitince dur', 'Stop at end of surah', 'توقف عند نهاية السورة', 'Surə bitəndə dayan', 'Остановиться в конце суры');
  String get noConnection => _pick('İnternet bağlantısı yok.', 'No internet connection.', 'لا يوجد اتصال بالإنترنت.', 'İnternet bağlantısı yoxdur.', 'Нет подключения к интернету.');
  String get wifiRequired => _pick('Büyük indirmeler yalnızca Wi‑Fi ile açık. İndirilenler ayarından değiştirebilirsin.', 'Large downloads are Wi‑Fi only. Change it in Downloads settings.', 'التنزيلات الكبيرة عبر Wi‑Fi فقط.', 'Böyük endirmələr yalnız Wi‑Fi üçündür.', 'Большие загрузки разрешены только по Wi‑Fi.');
  String get mobileDataTitle => _pick('Mobil veri kullanılsın mı?', 'Use mobile data?', 'استخدام بيانات الهاتف؟', 'Mobil data istifadə edilsin?', 'Использовать мобильные данные?');
  String get mobileDataBody => _pick('Ses dosyaları büyük olabilir. Bu sureyi mobil veri ile indirmek istiyor musun?', 'Audio files can be large. Download this surah over mobile data?', 'قد تكون ملفات الصوت كبيرة. هل تريد التنزيل عبر بيانات الهاتف؟', 'Səs faylları böyük ola bilər. Mobil data ilə endirilsin?', 'Аудиофайлы могут быть большими. Скачать через мобильную сеть?');
  String get translationRequiredTitle => _pick('Meal metni gerekli', 'Translation text required', 'نص الترجمة مطلوب', 'Tərcümə mətni lazımdır', 'Нужен текст перевода');
  String get translationRequiredBody => _pick('Bu ses yalnız kendi meal metniyle kullanılabilir. Önce eşleşen meal indirilecek.', 'This audio can only be used with its matching translation. The matching text will be downloaded first.', 'لا يمكن استخدام هذا الصوت إلا مع ترجمته المطابقة.', 'Bu səs yalnız uyğun tərcümə ilə istifadə olunur.', 'Это аудио используется только с соответствующим переводом.');
  String get downloadTranslation => _pick('Meali indir', 'Download translation', 'تنزيل الترجمة', 'Tərcüməni endir', 'Скачать перевод');
  String get downloadingTranslation => _pick('Eşleşen meal indiriliyor…', 'Downloading matching translation…', 'جارٍ تنزيل الترجمة المطابقة…', 'Uyğun tərcümə endirilir…', 'Загружается соответствующий перевод…');
  String get translationDownloadFailed => _pick('Meal indirilemedi. Bağlantıyı kontrol edip tekrar dene.', 'Translation could not be downloaded. Check the connection and try again.', 'تعذر تنزيل الترجمة.', 'Tərcümə endirilə bilmədi.', 'Не удалось скачать перевод.');
  String get audioError => _pick(''',
    'audio copy additions',
)
path.write_text(text, encoding='utf-8')


# Reader integration: persisted quality and automatic next-surah playback.
path = Path('lib/src/features/reader/quran_reader_screen.dart')
text = path.read_text(encoding='utf-8')
old_config = r'''  ReaderAudioSourceConfig? _audioConfig(AppSettings settings) =>
      readerAudioConfigFor(
        settings.selectedQuranSourceId,
        audioId: settings.selectedAudioSourceFor(
          settings.selectedQuranSourceId,
        ),
      );
'''
new_config = r'''  ReaderAudioSourceConfig? _audioConfig(AppSettings settings) {
    final sourceId = settings.selectedQuranSourceId;
    final audioId = settings.selectedAudioSourceFor(sourceId);
    return readerAudioConfigFor(
      sourceId,
      audioId: audioId,
      bitrate: audioId == null ? null : settings.selectedAudioBitrateFor(audioId),
    );
  }
'''
text = replace_once(text, old_config, new_config, 'reader audio config quality')
# Add continuation args to all three known configure calls in this section.
text = text.replace(
    '      verseCount: surah.verseCount,\n    );',
    '      verseCount: surah.verseCount,\n      continueAfterSurah: settings.audioAfterSurahBehavior ==\n          AudioAfterSurahBehavior.continueNext,\n      onRequestNextSurah: _continueAudioToNextSurah,\n    );',
    2,
)
# selectAudioSource configure has settings in scope and same snippet later; patch separately via nearby initialAyah.
text = replace_once(
    text,
    '      initialAyah: currentAyah.clamp(1, surah.verseCount).toInt(),\n      verseCount: surah.verseCount,\n    );\n    if (mounted) setState(() {});\n  }\n\n  Future<void> _showAudioPlayer',
    '      initialAyah: currentAyah.clamp(1, surah.verseCount).toInt(),\n      verseCount: surah.verseCount,\n      continueAfterSurah: settings.audioAfterSurahBehavior ==\n          AudioAfterSurahBehavior.continueNext,\n      onRequestNextSurah: _continueAudioToNextSurah,\n    );\n    if (mounted) setState(() {});\n  }\n\n  Future<void> _selectAudioBitrate(int bitrate) async {\n    final settings = AppSettingsScope.of(context);\n    final sourceId = settings.selectedQuranSourceId;\n    final audioId = _audioController.config?.id ??\n        settings.selectedAudioSourceFor(sourceId) ??\n        quranAudioForSource(sourceId).firstOrNull?.id;\n    if (audioId == null) return;\n    final currentAyah = _audioController.isConfigured\n        ? _audioController.currentAyah\n        : 1;\n    final wasPlaying = _audioController.isPlaying;\n    await settings.setSelectedAudioBitrate(audioId, bitrate);\n    final config = readerAudioConfigFor(sourceId, audioId: audioId, bitrate: bitrate);\n    if (config == null) return;\n    final surah = surahByNumber(_surahNumber);\n    await _audioController.configure(\n      config: config,\n      surah: _surahNumber,\n      initialAyah: currentAyah.clamp(1, surah.verseCount).toInt(),\n      verseCount: surah.verseCount,\n      continueAfterSurah: settings.audioAfterSurahBehavior ==\n          AudioAfterSurahBehavior.continueNext,\n      onRequestNextSurah: _continueAudioToNextSurah,\n    );\n    if (wasPlaying) await _audioController.toggle();\n    if (mounted) setState(() {});\n  }\n\n  Future<bool> _continueAudioToNextSurah() async {\n    if (!mounted || _surahNumber >= 114) return false;\n    final config = _audioController.config;\n    if (config == null) return false;\n    final next = surahByNumber(_surahNumber + 1);\n    final settings = AppSettingsScope.of(context);\n    setState(() {\n      _surahNumber = next.number;\n      _anchorAyah = 1;\n      _visibleAyah = 1;\n      _selectedAyahs.clear();\n      _lastAudioAyah = null;\n    });\n    AppNavigation.instance.setReaderSelectionActive(false);\n    await settings.saveReadingPosition(surah: next.number, ayah: 1);\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n      if (mounted && _scrollController.hasClients) _scrollController.jumpTo(0);\n    });\n    await _audioController.configure(\n      config: config,\n      surah: next.number,\n      initialAyah: 1,\n      verseCount: next.verseCount,\n      continueAfterSurah: settings.audioAfterSurahBehavior ==\n          AudioAfterSurahBehavior.continueNext,\n      onRequestNextSurah: _continueAudioToNextSurah,\n    );\n    await _audioController.toggle();\n    return true;\n  }\n\n  Future<void> _showAudioPlayer',
    'reader bitrate/continue methods',
)
# Dart Iterable has no firstOrNull without collection; replace with safe candidates expression.
text = text.replace(
    "    final audioId = _audioController.config?.id ??\n        settings.selectedAudioSourceFor(sourceId) ??\n        quranAudioForSource(sourceId).firstOrNull?.id;",
    "    final available = quranAudioForSource(sourceId);\n    final audioId = _audioController.config?.id ??\n        settings.selectedAudioSourceFor(sourceId) ??\n        (available.isEmpty ? null : available.first.id);",
)
text = replace_once(
    text,
    '        onSourceSelected: _selectAudioSource,\n      ),',
    '        onSourceSelected: _selectAudioSource,\n        onBitrateSelected: _selectAudioBitrate,\n      ),',
    'sheet bitrate callback wire',
)
path.write_text(text, encoding='utf-8')


# Downloads management screen.
Path('lib/src/features/profile/downloads_screen.dart').write_text(r'''import 'package:flutter/material.dart';

import '../../data/quran_audio_catalog.dart';
import '../../data/surah_catalog.dart';
import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../settings/app_settings.dart';
import '../reader/offline_audio_manager.dart';
import '../reader/reader_audio_cache.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  bool _loading = true;
  List<_TranslationDownload> _translations = const [];
  List<OfflineAudioSurah> _audio = const [];
  int _temporaryBytes = 0;
  int _offlineBytes = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final translations = <_TranslationDownload>[];
    for (final info in translationCatalog) {
      if (info.bundled || !await TranslationRepository.instance.isInstalled(info.id)) continue;
      translations.add(
        _TranslationDownload(
          info: info,
          bytes: await TranslationRepository.instance.installedTranslationBytes(info.id),
        ),
      );
    }
    final audio = await OfflineAudioManager.instance.downloadedSurahs();
    final temporary = await ReaderAudioCache.instance.temporaryCacheBytes();
    final offline = audio.fold<int>(0, (sum, item) => sum + item.bytes);
    if (!mounted) return;
    setState(() {
      _translations = translations;
      _audio = audio;
      _temporaryBytes = temporary;
      _offlineBytes = offline;
      _loading = false;
    });
  }

  QuranAudioInfo? _audioForStorageKey(String key) {
    for (final audio in quranAudioCatalog) {
      if (key == audio.id || key.startsWith('${audio.id}_')) return audio;
    }
    return null;
  }

  int? _bitrateForStorageKey(String key, QuranAudioInfo? audio) {
    if (audio == null || key == audio.id) return audio?.bitrate;
    return int.tryParse(key.substring(audio.id.length + 1)) ?? audio.bitrate;
  }

  @override
  Widget build(BuildContext context) {
    final copy = _DownloadsCopy(Localizations.localeOf(context).languageCode);
    final scheme = Theme.of(context).colorScheme;
    final settings = AppSettingsScope.of(context);
    final groupedAudio = <String, List<OfflineAudioSurah>>{};
    for (final item in _audio) {
      groupedAudio.putIfAbsent(item.storageKey, () => <OfflineAudioSurah>[]).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                _StorageSummary(
                  permanentBytes: _offlineBytes + _translations.fold<int>(0, (sum, item) => sum + item.bytes),
                  cacheBytes: _temporaryBytes,
                  copy: copy,
                ),
                const SizedBox(height: 24),
                Text(copy.downloadSettings, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: settings.audioDownloadWifiOnly,
                  onChanged: settings.setAudioDownloadWifiOnly,
                  title: Text(copy.wifiOnly, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(copy.wifiOnlyDescription),
                ),
                SwitchListTile.adaptive(
                  value: settings.audioDownloadAskOnMobile,
                  onChanged: settings.audioDownloadWifiOnly ? null : settings.setAudioDownloadAskOnMobile,
                  title: Text(copy.askMobile, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(copy.askMobileDescription),
                ),
                const SizedBox(height: 22),
                Text(copy.translations, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (_translations.isEmpty)
                  _EmptyCard(text: copy.noTranslations)
                else
                  for (final item in _translations)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.translate_rounded),
                        title: Text(item.info.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${item.info.publisher} · ${_formatBytes(item.bytes)}'),
                        trailing: IconButton(
                          onPressed: () async {
                            await TranslationRepository.instance.deleteInstalledTranslation(item.info.id);
                            await _refresh();
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    ),
                const SizedBox(height: 22),
                Text(copy.audio, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (groupedAudio.isEmpty)
                  _EmptyCard(text: copy.noAudio)
                else
                  for (final entry in groupedAudio.entries) ...[
                    Builder(
                      builder: (context) {
                        final audioInfo = _audioForStorageKey(entry.key);
                        final bitrate = _bitrateForStorageKey(entry.key, audioInfo);
                        final total = entry.value.fold<int>(0, (sum, item) => sum + item.bytes);
                        return Card(
                          child: ExpansionTile(
                            leading: const Icon(Icons.headphones_rounded),
                            title: Text(audioInfo?.title ?? entry.key, style: const TextStyle(fontWeight: FontWeight.w900)),
                            subtitle: Text('${entry.value.length} ${copy.surah} · ${_formatBytes(total)}${bitrate == null ? '' : ' · $bitrate kbps'}'),
                            children: [
                              for (final item in entry.value)
                                ListTile(
                                  title: Text(surahByNumber(item.surah).nameTr),
                                  subtitle: Text('${item.downloadedAyahs} ${copy.verse} · ${_formatBytes(item.bytes)}'),
                                  trailing: IconButton(
                                    onPressed: () async {
                                      await OfflineAudioManager.instance.deleteSurah(item.storageKey, item.surah);
                                      await _refresh();
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded),
                                  ),
                                ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      await OfflineAudioManager.instance.deleteSource(entry.key);
                                      await _refresh();
                                    },
                                    icon: const Icon(Icons.delete_sweep_outlined),
                                    label: Text(copy.deleteAll),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                const SizedBox(height: 22),
                Text(copy.cache, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.cached_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${copy.temporaryCache} · ${_formatBytes(_temporaryBytes)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text(copy.cacheDescription, style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _temporaryBytes <= 0
                            ? null
                            : () async {
                                await ReaderAudioCache.instance.clearTemporaryCache();
                                await _refresh();
                              },
                        child: Text(copy.clear),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _TranslationDownload {
  const _TranslationDownload({required this.info, required this.bytes});
  final TranslationInfo info;
  final int bytes;
}

class _StorageSummary extends StatelessWidget {
  const _StorageSummary({required this.permanentBytes, required this.cacheBytes, required this.copy});
  final int permanentBytes;
  final int cacheBytes;
  final _DownloadsCopy copy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: .45), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Icon(Icons.storage_rounded, color: scheme.primary, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${copy.permanent}: ${_formatBytes(permanentBytes)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${copy.temporaryCache}: ${_formatBytes(cacheBytes)} · 100 MB ${copy.limit}', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(18)),
        child: Text(text),
      );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class _DownloadsCopy {
  const _DownloadsCopy(this.languageCode);
  final String languageCode;
  String _pick(String tr, String en, String ar, String az, String ru) => switch (languageCode) {
        'tr' => tr,
        'ar' => ar,
        'az' => az,
        'ru' => ru,
        _ => en,
      };
  String get title => _pick('İndirilenler', 'Downloads', 'التنزيلات', 'Endirilənlər', 'Загрузки');
  String get downloadSettings => _pick('İndirme ayarları', 'Download settings', 'إعدادات التنزيل', 'Endirmə ayarları', 'Настройки загрузки');
  String get wifiOnly => _pick('Büyük indirmeler yalnızca Wi‑Fi', 'Large downloads on Wi‑Fi only', 'التنزيلات الكبيرة عبر Wi‑Fi فقط', 'Böyük endirmələr yalnız Wi‑Fi', 'Большие загрузки только по Wi‑Fi');
  String get wifiOnlyDescription => _pick('Ses dosyalarında mobil veri kullanımını engeller.', 'Prevents mobile-data use for audio downloads.', 'يمنع استخدام بيانات الهاتف لتنزيل الصوت.', 'Səs endirmələrində mobil datanı bloklayır.', 'Запрещает мобильные данные для аудио.');
  String get askMobile => _pick('Mobil veride indirmeden önce sor', 'Ask before downloading on mobile data', 'السؤال قبل التنزيل عبر بيانات الهاتف', 'Mobil datada əvvəlcə soruş', 'Спрашивать перед загрузкой по мобильной сети');
  String get askMobileDescription => _pick('Wi‑Fi zorunluluğu kapalıyken geçerlidir.', 'Used when Wi‑Fi-only is disabled.', 'يعمل عند تعطيل خيار Wi‑Fi فقط.', 'Wi‑Fi məcburiyyəti bağlı olanda işləyir.', 'Работает, когда режим «только Wi‑Fi» выключен.');
  String get translations => _pick('Mealler', 'Translations', 'الترجمات', 'Tərcümələr', 'Переводы');
  String get audio => _pick('Sesler', 'Audio', 'الصوت', 'Səslər', 'Аудио');
  String get cache => _pick('Önbellek', 'Cache', 'ذاكرة التخزين المؤقت', 'Keş', 'Кэш');
  String get permanent => _pick('Kalıcı indirmeler', 'Permanent downloads', 'التنزيلات الدائمة', 'Daimi endirmələr', 'Постоянные загрузки');
  String get temporaryCache => _pick('Geçici önbellek', 'Temporary cache', 'ذاكرة مؤقتة', 'Müvəqqəti keş', 'Временный кэш');
  String get cacheDescription => _pick('Dinlerken otomatik oluşur; kalıcı indirmeleri etkilemeden temizlenir.', 'Created automatically during playback; clearing it never removes permanent downloads.', 'يُنشأ تلقائيًا أثناء الاستماع ولا يحذف التنزيلات الدائمة.', 'Dinləyərkən avtomatik yaranır və daimi endirmələri silmir.', 'Создаётся автоматически и не затрагивает постоянные загрузки.');
  String get clear => _pick('Temizle', 'Clear', 'مسح', 'Təmizlə', 'Очистить');
  String get noTranslations => _pick('İndirilmiş ek meal yok.', 'No extra translations downloaded.', 'لا توجد ترجمات إضافية محملة.', 'Əlavə tərcümə endirilməyib.', 'Нет загруженных дополнительных переводов.');
  String get noAudio => _pick('Henüz kalıcı ses indirmesi yok.', 'No permanent audio downloads yet.', 'لا توجد تنزيلات صوتية دائمة بعد.', 'Hələ daimi səs endirilməsi yoxdur.', 'Постоянных аудиозагрузок пока нет.');
  String get surah => _pick('sure', 'surahs', 'سور', 'surə', 'сур');
  String get verse => _pick('ayet', 'verses', 'آية', 'ayə', 'аятов');
  String get deleteAll => _pick('Bu sesi tamamen sil', 'Delete all for this voice', 'حذف كل ملفات هذا الصوت', 'Bu səsi tam sil', 'Удалить весь этот голос');
  String get limit => _pick('sınır', 'limit', 'حد', 'limit', 'лимит');
}
''', encoding='utf-8')


# Profile link becomes functional.
path = Path('lib/src/features/profile/profile_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../reader/passage_preview_screen.dart';\nimport '../settings/settings_screen.dart';",
    "import '../reader/passage_preview_screen.dart';\nimport '../settings/settings_screen.dart';\nimport 'downloads_screen.dart';",
    'profile downloads import',
)
text = replace_once(
    text,
    "          _SettingsTile(\n            Icons.download_done_rounded,\n            l10n.downloads,\n            l10n.downloadsDescription,\n          ),",
    "          _SettingsTile(\n            Icons.download_done_rounded,\n            l10n.downloads,\n            l10n.downloadsDescription,\n            onTap: () => Navigator.of(context).push(\n              MaterialPageRoute<void>(builder: (_) => const DownloadsScreen()),\n            ),\n          ),",
    'profile downloads onTap',
)
text = replace_once(
    text,
    'class _SettingsTile extends StatelessWidget {\n  const _SettingsTile(this.icon, this.title, this.subtitle);\n\n  final IconData icon;\n  final String title;\n  final String? subtitle;',
    'class _SettingsTile extends StatelessWidget {\n  const _SettingsTile(this.icon, this.title, this.subtitle, {this.onTap});\n\n  final IconData icon;\n  final String title;\n  final String? subtitle;\n  final VoidCallback? onTap;',
    'settings tile callback',
)
text = replace_once(
    text,
    '      child: ListTile(\n        contentPadding:',
    '      child: ListTile(\n        onTap: onTap,\n        contentPadding:',
    'settings tile onTap wire',
)
path.write_text(text, encoding='utf-8')


# Settings also links to Downloads.
path = Path('lib/src/features/settings/settings_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../../settings/app_settings.dart';\nimport 'quran_translation_catalog_screen.dart';",
    "import '../../settings/app_settings.dart';\nimport '../profile/downloads_screen.dart';\nimport 'quran_translation_catalog_screen.dart';",
    'settings downloads import',
)
text = replace_once(
    text,
    "          const SizedBox(height: 30),\n          _SectionHeader(title: l10n.reading),",
    "          const SizedBox(height: 18),\n          SizedBox(\n            width: double.infinity,\n            child: FilledButton.tonalIcon(\n              onPressed: () => Navigator.of(context).push(\n                MaterialPageRoute<void>(builder: (_) => const DownloadsScreen()),\n              ),\n              icon: const Icon(Icons.download_done_rounded),\n              label: Text(l10n.downloads),\n            ),\n          ),\n          const SizedBox(height: 30),\n          _SectionHeader(title: l10n.reading),",
    'settings downloads button',
)
path.write_text(text, encoding='utf-8')


# Do not expose raw HTTP exceptions to end users.
path = Path('lib/src/features/settings/quran_translation_catalog_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "      ScaffoldMessenger.of(\n        context,\n      ).showSnackBar(SnackBar(content: Text('${copy.downloadFailed}: $error')));",
    "      ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(content: Text(copy.downloadFailed)),\n      );",
    'friendly translation error',
)
path.write_text(text, encoding='utf-8')


# Tests: one-request Turkish package and quality-aware cache identity.
path = Path('test/translation_repository_test.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import 'package:quran_i_kerim/src/data/translation_repository.dart';\n",
    "import 'package:quran_i_kerim/src/data/translation_catalog.dart';\nimport 'package:quran_i_kerim/src/data/translation_repository.dart';\n",
    'translation test catalog import',
)
text = replace_once(
    text,
    '\n}\n',
    r'''

  test('Islamic Network translation uses one complete-edition request', () {
    final info = translationById(turkishVakfiTranslationId)!;
    final uri = islamicNetworkTranslationPackageUri(info);
    expect(uri.host, 'api.alquran.cloud');
    expect(uri.path, '/v1/quran/tr.vakfi');
  });
}
''',
    'translation package test',
)
path.write_text(text, encoding='utf-8')

Path('test/audio_v2_catalog_test.dart').write_text(r'''import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/quran_audio_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/features/reader/reader_audio_sheet.dart';

void main() {
  test('Alafasy exposes only verified selectable bitrates', () {
    final audio = quranAudioById('arabic_recitation_alafasy');
    expect(audio, isNotNull);
    expect(quranAudioBitrates(audio!), <int>[64, 128]);
  });

  test('selected bitrate changes URL and persistent storage identity', () {
    final config = readerAudioConfigFor(
      arabicOriginalSourceId,
      audioId: 'arabic_recitation_alafasy',
      bitrate: 64,
    );
    expect(config, isNotNull);
    expect(config!.bitrate, 64);
    expect(config.cacheId, 'arabic_recitation_alafasy_64');
    expect(config.urlForVerse(1, 1), contains('/audio/64/ar.alafasy/1.mp3'));
  });
}
''', encoding='utf-8')
