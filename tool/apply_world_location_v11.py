from pathlib import Path
import re


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise SystemExit(f'missing patch target: {label}')
    return text.replace(old, new, 1)


# Prayer screen: GPS-first restore, manual worldwide persistence, Kaaba compass.
path = Path('lib/src/features/prayer/presentation/prayer_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../application/prayer_preferences_store.dart';\n",
    "import '../application/prayer_preferences_store.dart';\nimport '../application/prayer_region_resolver.dart';\n",
    'prayer region import',
)
text = replace_once(
    text,
    """    setState(() {
      _city = prayerCityById(cityId);
      _usingDeviceLocation = false;
      _prayerSettings = settings;
    });
    if (cityId == null) {
      unawaited(_useCurrentLocation(silent: true, preferCached: true));
    }
""",
    """    if (cityId == PrayerPreferencesStore.manualLocationId) {
      final savedManual = await PrayerPreferencesStore.loadManualLocation();
      if (!mounted) return;
      if (savedManual != null) {
        setState(() {
          _city = _cityFromManual(savedManual);
          _usingDeviceLocation = false;
          _prayerSettings = settings;
        });
        return;
      }
    }

    setState(() {
      _city = prayerCityById(cityId);
      _usingDeviceLocation = false;
      _prayerSettings = settings;
    });
    if (cityId == null) {
      unawaited(_useCurrentLocation(preferCached: true));
    }
""",
    'manual restore and first permission request',
)
text = replace_once(
    text,
    """  PrayerCity _cityFromDevice(PrayerDeviceLocationSnapshot value) => PrayerCity(
    id: PrayerPreferencesStore.deviceLocationId,
    label: 'GPS',
    country: '',
    group: value.regionCode,
    location: value.location,
    defaultMethod: value.defaultMethod,
  );
""",
    """  PrayerCity _cityFromDevice(PrayerDeviceLocationSnapshot value) => PrayerCity(
    id: PrayerPreferencesStore.deviceLocationId,
    label: 'GPS',
    country: '',
    group: value.regionCode,
    location: value.location,
    defaultMethod: value.defaultMethod,
  );

  PrayerCity _cityFromManual(PrayerManualLocationSnapshot value) => PrayerCity(
    id: value.sourceId,
    label: value.label,
    country: value.country,
    group: value.regionCode,
    location: value.location,
    defaultMethod: value.defaultMethod,
  );
""",
    'manual city conversion',
)
text = replace_once(
    text,
    """      builder: (_) => PrayerCityPicker(
        selectedCityId: _usingDeviceLocation ? null : _city.id,
      ),
""",
    """      builder: (_) => PrayerCityPicker(
        selectedCityId: _usingDeviceLocation ? null : _city.id,
        onUseCurrentLocation: () => _useCurrentLocation(preferCached: true),
      ),
""",
    'picker location action',
)
text = replace_once(
    text,
    """    if (picked == null || !mounted) return;
    await PrayerPreferencesStore.saveCityId(picked.id);
    if (!mounted) return;
    setState(() {
      _city = picked;
      _usingDeviceLocation = false;
      _showTomorrow = false;
    });
""",
    """    if (picked == null || !mounted) return;
    final isPriority = prayerCities.any((city) => city.id == picked.id);
    if (isPriority) {
      await PrayerPreferencesStore.saveCityId(picked.id);
    } else {
      final region = resolvePrayerRegion(
        picked.location.latitude,
        picked.location.longitude,
      );
      await PrayerPreferencesStore.saveManualLocation(
        PrayerManualLocationSnapshot(
          sourceId: picked.id,
          label: picked.label,
          country: picked.country,
          location: picked.location,
          defaultMethod: picked.defaultMethod,
          regionCode: region.regionCode,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _city = picked;
      _usingDeviceLocation = false;
      _showTomorrow = false;
    });
""",
    'persist manual world city',
)

