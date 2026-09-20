import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/surah_catalog.dart';
import '../../data/surah_localization.dart';
import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';
import '../plans/reading_plan_store.dart';
import '../reader/reader_navigation.dart';
import 'home_prayer_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _communitySeenCountKey = 'community_seen_activity_count_v1';

  final ReadingPlanStore _readingPlanStore = const ReadingPlanStore();

  int _tab = 0;
  int _communitySeenCount = 0;
  int _readingPlanLoadGeneration = 0;
  bool _readingPlanLoading = true;
  ReadingPlanSnapshot _readingPlanSnapshot = const ReadingPlanSnapshot();

  static const _dailyVerseRefs = <(int, int)>[
    (94, 5),
    (94, 6),
    (2, 286),
    (13, 28),
    (39, 53),
    (65, 3),
    (3, 139),
    (2, 152),
    (93, 5),
    (20, 46),
    (29, 69),
    (14, 7),
  ];

  @override
  void initState() {
    super.initState();
    ReadingPlanStore.changes.addListener(_handleReadingPlanChanged);
    _loadCommunitySeenCount();
    _loadReadingPlan();
  }

  @override
  void dispose() {
    ReadingPlanStore.changes.removeListener(_handleReadingPlanChanged);
    super.dispose();
  }

  Future<void> _loadCommunitySeenCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _communitySeenCount = prefs.getInt(_communitySeenCountKey) ?? 0;
    });
  }

  void _handleReadingPlanChanged() {
    _loadReadingPlan();
  }

  Future<void> _loadReadingPlan() async {
    final generation = ++_readingPlanLoadGeneration;
    final snapshot = await _readingPlanStore.load();
    if (!mounted || generation != _readingPlanLoadGeneration) return;
    setState(() {
      _readingPlanSnapshot = snapshot;
      _readingPlanLoading = false;
    });
  }

  void _openPlans() {
    HapticFeedback.selectionClick();
    AppNavigation.instance.openPlans();
  }

  void _openReadingPlanDay() {
    final day = _readingPlanSnapshot.active?.nextDay;
    if (day == null) {
      _openPlans();
      return;
    }
    final target = firstVerseForPage(day.startPage);
    if (target == null) {
      _openPlans();
      return;
    }
    HapticFeedback.selectionClick();
    AppNavigation.instance.openReader(surah: target.surah, ayah: target.ayah);
  }

  int _activityCount(AppSettings settings) =>
      settings.bookmarkKeys.length +
      settings.noteEntries.length +
      settings.highlightEntries.length;

  Future<void> _selectTab(int index, AppSettings settings) async {
    if (_tab != index) {
      HapticFeedback.selectionClick();
      setState(() => _tab = index);
    }
    if (index != 1) return;
    final current = _activityCount(settings);
    if (_communitySeenCount == current) return;
    setState(() => _communitySeenCount = current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_communitySeenCountKey, current);
  }

  (int, int) get _todayVerse {
    final now = DateTime.now();
    final day = now.difference(DateTime(now.year)).inDays;
    return _dailyVerseRefs[day % _dailyVerseRefs.length];
  }

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 11) return l10n.text('goodMorning');
    if (hour < 18) return l10n.text('goodDay');
    return l10n.text('goodEvening');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = AppSettingsScope.of(context);
    final lastSurah = surahByNumber(settings.lastSurah);
    final l10n = context.l10n;
    final hasUnseenActivity = _activityCount(settings) > _communitySeenCount;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 4),
            child: Row(
              children: [
                _tabButton(l10n.text('today'), 0, settings),
                const SizedBox(width: 28),
                _tabButton(
                  l10n.text('community'),
                  1,
                  settings,
                  showDot: hasUnseenActivity,
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _greeting(l10n),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          Icon(
                            Icons.bolt_outlined,
                            size: 29,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              '${settings.readingStreak}',
                              key: ValueKey(settings.readingStreak),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 18),
                          const Icon(
                            Icons.notifications_none_rounded,
                            size: 29,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _VerseCard(reference: _todayVerse),
                      const SizedBox(height: 18),
                      _ContinueCard(surah: lastSurah, ayah: settings.lastAyah),
                      const SizedBox(height: 18),
                      const HomePrayerCard(),
                      const SizedBox(height: 18),
                      _InfoCard(
                        eyebrow: l10n.text('todayFiveMinutes'),
                        title: l10n.text('spendTimeQuran'),
                        button: l10n.text('minutes46'),
                        icon: Icons.auto_awesome_outlined,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.text('moreForYou'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 18),
                      _ReadingPlanHomeCard(
                        loading: _readingPlanLoading,
                        snapshot: _readingPlanSnapshot,
                        onOpenPlans: _openPlans,
                        onReadToday: _openReadingPlanDay,
                      ),
                    ],
                  )
                : const _CommunityFeed(),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(
    String text,
    int index,
    AppSettings settings, {
    bool showDot = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => _selectTab(index, settings),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(left: 7, top: 2),
                width: showDot ? 8 : 0,
                height: showDot ? 8 : 0,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: showDot
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: .55),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 88 : 0,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseCard extends StatefulWidget {
  const _VerseCard({required this.reference});

  final (int, int) reference;

  @override
  State<_VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<_VerseCard> {
  bool _expanded = false;

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  void _openReader() {
    HapticFeedback.selectionClick();
    AppNavigation.instance.openReader(
      surah: widget.reference.$1,
      ayah: widget.reference.$2,
    );
  }

  Future<String?> _preferredTranslationVerse(String sourceId) async {
    if (sourceId == arabicOriginalSourceId) return null;
    final verses = await TranslationRepository.instance.loadSourceVerses(
      sourceId,
    );
    return verses['${widget.reference.$1}:${widget.reference.$2}'];
  }

  String _surahNameForLanguage(int surahNumber, String languageCode) =>
      localizedSurahName(surahNumber, languageCode);

  @override
  Widget build(BuildContext context) {
    final reference = widget.reference;
    final surah = surahByNumber(reference.$1);
    final settings = AppSettingsScope.of(context);
    final l10n = context.l10n;
    final languageCode = l10n.locale.languageCode;
    final homeSourceId = settings.quranSourceWasUserSelected
        ? settings.selectedQuranSourceId
        : defaultQuranSourceForLanguage(languageCode);
    final translation = translationById(homeSourceId);
    final sourceCode = homeSourceId == arabicOriginalSourceId
        ? 'AR'
        : translation?.code ?? 'RWD';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF315348), Color(0xFF182B25)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.text('dailyVerse'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_surahNameForLanguage(surah.number, languageCode)} ${reference.$1}:${reference.$2} · $sourceCode',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: _expanded ? .5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Text(
                  quran.getVerse(reference.$1, reference.$2),
                  maxLines: _expanded ? null : 4,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'serif',
                    fontSize: 27,
                    height: 1.8,
                  ),
                ),
              ),
              if (homeSourceId != arabicOriginalSourceId) ...[
                const SizedBox(height: 18),
                FutureBuilder<String?>(
                  future: _preferredTranslationVerse(homeSourceId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        l10n.text('translationUnavailable'),
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      );
                    }
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Text(
                        snapshot.data ?? l10n.text('translationLoading'),
                        key: ValueKey(
                          '${settings.selectedQuranSourceId}:${snapshot.data}',
                        ),
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                    color: Colors.white70,
                    size: 19,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _expanded ? l10n.homeVerseCollapse : l10n.homeVerseExpand,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openReader,
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(l10n.homeVerseReadSurah),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF183027),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(Icons.bookmark_border_rounded, l10n.text('save')),
                  _Stat(Icons.headphones_outlined, l10n.text('listen')),
                  _Stat(Icons.ios_share_outlined, l10n.text('share')),
                  _Stat(Icons.more_horiz, l10n.text('more')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.surah, required this.ayah});

  final SurahInfo surah;
  final int ayah;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.selectionClick();
          AppNavigation.instance.openReader(surah: surah.number, ayah: ayah);
        },
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(Icons.menu_book_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.text('continueReading'),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${surah.nameTr} ${surah.number}:$ayah',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 23, color: Colors.white),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}

class _ReadingPlanHomeCard extends StatelessWidget {
  const _ReadingPlanHomeCard({
    required this.loading,
    required this.snapshot,
    required this.onOpenPlans,
    required this.onReadToday,
  });

  final bool loading;
  final ReadingPlanSnapshot snapshot;
  final VoidCallback onOpenPlans;
  final VoidCallback onReadToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = snapshot.active;
    if (loading || active == null) {
      return _InfoCard(
        eyebrow: l10n.text('needPlaceToStart'),
        title: l10n.text('choosePlanHelp'),
        button: l10n.text('explorePlans'),
        icon: Icons.route_outlined,
        onTap: onOpenPlans,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final day = active.nextDay;
    final dayText = day == null
        ? l10n.text('myPlans')
        : l10n
            .text('plansDayProgressV1')
            .replaceAll('{day}', '${day.dayNumber}')
            .replaceAll('{total}', '${active.preset.durationDays}');
    final pagesText = day == null
        ? l10n.text('plansPlanCompletedV1')
        : l10n
            .text('plansPagesV1')
            .replaceAll('{start}', '${day.startPage}')
            .replaceAll('{end}', '${day.endPage}');
    final progressText = l10n
        .text('plansProgressV1')
        .replaceAll('{done}', '${active.completedPrefixDays}')
        .replaceAll('{total}', '${active.preset.durationDays}');
    final schedule = active.scheduleStatus(DateTime.now());
    final scheduleText = active.isPaused
        ? l10n.text('plansPausedV1')
        : schedule.isBehind
        ? l10n
            .text('plansScheduleBehindV1')
            .replaceAll('{count}', '${schedule.behindByDays}')
        : schedule.isAhead
            ? l10n
                .text('plansScheduleAheadV1')
                .replaceAll('{count}', '${schedule.aheadByDays}')
            : l10n.text('plansScheduleOnTrackV1');

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onOpenPlans,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(Icons.route_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.today,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.text(active.preset.titleKey),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$dayText · $pagesText',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: active.progress.clamp(0, 1)),
              const SizedBox(height: 7),
              Text(
                '$progressText · $scheduleText',
                style: TextStyle(
                  color: active.isPaused
                      ? scheme.primary
                      : schedule.isBehind
                      ? scheme.error
                      : scheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: active.isPaused || schedule.isBehind
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: day == null ? onOpenPlans : onReadToday,
                  icon: Icon(
                    day == null
                        ? Icons.route_outlined
                        : Icons.menu_book_rounded,
                  ),
                  label: Text(
                    l10n.text(day == null ? 'myPlans' : 'plansReadTodayV1'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.eyebrow,
    required this.title,
    required this.button,
    required this.icon,
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String button;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        child: Text(
                          button,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: 88,
                child: Icon(icon, size: 54, color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityFeed extends StatelessWidget {
  const _CommunityFeed();

  String _text(String languageCode, String key) {
    const values = <String, Map<String, String>>{
      'tr': {
        'title': 'Senin etkinliklerin',
        'body':
            'Kaydettiğin, vurguladığın ve not aldığın ayetler burada görünür. Arkadaş sistemi geldiğinde bu akış arkadaş etkinliklerini de gösterebilir.',
        'empty':
            'Henüz bir etkinlik yok. Bir ayet kaydettiğinde, vurguladığında veya not eklediğinde burada görünecek.',
        'bookmark': 'Bir ayeti kaydettin',
        'highlight': 'Bir ayeti vurguladın',
        'note': 'Bir ayete not ekledin',
      },
      'en': {
        'title': 'Your activity',
        'body':
            'Verses you save, highlight or annotate appear here. When friends arrive, this feed can also include their activity.',
        'empty':
            'No activity yet. Save, highlight or add a note to a verse and it will appear here.',
        'bookmark': 'You saved a verse',
        'highlight': 'You highlighted a verse',
        'note': 'You added a note to a verse',
      },
      'ar': {
        'title': 'نشاطك',
        'body':
            'تظهر هنا الآيات التي تحفظها أو تميزها أو تضيف إليها ملاحظات. وعند إضافة الأصدقاء يمكن أن يعرض هذا القسم نشاطهم أيضاً.',
        'empty': 'لا يوجد نشاط بعد. احفظ آية أو ميزها أو أضف ملاحظة لتظهر هنا.',
        'bookmark': 'حفظت آية',
        'highlight': 'ميزت آية',
        'note': 'أضفت ملاحظة إلى آية',
      },
      'az': {
        'title': 'Sənin fəaliyyətin',
        'body':
            'Yadda saxladığın, vurğuladığın və qeyd əlavə etdiyin ayələr burada görünür. Dost sistemi gələndə bu axın onların fəaliyyətini də göstərə bilər.',
        'empty':
            'Hələ fəaliyyət yoxdur. Ayəni yadda saxla, vurğula və ya qeyd əlavə et.',
        'bookmark': 'Bir ayəni yadda saxladın',
        'highlight': 'Bir ayəni vurğuladın',
        'note': 'Bir ayəyə qeyd əlavə etdin',
      },
      'ru': {
        'title': 'Ваша активность',
        'body':
            'Здесь появляются сохранённые и выделенные аяты и заметки. После появления друзей лента сможет показывать и их активность.',
        'empty':
            'Пока активности нет. Сохраните или выделите аят либо добавьте заметку.',
        'bookmark': 'Вы сохранили аят',
        'highlight': 'Вы выделили аят',
        'note': 'Вы добавили заметку к аяту',
      },
    };
    return values[languageCode]?[key] ?? values['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final languageCode = context.l10n.locale.languageCode;
    final items = <_ActivityItem>[
      for (final key in settings.bookmarkKeys)
        _ActivityItem(
          kind: 'bookmark',
          selectionKey: key,
          timestamp: settings.archiveTimestamp('bookmark', key),
        ),
      for (final key in settings.highlightEntries.keys)
        _ActivityItem(
          kind: 'highlight',
          selectionKey: key,
          timestamp: settings.archiveTimestamp('highlight', key),
        ),
      for (final entry in settings.noteEntries.entries)
        _ActivityItem(
          kind: 'note',
          selectionKey: entry.key,
          timestamp: settings.archiveTimestamp('note', entry.key),
          note: entry.value,
        ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt_outlined, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _text(languageCode, 'title'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _text(languageCode, 'body'),
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              _text(languageCode, 'empty'),
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
            ),
          )
        else
          for (final item in items.take(30)) ...[
            _ActivityCard(item: item, title: _text(languageCode, item.kind)),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.kind,
    required this.selectionKey,
    required this.timestamp,
    this.note,
  });

  final String kind;
  final String selectionKey;
  final int timestamp;
  final String? note;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item, required this.title});

  final _ActivityItem item;
  final String title;

  (int, int)? _target() {
    final separator = item.selectionKey.indexOf(':');
    if (separator <= 0) return null;
    final surah = int.tryParse(item.selectionKey.substring(0, separator));
    if (surah == null || surah < 1 || surah > 114) return null;
    final ayahPart = item.selectionKey.substring(separator + 1);
    final firstPart = ayahPart.split(RegExp(r'[-,]')).first;
    final ayah = int.tryParse(firstPart);
    if (ayah == null || ayah < 1) return null;
    return (surah, ayah);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final target = _target();
    final icon = switch (item.kind) {
      'highlight' => Icons.format_color_fill_rounded,
      'note' => Icons.sticky_note_2_outlined,
      _ => Icons.bookmark_added_outlined,
    };
    final reference = target == null
        ? item.selectionKey
        : '${surahByNumber(target.$1).nameTr} ${item.selectionKey}';

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: target == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                AppNavigation.instance.openReader(
                  surah: target.$1,
                  ayah: target.$2,
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.primary, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reference,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.note?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.note!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
