import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/surah_catalog.dart';
import '../../data/translation_catalog.dart';
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
    final settings = AppSettingsScope.of(context);

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
                  arabicFontSize: settings.arabicFontSize,
                  bookmarked: settings.isBookmarked(_surahNumber, index),
                  hasNote: settings.noteFor(_surahNumber, index)?.isNotEmpty ?? false,
                  onTap: () => _openVerseActions(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, VoidCallback onTap) => InkWell(
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
              style: const TextStyle(fontFamily: 'serif', fontSize: 25, height: 1.9),
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
                subtitle: const Text('Arapça boyutu ve görünüm ayarları'),
                onTap: () {
                  Navigator.pop(context);
                  _showReadingAppearance();
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: const Text('Meal seç'),
                subtitle: const Text('İlk Türkçe meal paketi hazırlanıyor'),
                onTap: () {
                  Navigator.pop(context);
                  _showTranslations();
                },
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

  Future<void> _showReadingAppearance() async {
    final settings = AppSettingsScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Okuma görünümü', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(child: Text('Arapça yazı boyutu', style: TextStyle(fontWeight: FontWeight.w800))),
                    Text(settings.arabicFontSize.round().toString()),
                  ],
                ),
                Slider(
                  min: 22,
                  max: 42,
                  divisions: 20,
                  value: settings.arabicFontSize,
                  onChanged: (value) {
                    settings.setArabicFontSize(value);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 10),
                const _ModePreview(
                  title: 'Arapça',
                  subtitle: 'Şu an aktif',
                  selected: true,
                ),
                const _ModePreview(
                  title: 'Arapça + meal',
                  subtitle: 'Türkçe meal paketi eklenince açılacak',
                ),
                const _ModePreview(
                  title: 'Sadece meal',
                  subtitle: 'Türkçe meal paketi eklenince açılacak',
                ),
              ],
            ),
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
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
    await AppSettingsScope.of(context).saveReadingPosition(surah: picked, ayah: 1);
  }

  Future<void> _showTranslations() async {
    final scheme = Theme.of(context).colorScheme;
    final candidate = translationCatalog.first;

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
              const Text('Mealler', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${candidate.code} · ${candidate.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text('${candidate.publisher} · ${candidate.source} · v${candidate.version}'),
                        ],
                      ),
                    ),
                    const Icon(Icons.schedule_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Meal metnini lisans ve sürüm bilgisiyle birlikte paketliyoruz. Hazır olmadan başka bir metni Diyanet diye göstermeyeceğiz.',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openVerseActions(int ayahNumber) async {
    final settings = AppSettingsScope.of(context);
    await settings.saveReadingPosition(surah: _surahNumber, ayah: ayahNumber);
    if (!mounted) return;

    final surah = surahByNumber(_surahNumber);
    final arabic = quran.getVerse(_surahNumber, ayahNumber);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final saved = settings.isBookmarked(_surahNumber, ayahNumber);
        final hasNote = settings.noteFor(_surahNumber, ayahNumber)?.isNotEmpty ?? false;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${surah.nameTr} $_surahNumber:$ayahNumber',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ActionChip(
                      saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      saved ? 'Kaydedildi' : 'Kaydet',
                      onTap: () async {
                        await settings.toggleBookmark(_surahNumber, ayahNumber);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                    ),
                    _ActionChip(
                      hasNote ? Icons.note_alt_rounded : Icons.note_alt_outlined,
                      hasNote ? 'Notu düzenle' : 'Not',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _editNote(ayahNumber);
                      },
                    ),
                    _ActionChip(
                      Icons.copy_rounded,
                      'Kopyala',
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: '$arabic\n\n${surah.nameTr} $_surahNumber:$ayahNumber'));
                        if (!mounted) return;
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayet kopyalandı')));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editNote(int ayahNumber) async {
    final settings = AppSettingsScope.of(context);
    final controller = TextEditingController(text: settings.noteFor(_surahNumber, ayahNumber) ?? '');

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${surahByNumber(_surahNumber).nameTr} $_surahNumber:$ayahNumber için not'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Notunuzu yazın'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Kaydet')),
        ],
      ),
    );

    controller.dispose();
    if (value != null) await settings.setNote(_surahNumber, ayahNumber, value);
  }
}

class _Verse extends StatelessWidget {
  const _Verse({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.arabicFontSize,
    required this.bookmarked,
    required this.hasNote,
    required this.onTap,
  });

  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final double arabicFontSize;
  final bool bookmarked;
  final bool hasNote;
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
              style: TextStyle(fontFamily: 'serif', fontSize: arabicFontSize, height: 2.02),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (bookmarked) Icon(Icons.bookmark_rounded, size: 17, color: scheme.primary),
                if (bookmarked && hasNote) const SizedBox(width: 5),
                if (hasNote) Icon(Icons.note_alt_rounded, size: 17, color: scheme.primary),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$surahNumber:$ayahNumber',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModePreview extends StatelessWidget {
  const _ModePreview({required this.title, required this.subtitle, this.selected = false});

  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(selected ? Icons.check_circle_rounded : Icons.lock_outline_rounded, color: selected ? scheme.primary : scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.surah, required this.selected, required this.onTap});

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
            style: TextStyle(color: selected ? scheme.primary : scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(surah.nameTr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        subtitle: Text('${surah.verseCount} ayet'),
        trailing: Text(surah.nameAr, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'serif', fontSize: 20)),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(this.icon, this.label, {required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 19),
        label: Text(label),
        onPressed: onTap,
      );
}
