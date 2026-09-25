import 'package:flutter/material.dart';

import '../../data/quran_audio_catalog.dart';
import '../../data/surah_catalog.dart';
import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';
import '../reader/audio_download_queue_controller.dart';
import '../reader/offline_audio_manager.dart';
import '../reader/reader_audio_cache.dart';
import '../reader/quran_audio_download_url.dart';

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
  int _refreshGeneration = 0;

  @override
  void initState() {
    super.initState();
    OfflineAudioManager.instance.addListener(_handleAudioChanged);
    AudioDownloadQueueController.instance.addListener(_handleQueueChanged);
    _refresh();
  }

  @override
  void dispose() {
    OfflineAudioManager.instance.removeListener(_handleAudioChanged);
    AudioDownloadQueueController.instance.removeListener(_handleQueueChanged);
    super.dispose();
  }

  void _handleAudioChanged() {
    if (mounted) _refresh();
  }

  void _handleQueueChanged() {
    if (mounted) setState(() {});
  }

  List<AudioQueueItem> _recoverableQueueItems() {
    final items = <AudioQueueItem>[];
    for (final pack in _audio) {
      if (pack.readiness == OfflineAudioPackReadiness.ready) continue;
      final info = _audioForStorageKey(pack.storageKey);
      if (info == null || pack.verseCount <= 0) continue;
      items.add(
        AudioQueueItem(
          storageKey: pack.storageKey,
          surah: pack.surah,
          verseCount: pack.verseCount,
          audioInfo: info,
          bitrate: _bitrateForStorageKey(pack.storageKey, info),
        ),
      );
    }
    return items;
  }

  Future<void> _startRecoveryQueue(_DownloadsCopy copy) async {
    final items = _recoverableQueueItems();
    if (items.isEmpty) return;
    final settings = AppSettingsScope.of(context);
    final network = await OfflineAudioManager.instance.currentNetworkKind();
    if (!mounted) return;
    if (network == AudioNetworkKind.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.noConnection)),
      );
      return;
    }
    if (settings.audioDownloadWifiOnly && network != AudioNetworkKind.wifi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.wifiRequired)),
      );
      return;
    }
    if (!settings.audioDownloadWifiOnly &&
        settings.audioDownloadAskOnMobile &&
        network == AudioNetworkKind.mobile) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(copy.mobileDataTitle),
          content: Text(copy.bulkMobileDataBody(items.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.continueDownload),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    final queue = AudioDownloadQueueController.instance;
    queue.enqueueAll(items);
    await queue.start();
    if (mounted) await _refresh();
  }

  Future<void> _refresh() async {
    final generation = ++_refreshGeneration;
    final translations = <_TranslationDownload>[];
    for (final info in translationCatalog) {
      if (info.bundled ||
          !await TranslationRepository.instance.isInstalled(info.id))
        continue;
      translations.add(
        _TranslationDownload(
          info: info,
          bytes: await TranslationRepository.instance.installedTranslationBytes(
            info.id,
          ),
        ),
      );
    }
    final audio = await OfflineAudioManager.instance.downloadedSurahs();
    final temporary = await ReaderAudioCache.instance.temporaryCacheBytes();
    final offline = audio.fold<int>(0, (sum, item) => sum + item.bytes);
    if (!mounted || generation != _refreshGeneration) return;
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

  AudioDownloadProgress? _progressFor(OfflineAudioSurah item) =>
      OfflineAudioManager.instance.progressFor(item.storageKey, item.surah);

  bool _recoveryActive(OfflineAudioSurah item) {
    final status = _progressFor(item)?.status;
    return status == AudioDownloadStatus.downloading ||
        status == AudioDownloadStatus.verifying;
  }

  String _packStatusText(OfflineAudioSurah item, _DownloadsCopy copy) {
    final progress = _progressFor(item);
    if (progress == null) return copy.packStatus(item.readiness);
    return switch (progress.status) {
      AudioDownloadStatus.downloading => copy.downloading,
      AudioDownloadStatus.paused => copy.paused,
      AudioDownloadStatus.verifying => copy.verifying,
      AudioDownloadStatus.completed => copy.packStatus(item.readiness),
      AudioDownloadStatus.failed => copy.failed,
    };
  }

  Future<void> _resumeOrRepair(
    OfflineAudioSurah item,
    QuranAudioInfo audioInfo,
    int? bitrate,
    _DownloadsCopy copy,
  ) async {
    final settings = AppSettingsScope.of(context);
    final network = await OfflineAudioManager.instance.currentNetworkKind();
    if (!mounted) return;
    if (network == AudioNetworkKind.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.noConnection)),
      );
      return;
    }
    if (settings.audioDownloadWifiOnly && network != AudioNetworkKind.wifi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.wifiRequired)),
      );
      return;
    }
    if (!settings.audioDownloadWifiOnly &&
        settings.audioDownloadAskOnMobile &&
        network == AudioNetworkKind.mobile) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(copy.mobileDataTitle),
          content: Text(copy.mobileDataBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.continueDownload),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }

    final resolver = QuranAudioDownloadUrlResolver(audioInfo, bitrate: bitrate);
    await OfflineAudioManager.instance.downloadSurah(
      storageKey: item.storageKey,
      surah: item.surah,
      verseCount: item.verseCount,
      urlForAyah: (ayah) => resolver.urlForVerse(item.surah, ayah),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _DownloadsCopy(Localizations.localeOf(context).languageCode);
    final scheme = Theme.of(context).colorScheme;
    final settings = AppSettingsScope.of(context);
    final groupedAudio = <String, List<OfflineAudioSurah>>{};
    for (final item in _audio) {
      groupedAudio
          .putIfAbsent(item.storageKey, () => <OfflineAudioSurah>[])
          .add(item);
    }

    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              children: [
                _StorageSummary(
                  permanentBytes:
                      _offlineBytes +
                      _translations.fold<int>(
                        0,
                        (sum, item) => sum + item.bytes,
                      ),
                  cacheBytes: _temporaryBytes,
                  copy: copy,
                ),
                const SizedBox(height: 24),
                Text(
                  copy.downloadSettings,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: settings.audioDownloadWifiOnly,
                  onChanged: settings.setAudioDownloadWifiOnly,
                  title: Text(
                    copy.wifiOnly,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(copy.wifiOnlyDescription),
                ),
                SwitchListTile.adaptive(
                  value: settings.audioDownloadAskOnMobile,
                  onChanged: settings.audioDownloadWifiOnly
                      ? null
                      : settings.setAudioDownloadAskOnMobile,
                  title: Text(
                    copy.askMobile,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(copy.askMobileDescription),
                ),
                const SizedBox(height: 22),
                Text(
                  copy.translations,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (_translations.isEmpty)
                  _EmptyCard(text: copy.noTranslations)
                else
                  for (final item in _translations)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.translate_rounded),
                        title: Text(
                          item.info.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${item.info.publisher} · ${_formatBytes(item.bytes)}',
                        ),
                        trailing: IconButton(
                          onPressed: () async {
                            await TranslationRepository.instance
                                .deleteInstalledTranslation(item.info.id);
                            await _refresh();
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    ),
                const SizedBox(height: 22),
                Text(
                  copy.audio,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (_recoverableQueueItems().isNotEmpty ||
                    AudioDownloadQueueController.instance.hasWork)
                  _AudioRecoveryQueueCard(
                    queue: AudioDownloadQueueController.instance,
                    recoverableCount: _recoverableQueueItems().length,
                    copy: copy,
                    onStart: () => _startRecoveryQueue(copy),
                  ),
                if (_recoverableQueueItems().isNotEmpty ||
                    AudioDownloadQueueController.instance.hasWork)
                  const SizedBox(height: 10),
                if (groupedAudio.isEmpty)
                  _EmptyCard(text: copy.noAudio)
                else
                  for (final entry in groupedAudio.entries) ...[
                    Builder(
                      builder: (context) {
                        final audioInfo = _audioForStorageKey(entry.key);
                        final bitrate = _bitrateForStorageKey(
                          entry.key,
                          audioInfo,
                        );
                        final total = entry.value.fold<int>(
                          0,
                          (sum, item) => sum + item.bytes,
                        );
                        return Card(
                          child: ExpansionTile(
                            leading: const Icon(Icons.headphones_rounded),
                            title: Text(
                              audioInfo?.title ?? entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '${entry.value.length} ${copy.surah} · ${_formatBytes(total)}${bitrate == null ? '' : ' · $bitrate kbps'}',
                            ),
                            children: [
                              for (final item in entry.value)
                                ListTile(
                                  leading: Icon(
                                    item.readiness ==
                                            OfflineAudioPackReadiness.ready
                                        ? Icons.offline_pin_rounded
                                        : item.readiness ==
                                              OfflineAudioPackReadiness
                                                  .needsRepair
                                        ? Icons.warning_amber_rounded
                                        : Icons.downloading_rounded,
                                    color: item.readiness ==
                                            OfflineAudioPackReadiness.ready
                                        ? scheme.primary
                                        : item.readiness ==
                                              OfflineAudioPackReadiness
                                                  .needsRepair
                                        ? scheme.error
                                        : scheme.tertiary,
                                  ),
                                  title: Text(surahByNumber(item.surah).nameTr),
                                  subtitle: Text(
                                    '${item.downloadedAyahs}/${item.verseCount} ${copy.verse} · ${_formatBytes(item.bytes)}\n${_packStatusText(item, copy)}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (item.readiness !=
                                              OfflineAudioPackReadiness.ready &&
                                          audioInfo != null)
                                        IconButton(
                                          onPressed: () {
                                            if (_recoveryActive(item)) {
                                              OfflineAudioManager.instance
                                                  .pauseDownload(
                                                    item.storageKey,
                                                    item.surah,
                                                  );
                                              return;
                                            }
                                            _resumeOrRepair(
                                              item,
                                              audioInfo,
                                              bitrate,
                                              copy,
                                            );
                                          },
                                          tooltip: _recoveryActive(item)
                                              ? copy.pause
                                              : item.readiness ==
                                                    OfflineAudioPackReadiness.needsRepair
                                              ? copy.repair
                                              : copy.resume,
                                          icon: Icon(
                                            _recoveryActive(item)
                                                ? Icons.pause_circle_outline_rounded
                                                : item.readiness ==
                                                      OfflineAudioPackReadiness.needsRepair
                                                ? Icons.build_circle_outlined
                                                : Icons.download_for_offline_outlined,
                                          ),
                                        ),
                                      if (item.readiness !=
                                          OfflineAudioPackReadiness.ready)
                                        IconButton(
                                          onPressed: () =>
                                              AppNavigation.instance.openReader(
                                                surah: item.surah,
                                                ayah: 1,
                                              ),
                                          tooltip: copy.openReader,
                                          icon: const Icon(
                                            Icons.menu_book_rounded,
                                          ),
                                        ),
                                      IconButton(
                                        onPressed: () async {
                                          await OfflineAudioManager.instance
                                              .deleteSurah(
                                                item.storageKey,
                                                item.surah,
                                              );
                                          await _refresh();
                                        },
                                        tooltip: copy.delete,
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    10,
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      await OfflineAudioManager.instance
                                          .deleteSource(entry.key);
                                      await _refresh();
                                    },
                                    icon: const Icon(
                                      Icons.delete_sweep_outlined,
                                    ),
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
                Text(
                  copy.cache,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cached_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${copy.temporaryCache} · ${_formatBytes(_temporaryBytes)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              copy.cacheDescription,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _temporaryBytes <= 0
                            ? null
                            : () async {
                                await ReaderAudioCache.instance
                                    .clearTemporaryCache();
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

class _AudioRecoveryQueueCard extends StatelessWidget {
  const _AudioRecoveryQueueCard({
    required this.queue,
    required this.recoverableCount,
    required this.copy,
    required this.onStart,
  });

  final AudioDownloadQueueController queue;
  final int recoverableCount;
  final _DownloadsCopy copy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final running = queue.status == AudioQueueStatus.running;
    final count = queue.pendingCount + (queue.active == null ? 0 : 1);
    return Semantics(
      container: true,
      label: copy.queueSemantics(running ? count : recoverableCount),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.recoveryQueueTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                running
                    ? copy.queueRunning(count)
                    : copy.queueReady(recoverableCount),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: running ? null : onStart,
                    icon: Icon(running
                        ? Icons.downloading_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(running ? copy.queueRunningShort : copy.resumeAll),
                  ),
                  if (running)
                    OutlinedButton.icon(
                      onPressed: queue.pause,
                      icon: const Icon(Icons.pause_rounded),
                      label: Text(copy.pauseAll),
                    ),
                  if (!running && queue.pendingCount > 0)
                    TextButton(
                      onPressed: queue.clearPending,
                      child: Text(copy.clearQueue),
                    ),
                ],
              ),
            ],
          ),
        ),
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
  const _StorageSummary({
    required this.permanentBytes,
    required this.cacheBytes,
    required this.copy,
  });
  final int permanentBytes;
  final int cacheBytes;
  final _DownloadsCopy copy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.storage_rounded, color: scheme.primary, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${copy.permanent}: ${_formatBytes(permanentBytes)}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${copy.temporaryCache}: ${_formatBytes(cacheBytes)} · 100 MB ${copy.limit}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
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
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
    ),
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
  String _pick(
    String tr,
    String en,
    String ar,
    String az,
    String ru, [
    String? fr,
  ]) =>
      switch (languageCode) {
        'tr' => tr,
        'ar' => ar,
        'az' => az,
        'ru' => ru,
        'fr' => fr ?? en,
        _ => en,
      };
  String get title => _pick(
    'İndirilenler',
    'Downloads',
    'التنزيلات',
    'Endirilənlər',
    'Загрузки',
  );
  String get downloadSettings => _pick(
    'İndirme ayarları',
    'Download settings',
    'إعدادات التنزيل',
    'Endirmə ayarları',
    'Настройки загрузки',
  );
  String get wifiOnly => _pick(
    'Büyük indirmeler yalnızca Wi‑Fi',
    'Large downloads on Wi‑Fi only',
    'التنزيلات الكبيرة عبر Wi‑Fi فقط',
    'Böyük endirmələr yalnız Wi‑Fi',
    'Большие загрузки только по Wi‑Fi',
  );
  String get wifiOnlyDescription => _pick(
    'Ses dosyalarında mobil veri kullanımını engeller.',
    'Prevents mobile-data use for audio downloads.',
    'يمنع استخدام بيانات الهاتف لتنزيل الصوت.',
    'Səs endirmələrində mobil datanı bloklayır.',
    'Запрещает мобильные данные для аудио.',
  );
  String get askMobile => _pick(
    'Mobil veride indirmeden önce sor',
    'Ask before downloading on mobile data',
    'السؤال قبل التنزيل عبر بيانات الهاتف',
    'Mobil datada əvvəlcə soruş',
    'Спрашивать перед загрузкой по мобильной сети',
  );
  String get askMobileDescription => _pick(
    'Wi‑Fi zorunluluğu kapalıyken geçerlidir.',
    'Used when Wi‑Fi-only is disabled.',
    'يعمل عند تعطيل خيار Wi‑Fi فقط.',
    'Wi‑Fi məcburiyyəti bağlı olanda işləyir.',
    'Работает, когда режим «только Wi‑Fi» выключен.',
  );
  String get translations =>
      _pick('Mealler', 'Translations', 'الترجمات', 'Tərcümələr', 'Переводы');
  String get audio => _pick('Sesler', 'Audio', 'الصوت', 'Səslər', 'Аудио');
  String get cache =>
      _pick('Önbellek', 'Cache', 'ذاكرة التخزين المؤقت', 'Keş', 'Кэш');
  String get permanent => _pick(
    'Kalıcı indirmeler',
    'Permanent downloads',
    'التنزيلات الدائمة',
    'Daimi endirmələr',
    'Постоянные загрузки',
  );
  String get temporaryCache => _pick(
    'Geçici önbellek',
    'Temporary cache',
    'ذاكرة مؤقتة',
    'Müvəqqəti keş',
    'Временный кэш',
  );
  String get cacheDescription => _pick(
    'Dinlerken otomatik oluşur; kalıcı indirmeleri etkilemeden temizlenir.',
    'Created automatically during playback; clearing it never removes permanent downloads.',
    'يُنشأ تلقائيًا أثناء الاستماع ولا يحذف التنزيلات الدائمة.',
    'Dinləyərkən avtomatik yaranır və daimi endirmələri silmir.',
    'Создаётся автоматически и не затрагивает постоянные загрузки.',
  );
  String get clear => _pick('Temizle', 'Clear', 'مسح', 'Təmizlə', 'Очистить');
  String get noTranslations => _pick(
    'İndirilmiş ek meal yok.',
    'No extra translations downloaded.',
    'لا توجد ترجمات إضافية محملة.',
    'Əlavə tərcümə endirilməyib.',
    'Нет загруженных дополнительных переводов.',
  );
  String get noAudio => _pick(
    'Henüz kalıcı ses indirmesi yok.',
    'No permanent audio downloads yet.',
    'لا توجد تنزيلات صوتية دائمة بعد.',
    'Hələ daimi səs endirilməsi yoxdur.',
    'Постоянных аудиозагрузок пока нет.',
  );
  String get surah => _pick('sure', 'surahs', 'سور', 'surə', 'сур');
  String get verse => _pick('ayet', 'verses', 'آية', 'ayə', 'аятов');
  String packStatus(OfflineAudioPackReadiness readiness) => switch (readiness) {
    OfflineAudioPackReadiness.ready => _pick(
      'Çevrimdışı hazır',
      'Ready offline',
      'جاهز دون اتصال',
      'Oflayn hazırdır',
      'Готово офлайн',
      'Prêt hors ligne',
    ),
    OfflineAudioPackReadiness.needsRepair => _pick(
      'Onarım gerekiyor · Reader’dan onar',
      'Needs repair · repair from Reader',
      'يحتاج إلى إصلاح · أصلحه من القارئ',
      'Bərpa lazımdır · Reader-dan bərpa et',
      'Требуется исправление · откройте Reader',
      'Réparation requise · ouvrir Reader',
    ),
    OfflineAudioPackReadiness.incomplete => _pick(
      'Bekliyor · Reader’dan devam et',
      'Pending · resume from Reader',
      'قيد الانتظار · تابع من القارئ',
      'Gözləyir · Reader-dan davam et',
      'Ожидает · продолжите в Reader',
      'En attente · reprendre dans Reader',
    ),
    OfflineAudioPackReadiness.notInstalled => _pick(
      'Yeniden indirme bekliyor',
      'Waiting to be downloaded again',
      'في انتظار إعادة التنزيل',
      'Yenidən endirilməni gözləyir',
      'Ожидает повторной загрузки',
      'En attente d’un nouveau téléchargement',
    ),
  };
  String get downloading => _pick('İndiriliyor', 'Downloading', 'جارٍ التنزيل', 'Endirilir', 'Загрузка', 'Téléchargement');
  String get paused => _pick('Duraklatıldı', 'Paused', 'متوقف مؤقتًا', 'Dayandırılıb', 'Приостановлено', 'En pause');
  String get verifying => _pick('Doğrulanıyor', 'Verifying', 'جارٍ التحقق', 'Yoxlanılır', 'Проверка', 'Vérification');
  String get failed => _pick('İndirme başarısız', 'Download failed', 'فشل التنزيل', 'Endirmə alınmadı', 'Ошибка загрузки', 'Échec du téléchargement');
  String get pause => _pick('Duraklat', 'Pause download', 'إيقاف مؤقت', 'Endirməni dayandır', 'Приостановить загрузку', 'Mettre en pause');
  String get resume => _pick('Devam et', 'Resume download', 'متابعة التنزيل', 'Endirməyə davam et', 'Продолжить загрузку', 'Reprendre');
  String get repair => _pick('Onar', 'Repair download', 'إصلاح التنزيل', 'Endirməni bərpa et', 'Исправить загрузку', 'Réparer');
  String get noConnection => _pick('İnternet bağlantısı yok.', 'No internet connection.', 'لا يوجد اتصال بالإنترنت.', 'İnternet bağlantısı yoxdur.', 'Нет подключения к интернету.', 'Pas de connexion Internet.');
  String get wifiRequired => _pick('Bu indirme için Wi‑Fi gerekli.', 'Wi‑Fi is required for this download.', 'يلزم اتصال Wi‑Fi لهذا التنزيل.', 'Bu endirmə üçün Wi‑Fi lazımdır.', 'Для этой загрузки требуется Wi‑Fi.', 'Le Wi‑Fi est requis pour ce téléchargement.');
  String get mobileDataTitle => _pick('Mobil veri kullanılsın mı?', 'Use mobile data?', 'استخدام بيانات الهاتف؟', 'Mobil data istifadə edilsin?', 'Использовать мобильные данные?', 'Utiliser les données mobiles ?');
  String get mobileDataBody => _pick('Ses indirmesi mobil veri kullanabilir.', 'Audio download may use mobile data.', 'قد يستخدم تنزيل الصوت بيانات الهاتف.', 'Səs endirməsi mobil data istifadə edə bilər.', 'Загрузка аудио может использовать мобильный интернет.', 'Le téléchargement audio peut utiliser les données mobiles.');
  String get continueDownload => _pick('İndir', 'Download', 'تنزيل', 'Endir', 'Загрузить', 'Télécharger');
  String get cancel => _pick('Vazgeç', 'Cancel', 'إلغاء', 'Ləğv et', 'Отмена', 'Annuler');
  String get openReader => _pick(
    'Reader’da aç ve onar',
    'Open Reader to repair',
    'افتح القارئ للإصلاح',
    'Bərpa üçün Reader-da aç',
    'Открыть Reader для исправления',
    'Ouvrir Reader pour réparer',
  );
  String get delete => _pick(
    'Paketi sil',
    'Delete pack',
    'حذف الحزمة',
    'Paketi sil',
    'Удалить пакет',
    'Supprimer le pack',
  );
  String get deleteAll => _pick(
    'Bu sesi tamamen sil',
    'Delete all for this voice',
    'حذف كل ملفات هذا الصوت',
    'Bu səsi tam sil',
    'Удалить весь этот голос',
  );
  String get recoveryQueueTitle => _pick('Ses kurtarma kuyruğu', 'Audio recovery queue', 'قائمة استعادة الصوت', 'Səs bərpa növbəsi', 'Очередь восстановления аудио', 'File de récupération audio');
  String get resumeAll => _pick('Tümüne devam et', 'Resume all', 'متابعة الكل', 'Hamısına davam et', 'Продолжить все', 'Tout reprendre');
  String get pauseAll => _pick('Kuyruğu duraklat', 'Pause queue', 'إيقاف القائمة مؤقتًا', 'Növbəni dayandır', 'Приостановить очередь', 'Mettre la file en pause');
  String get clearQueue => _pick('Kuyruğu temizle', 'Clear queue', 'مسح القائمة', 'Növbəni təmizlə', 'Очистить очередь', 'Vider la file');
  String get queueRunningShort => _pick('İndiriliyor', 'Downloading', 'جارٍ التنزيل', 'Endirilir', 'Загрузка', 'Téléchargement');
  String queueReady(int count) => _pick('$count paket devam etmeye veya onarıma hazır.', '$count packs are ready to resume or repair.', '$count حزمة جاهزة للمتابعة أو الإصلاح.', '$count paket davam etməyə və ya bərpaya hazırdır.', '$count пак. готовы к продолжению или исправлению.', '$count packs prêts à reprendre ou réparer.');
  String queueRunning(int count) => _pick('$count paket kuyrukta veya işleniyor.', '$count packs queued or in progress.', '$count حزمة في القائمة أو قيد المعالجة.', '$count paket növbədədir və ya işlənir.', '$count пак. в очереди или обрабатываются.', '$count packs en file ou en cours.');
  String queueSemantics(int count) => _pick('Ses kurtarma kuyruğu, $count paket', 'Audio recovery queue, $count packs', 'قائمة استعادة الصوت، $count حزمة', 'Səs bərpa növbəsi, $count paket', 'Очередь восстановления аудио, $count пак.', 'File de récupération audio, $count packs');
  String bulkMobileDataBody(int count) => _pick('$count ses paketi mobil veri kullanabilir.', '$count audio packs may use mobile data.', 'قد تستخدم $count حزمة صوت بيانات الهاتف.', '$count səs paketi mobil data istifadə edə bilər.', '$count аудиопакетов могут использовать мобильный интернет.', '$count packs audio peuvent utiliser les données mobiles.');
  String get limit => _pick('sınır', 'limit', 'حد', 'limit', 'лимит');
}