qibla_pattern = re.compile(
    r'class QiblaInfoScreen extends StatelessWidget \{.*?\n\}\n\nclass _PrayerTimeRow',
    re.S,
)
qibla_replacement = r'''class QiblaInfoScreen extends StatefulWidget {
  const QiblaInfoScreen({
    required this.city,
    required this.qiblaDegrees,
    super.key,
  });

  final PrayerCity city;
  final double qiblaDegrees;

  @override
  State<QiblaInfoScreen> createState() => _QiblaInfoScreenState();
}

class _QiblaInfoScreenState extends State<QiblaInfoScreen> {
  bool _wasAligned = false;

  void _handleAlignment(bool aligned) {
    if (aligned && !_wasAligned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) HapticFeedback.mediumImpact();
      });
    }
    _wasAligned = aligned;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('qibla'))),
      body: StreamBuilder<CompassEvent>(
        stream: FlutterCompass.events,
        builder: (context, snapshot) {
          final heading = snapshot.data?.heading;
          final rawDelta = heading == null
              ? widget.qiblaDegrees
              : (widget.qiblaDegrees - heading + 360) % 360;
          final signedDelta = rawDelta > 180 ? rawDelta - 360 : rawDelta;
          final aligned = heading != null && signedDelta.abs() <= 5;
          _handleAlignment(aligned);
          final angle = rawDelta * math.pi / 180;
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            children: [
              Text(
                widget.city.id == PrayerPreferencesStore.deviceLocationId
                    ? l10n.text('currentLocation')
                    : widget.city.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                heading == null
                    ? l10n.text('compassUnavailable')
                    : aligned
                    ? l10n.text('qiblaAligned')
                    : l10n.text('pointTopToKaaba'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: aligned ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Container(
                  width: 268,
                  height: 268,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainer,
                    border: Border.all(
                      color: aligned ? scheme.primary : scheme.outlineVariant,
                      width: aligned ? 2.4 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned(
                        top: 13,
                        child: Text(
                          'N',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Positioned(
                        top: 42,
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 34,
                          color: aligned ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                      Transform.rotate(
                        angle: angle,
                        child: SizedBox(
                          width: 232,
                          height: 232,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Transform.rotate(
                              angle: -angle,
                              child: const _KaabaMarker(),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                heading == null
                    ? '${widget.qiblaDegrees.round()}°'
                    : '${signedDelta.abs().round()}°',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                heading == null
                    ? l10n.text('qiblaNorthDescription')
                    : aligned
                    ? l10n.text('qiblaAligned')
                    : l10n.text('liveQibla'),
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  l10n.text('qiblaCalibrationInfo'),
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KaabaMarker extends StatelessWidget {
  const _KaabaMarker();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFF171717),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: const Color(0xFFB99A45), width: 1.2),
      boxShadow: const [
        BoxShadow(blurRadius: 7, offset: Offset(0, 2), color: Color(0x33000000)),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 10,
          child: Container(height: 5, color: const Color(0xFFC9A94E)),
        ),
        Positioned(
          right: 7,
          bottom: 5,
          child: Container(
            width: 8,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFFB68C32),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PrayerTimeRow'''
text, count = qibla_pattern.subn(qibla_replacement, text, count=1)
if count != 1:
    raise SystemExit('missing patch target: qibla screen block')
path.write_text(text, encoding='utf-8')


# Discover: direct visible Qibla shortcut.
path = Path('lib/src/features/discover/discover_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    "import '../prayer/presentation/prayer_screen.dart';\n",
    "import '../prayer/presentation/prayer_screen.dart';\nimport '../prayer/presentation/qibla_launcher_screen.dart';\n",
    'discover qibla import',
)
text = replace_once(
    text,
    """    void openDhikr() {
""",
    """    void openQibla() {
      HapticFeedback.selectionClick();
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const QiblaLauncherScreen()),
      );
    }

    void openDhikr() {
""",
    'discover open qibla',
)
text = replace_once(
    text,
    """          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  Icons.touch_app_outlined,
""",
    """          const SizedBox(height: 12),
          _Shortcut(
            Icons.explore_outlined,
            l10n.text('qibla'),
            onTap: openQibla,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  Icons.touch_app_outlined,
""",
    'discover qibla shortcut',
)
path.write_text(text, encoding='utf-8')


