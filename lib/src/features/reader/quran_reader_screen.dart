import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../../data/surah_catalog.dart';
import '../../settings/app_settings.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  int _surahNumber = 1;
  bool _didRestorePosition = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRestorePosition) return;
    _surahNumber = AppSettingsScope.of(context).lastSurah;
    _didRestorePosition = true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surah = surahByNumber(_surahNumber);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 15, 10),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _segment('${surah.nameTr} ${surah.number}', _showSurahs),
                        Container(
                          width: 1,
                          height: 48,
                          color: scheme.outline.withValues(alpha: .28),
                        ),
                        _segment('AR', _showTranslations),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showSurahs,
                  icon: const Icon(Icons.search_rounded, size: 29),
                  tooltip: 'Sure ara',
                ),
                IconButton(
                  onPressed: _showReaderMenu,
                  icon: const Icon(Icons.more_horiz_rounded, size: 30),
                  tooltip: 'Okuma ayarları',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              key: ValueKey(_surahNumber),
              padding: const EdgeInsets.fromLTRB(26, 40, 26, 140),
              itemCount: surah.verseCount + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _surahHeader(surah);
                return _Verse(
                  surahNumber: _surahNumber,
                  ayahNumber: index,
                  arabic: quran.getVerse(_surahNumber, index),
                  onTap: () => _openVerseActions(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _surahHeader(SurahInfo surah) {
    final scheme = Theme.of(context).colorScheme;
    final hasSeparateBasmala = surah.number != 1 && surah.number != 9;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          Text(
            surah.nameTr,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'serif',
                  fontSize: 34,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            surah.nameAr,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 23,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${surah.verseCount} ayet',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasSeparateBasmala) ...[
            const SizedBox(height: 34),
            Text(
              quran.basmala,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 25,
                height: 1.9,
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showReaderMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields_rounded),
                title: const Text('Yazı tipi ve okuma görünümü'),
                subtitle: const Text('Boyut, satır aralığı ve görünüm'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: const Text('Meal karşılaştır'),
                subtitle: const Text('Meal paketleri bağlandığında aktif olacak'),
                onTap: _showTranslations,
              ),
              const ListTile(
                leading: Icon(Icons.verified_outlined),
                title: Text('Arapça metin kaynağı'),
                subtitle: Text('Tanzil.net · çevrimdışı ve değiştirilmeden'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSurahs() async {
    final controller = TextEditingController();
    String query = '';

    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .92,
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final normalized = query.trim().toLowerCase();
              final filtered = normalized.isEmpty
                  ? surahCatalog
                  : surahCatalog.where((surah) {
                      return surah.nameTr.toLowerCase().contains(normalized) ||
                          surah.nameAr.contains(normalized) ||
                          surah.number.toString() == normalized;
                    }).toList(growable: false);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                        const Expanded(
                          child: Text(
                            'Sureler',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                    child: TextField(
                      controller: controller,
                      autofocus: false,
                      onChanged: (value) => setSheetState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Sure adı veya numara ara',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  controller.clear();
                                  setSheetState(() => query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final surah = filtered[index];
                        return _SurahRow(
                          surah: surah,
                          selected: surah.number == _surahNumber,
                          onTap: () => Navigator.pop(sheetContext, surah.number),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  _LastReadTile(
                    onTap: () {
                      final last = AppSettingsScope.of(context).lastSurah;
                      Navigator.pop(sheetContext, last);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    controller.dispose();
    if (picked == null || !mounted) return;
    setState(() => _surahNumber = picked);
    await AppSettingsScope.of(context).saveReadingPosition(
      surah: picked,
      ayah: 1,
    );
  }

  Future<void> _showTranslations() async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mealler',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'Arapça Kuran metni çevrimdışı hazır. Türkçe ve diğer diller için yalnızca yeniden dağıtım ve ticari kullanım izni doğrulanmış mealler eklenecek.',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.download_done_rounded),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paket sistemi hazır olacak',
                            style: TextStyle(fontWeight: FontWeight.w850),
                          ),
                          SizedBox(height: 3),
                          Text('Bir kez indir, internetsiz oku.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVerseActions(int ayahNumber) async {
    await AppSettingsScope.of(context).saveReadingPosition(
      surah: _surahNumber,
      ayah: ayahNumber,
    );
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${surahByNumber(_surahNumber).nameTr} $_surahNumber:$ayahNumber',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ActionChip(Icons.bookmark_border_rounded, 'Kaydet'),
                  _ActionChip(Icons.palette_outlined, 'Renklendir'),
                  _ActionChip(Icons.note_alt_outlined, 'Not'),
                  _ActionChip(Icons.headphones_outlined, 'Dinle'),
                  _ActionChip(Icons.ios_share_outlined, 'Paylaş'),
                  _ActionChip(Icons.auto_stories_outlined, 'Tefsir'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Verse extends StatelessWidget {
  const _Verse({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.onTap,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 29,
                height: 2.05,
              ),
            ),
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$surahNumber:$ayahNumber',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.selected,
    required this.onTap,
  });

  final SurahInfo surah;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        leading: SizedBox(
          width: 34,
          child: Text(
            '${surah.number}',
            style: TextStyle(
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          surah.nameTr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${surah.verseCount} ayet'),
        trailing: Text(
          surah.nameAr,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'serif', fontSize: 20),
        ),
      ),
    );
  }
}

class _LastReadTile extends StatelessWidget {
  const _LastReadTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final surah = surahByNumber(settings.lastSurah);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Son okunan',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.nameTr} ${settings.lastSurah}:${settings.lastAyah}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
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

class _ActionChip extends StatelessWidget {
  const _ActionChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
