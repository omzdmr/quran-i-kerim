import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/surah_catalog.dart';
import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';
import 'home_prayer_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

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

  (int, int) get _todayVerse {
    final now = DateTime.now();
    final day = now.difference(DateTime(now.year)).inDays;
    return _dailyVerseRefs[day % _dailyVerseRefs.length];
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = AppSettingsScope.of(context);
    final lastSurah = surahByNumber(settings.lastSurah);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 4),
            child: Row(
              children: [
                _tabButton('Bugün', 0),
                const SizedBox(width: 28),
                _tabButton('Topluluk', 1),
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
                              _greeting,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          Icon(Icons.bolt_outlined, size: 29, color: scheme.primary),
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
                          const Icon(Icons.notifications_none_rounded, size: 29),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _VerseCard(reference: _todayVerse),
                      const SizedBox(height: 18),
                      _ContinueCard(surah: lastSurah, ayah: settings.lastAyah),
                      const SizedBox(height: 18),
                      const HomePrayerCard(),
                      const SizedBox(height: 18),
                      const _InfoCard(
                        eyebrow: 'Bugünün 5 Dakikası',
                        title: 'Bugün Kuran ile biraz zaman geçirin.',
                        button: '4–6 dakika',
                        icon: Icons.auto_awesome_outlined,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Sizin için daha fazlası',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 18),
                      const _InfoCard(
                        eyebrow: 'Başlayacak bir yere mi ihtiyacınız var?',
                        title: 'Kuran’da zaman geçirmenize yardımcı olacak bir plan seçin.',
                        button: 'Planları keşfet',
                        icon: Icons.route_outlined,
                      ),
                    ],
                  )
                : const _CommunityPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Column(
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

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.reference});

  final (int, int) reference;

  void _openReader() {
    HapticFeedback.selectionClick();
    AppNavigation.instance.openReader(surah: reference.$1, ayah: reference.$2);
  }

  @override
  Widget build(BuildContext context) {
    final surah = surahByNumber(reference.$1);
    final translation = translationCatalog.first;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 330),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openReader,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
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
                const Text('Günün Ayeti', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  '${surah.nameTr} ${reference.$1}:${reference.$2} · ${translation.code}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  quran.getVerse(reference.$1, reference.$2),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'serif',
                    fontSize: 27,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 18),
                FutureBuilder<String?>(
                  future: TranslationRepository.instance.turkishVerse(
                    reference.$1,
                    reference.$2,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        'Türkçe meal şu anda gösterilemiyor.',
                        style: TextStyle(color: Colors.white70, height: 1.5),
                      );
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        snapshot.data ?? 'Meal yükleniyor…',
                        key: ValueKey(snapshot.data),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(Icons.bookmark_border_rounded, 'Kaydet'),
                    _Stat(Icons.headphones_outlined, 'Dinle'),
                    _Stat(Icons.ios_share_outlined, 'Paylaş'),
                    _Stat(Icons.more_horiz, 'Daha fazla'),
                  ],
                ),
              ],
            ),
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
                      'Kaldığınız yerden devam edin',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${surah.nameTr} ${surah.number}:$ayah',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.eyebrow,
    required this.title,
    required this.button,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String button;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow, style: TextStyle(color: scheme.onSurfaceVariant)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
          SizedBox(width: 88, child: Icon(icon, size: 54, color: scheme.primary)),
        ],
      ),
    );
  }
}

class _CommunityPlaceholder extends StatelessWidget {
  const _CommunityPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 72, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Birlikte okumak',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              Text(
                'Özel arkadaş grupları ve birlikte okuma planları daha sonraki sürümlerde burada yer alacak.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 17,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