# Reader: selected ayah Listen action starts at selected verse in active audio source.
path = Path('lib/src/features/reader/quran_reader_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    """  Future<void> _showAudioPlayer(ReaderAudioSourceConfig config) async {
""",
    """  Future<void> _listenSelection(ReaderAudioSourceConfig config) async {
    final selected = _selection;
    if (selected.isEmpty) return;
    final targetAyah = selected.first;
    await _prepareAudio(config);
    await _audioController.playAyah(targetAyah);
    if (!mounted) return;
    setState(() {
      _audioFollowEnabled = true;
      _manualReaderScroll = false;
    });
    _clearSelection();
    _scheduleScrollToAyah(targetAyah, audioFollow: true);
  }

  Future<void> _showAudioPlayer(ReaderAudioSourceConfig config) async {
""",
    'listen selected ayah method',
)
text = replace_once(
    text,
    """                    onNote: _editSelectionNote,
                    onCopy: _copySelection,
                    onCompare: _showCompareSheet,
""",
    """                    onNote: _editSelectionNote,
                    onListen: audioConfig == null
                        ? null
                        : () => _listenSelection(audioConfig),
                    onCopy: _copySelection,
                    onCompare: _showCompareSheet,
""",
    'selection tray listen callback',
)
text = replace_once(
    text,
    """    required this.onNote,
    required this.onCopy,
    required this.onCompare,
""",
    """    required this.onNote,
    required this.onListen,
    required this.onCopy,
    required this.onCompare,
""",
    'selection tray constructor listen',
)
text = replace_once(
    text,
    """  final VoidCallback onNote;
  final VoidCallback onCopy;
  final VoidCallback onCompare;
""",
    """  final VoidCallback onNote;
  final VoidCallback? onListen;
  final VoidCallback onCopy;
  final VoidCallback onCompare;
""",
    'selection tray listen field',
)
text = replace_once(
    text,
    """              _SelectionAction(
                icon: Icons.note_alt_outlined,
                label: l10n.text('note'),
                onTap: onNote,
              ),
              _SelectionAction(
                icon: Icons.copy_rounded,
""",
    """              _SelectionAction(
                icon: Icons.note_alt_outlined,
                label: l10n.text('note'),
                onTap: onNote,
              ),
              if (onListen != null)
                _SelectionAction(
                  icon: Icons.headphones_rounded,
                  label: l10n.text('listen'),
                  onTap: onListen!,
                ),
              _SelectionAction(
                icon: Icons.copy_rounded,
""",
    'selection tray listen action',
)
path.write_text(text, encoding='utf-8')


# Localization: add worldwide location/Qibla copy in all five locales.
path = Path('lib/src/l10n/strings/feature_strings.dart')
text = path.read_text(encoding='utf-8')
insertions = {
    "    'cityNotFound': 'Şehir bulunamadı.',\n": """    'cityNotFound': 'Şehir bulunamadı.',
    'worldCitySearchInfo': 'Dünya şehirleri çevrimdışı aranır. Bulamazsanız GPS veya isteğe bağlı çevrimiçi aramayı kullanabilirsiniz.',
    'cityNotFoundBody': 'Şehriniz listede yoksa konum izniyle otomatik bulabilir veya yalnızca bu arama için çevrimiçi arayabilirsiniz.',
    'useLocationToFind': 'Konumumu kullan ve bul',
    'searchOnline': 'Çevrimiçi ara',
    'onlineSearchFailed': 'Çevrimiçi şehir araması başarısız oldu.',
    'onlineResults': 'Çevrimiçi sonuçlar',
    'offlineResults': 'Çevrimdışı sonuçlar',
    'priorityCities': 'Öne çıkan şehirler',
    'locationDataAttribution': 'Çevrimdışı şehir verisi: GeoNames (CC BY 4.0) · Çevrimiçi arama: OpenStreetMap katkıcıları',
    'qiblaLocationPrompt': 'Kıble için konum gerekli',
    'qiblaLocationPromptBody': 'Konum izni verirseniz Kâbe yönünü bulunduğunuz noktadan hesaplarız. Şehir seçmeniz gerekmez.',
    'chooseManually': 'Manuel konum seç',
    'pointTopToKaaba': 'Telefonun üst kısmını Kâbe işaretine çevirin',
""",
    "    'cityNotFound': 'City not found.',\n": """    'cityNotFound': 'City not found.',
    'worldCitySearchInfo': 'Worldwide cities are searched offline. If needed, use GPS or an explicit online lookup.',
    'cityNotFoundBody': 'If your city is missing, let us find your location with GPS or run a one-time online search.',
    'useLocationToFind': 'Use my location and find it',
    'searchOnline': 'Search online',
    'onlineSearchFailed': 'Online city search failed.',
    'onlineResults': 'Online results',
    'offlineResults': 'Offline results',
    'priorityCities': 'Featured cities',
    'locationDataAttribution': 'Offline city data: GeoNames (CC BY 4.0) · Online search: OpenStreetMap contributors',
    'qiblaLocationPrompt': 'Location is needed for Qibla',
    'qiblaLocationPromptBody': 'Allow location access and we calculate the Kaaba direction from your exact position. No city selection is required.',
    'chooseManually': 'Choose location manually',
    'pointTopToKaaba': 'Turn the top of your phone toward the Kaaba marker',
""",
    "    'cityNotFound': 'لم يتم العثور على مدينة.',\n": """    'cityNotFound': 'لم يتم العثور على مدينة.',
    'worldCitySearchInfo': 'يتم البحث في مدن العالم دون اتصال. عند الحاجة استخدم GPS أو البحث عبر الإنترنت صراحةً.',
    'cityNotFoundBody': 'إذا لم تجد مدينتك، يمكن تحديد موقعك عبر GPS أو إجراء بحث واحد عبر الإنترنت.',
    'useLocationToFind': 'استخدم موقعي للعثور عليها',
    'searchOnline': 'بحث عبر الإنترنت',
    'onlineSearchFailed': 'فشل البحث عن المدينة عبر الإنترنت.',
    'onlineResults': 'نتائج الإنترنت',
    'offlineResults': 'نتائج دون اتصال',
    'priorityCities': 'مدن بارزة',
    'locationDataAttribution': 'بيانات المدن دون اتصال: GeoNames (CC BY 4.0) · البحث عبر الإنترنت: مساهمو OpenStreetMap',
    'qiblaLocationPrompt': 'الموقع مطلوب لتحديد القبلة',
    'qiblaLocationPromptBody': 'اسمح بالوصول إلى الموقع لنحسب اتجاه الكعبة من موقعك الدقيق دون الحاجة لاختيار مدينة.',
    'chooseManually': 'اختيار الموقع يدويًا',
    'pointTopToKaaba': 'وجّه أعلى الهاتف نحو علامة الكعبة',
""",
    "    'cityNotFound': 'Şəhər tapılmadı.',\n": """    'cityNotFound': 'Şəhər tapılmadı.',
    'worldCitySearchInfo': 'Dünya şəhərləri oflayn axtarılır. Lazım olsa GPS və ya açıq şəkildə onlayn axtarışdan istifadə edin.',
    'cityNotFoundBody': 'Şəhərinizi tapmadınızsa GPS ilə məkanınızı müəyyən edə və ya bir dəfə onlayn axtara bilərsiniz.',
    'useLocationToFind': 'Məkanımı istifadə edib tap',
    'searchOnline': 'Onlayn axtar',
    'onlineSearchFailed': 'Onlayn şəhər axtarışı uğursuz oldu.',
    'onlineResults': 'Onlayn nəticələr',
    'offlineResults': 'Oflayn nəticələr',
    'priorityCities': 'Seçilmiş şəhərlər',
    'locationDataAttribution': 'Oflayn şəhər məlumatı: GeoNames (CC BY 4.0) · Onlayn axtarış: OpenStreetMap iştirakçıları',
    'qiblaLocationPrompt': 'Qiblə üçün məkan lazımdır',
    'qiblaLocationPromptBody': 'Məkan icazəsi versəniz Kəbə istiqamətini dəqiq mövqeyinizdən hesablayarıq. Şəhər seçmək lazım deyil.',
    'chooseManually': 'Məkanı əl ilə seç',
    'pointTopToKaaba': 'Telefonun üst hissəsini Kəbə işarəsinə çevirin',
""",
    "    'cityNotFound': 'Город не найден.',\n": """    'cityNotFound': 'Город не найден.',
    'worldCitySearchInfo': 'Города мира ищутся офлайн. При необходимости используйте GPS или явный онлайн-поиск.',
    'cityNotFoundBody': 'Если города нет в списке, определите местоположение по GPS или выполните разовый онлайн-поиск.',
    'useLocationToFind': 'Найти по моему местоположению',
    'searchOnline': 'Искать онлайн',
    'onlineSearchFailed': 'Не удалось выполнить онлайн-поиск города.',
    'onlineResults': 'Онлайн-результаты',
    'offlineResults': 'Офлайн-результаты',
    'priorityCities': 'Избранные города',
    'locationDataAttribution': 'Офлайн-данные городов: GeoNames (CC BY 4.0) · Онлайн-поиск: участники OpenStreetMap',
    'qiblaLocationPrompt': 'Для Киблы нужно местоположение',
    'qiblaLocationPromptBody': 'Разрешите доступ к местоположению, и направление на Каабу будет рассчитано от вашей точной позиции без выбора города.',
    'chooseManually': 'Выбрать место вручную',
    'pointTopToKaaba': 'Поверните верх телефона к значку Каабы',
""",
}
for old, new in insertions.items():
    text = replace_once(text, old, new, f'localization {old.strip()}')
path.write_text(text, encoding='utf-8')


# Localization test locks the new product copy in every locale.
path = Path('test/app_localizations_test.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(
    text,
    """      'chooseCity',
      'monthlyPrayerTimes',
""",
    """      'chooseCity',
      'worldCitySearchInfo',
      'searchOnline',
      'qiblaLocationPrompt',
      'pointTopToKaaba',
      'monthlyPrayerTimes',
""",
    'localization test keys',
)
path.write_text(text, encoding='utf-8')

print('world location v11 patch applied')
