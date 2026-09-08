import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../data/surah_catalog.dart';
import '../../data/translation_catalog.dart';
import '../../data/translation_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../navigation/app_navigation.dart';
import '../../settings/app_settings.dart';

class PassagePreviewScreen extends StatelessWidget {
  const PassagePreviewScreen({
    required this.selectionKey,
    this.sourceCode,
    super.key,
  });

  final String selectionKey;
  final String? sourceCode;

  (int, List<int>)? _parseSelection() {
    final separator = selectionKey.indexOf(':');
    if (separator < 1 || separator == selectionKey.length - 1) return null;
    final surah = int.tryParse(selectionKey.substring(0, separator));
    if (surah == null || surah < 1 || surah > 114) return null;

    final part = selectionKey.substring(separator + 1);
    final ayahs = <int>[];
    if (part.contains('-')) {
      final bounds = part.split('-');
      if (bounds.length != 2) return null;
      final start = int.tryParse(bounds.first);
      final end = int.tryParse(bounds.last);
      if (start == null || end == null || start < 1 || end < start) return null;
      ayahs.addAll([for (var value = start; value <= end; value++) value]);
    } else if (part.contains(',')) {
      for (final raw in part.split(',')) {
        final value = int.tryParse(raw);
        if (value == null || value < 1) return null;
        ayahs.add(value);
      }
    } else {
      final value = int.tryParse(part);
      if (value == null || value < 1) return null;
      ayahs.add(value);
    }
    return ayahs.isEmpty ? null : (surah, ayahs);
  }

  String _sourceId(AppSettings settings) {
    final code = sourceCode?.trim();
    if (code == null || code.isEmpty) return settings.selectedQuranSourceId;
    if (code == 'AR') return arabicOriginalSourceId;
    for (final info in translationCatalog) {
      if (info.code == code) return info.id;
    }
    return bundledTurkishTranslationId;
  }

  String _sourceLabel(String sourceId) {
    if (sourceId == arabicOriginalSourceId) return 'AR';
    return translationById(sourceId)?.code ?? 'RWD';
  }

  String _reference(BuildContext context, int surah, List<int> ayahs) {
    final info = surahByNumber(surah);
    final name = Localizations.localeOf(context).languageCode == 'ar'
        ? info.nameAr
        : info.nameTr;
    final part = ayahs.length == 1
        ? '${ayahs.single}'
        : _contiguous(ayahs)
        ? '${ayahs.first}-${ayahs.last}'
        : ayahs.join(',');
    return '$name $surah:$part';
  }

  bool _contiguous(List<int> ayahs) {
    for (var i = 1; i < ayahs.length; i++) {
      if (ayahs[i] != ayahs[i - 1] + 1) return false;
    }
    return true;
  }

  String _uiText(String languageCode, String key) {
    const values = <String, Map<String, String>>{
      'tr': {
        'title': 'Ayet görünümü',
        'read': 'Surenin tamamını oku',
        'source': 'Metin kaynağı',
        'unavailable': 'Bu metin şu anda cihazda kullanılamıyor.',
      },
      'en': {
        'title': 'Passage',
        'read': 'Read the full surah',
        'source': 'Text source',
        'unavailable': 'This text is not available on this device right now.',
      },
      'ar': {
        'title': 'المقطع',
        'read': 'قراءة السورة كاملة',
        'source': 'مصدر النص',
        'unavailable': 'هذا النص غير متاح على الجهاز حالياً.',
      },
      'az': {
        'title': 'Ayə görünüşü',
        'read': 'Surəni tam oxu',
        'source': 'Mətn mənbəyi',
        'unavailable': 'Bu mətn hazırda cihazda mövcud deyil.',
      },
      'ru': {
        'title': 'Отрывок',
        'read': 'Читать суру полностью',
        'source': 'Источник текста',
        'unavailable': 'Этот текст сейчас недоступен на устройстве.',
      },
    };
    return values[languageCode]?[key] ?? values['en']![key]!;
  }

  Future<Map<String, String>> _loadTranslation(String sourceId) async {
    if (sourceId == arabicOriginalSourceId) return const <String, String>{};
    return TranslationRepository.instance.loadSourceVerses(sourceId);
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseSelection();
    if (parsed == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Invalid passage')),
      );
    }

    final settings = AppSettingsScope.of(context);
    final languageCode = context.l10n.locale.languageCode;
    final sourceId = _sourceId(settings);
    final sourceInfo = translationById(sourceId);
    final reference = _reference(context, parsed.$1, parsed.$2);
    final isArabic = sourceId == arabicOriginalSourceId;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_uiText(languageCode, 'title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 38),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reference,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _sourceLabel(sourceId),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FutureBuilder<Map<String, String>>(
              future: _loadTranslation(sourceId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    _uiText(languageCode, 'unavailable'),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  );
                }
                if (!isArabic && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                final map = snapshot.data ?? const <String, String>{};
                final children = <InlineSpan>[];
                for (final ayah in parsed.$2) {
                  final text = isArabic
                      ? quran.getVerse(parsed.$1, ayah)
                      : map['${parsed.$1}:$ayah'];
                  if (text == null || text.trim().isEmpty) continue;
                  children.add(
                    TextSpan(
                      text: '$ayah ',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                  children.add(TextSpan(text: '$text '));
                }
                return SelectableText.rich(
                  TextSpan(children: children),
                  textDirection: isArabic ? TextDirection.rtl : null,
                  textAlign: isArabic ? TextAlign.right : TextAlign.start,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontFamily: 'serif',
                    fontSize: settings.readerTextSize + 2,
                    height: isArabic
                        ? settings.arabicLineHeight
                        : settings.translationLineHeight,
                  ),
                );
              },
            ),
            const SizedBox(height: 34),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  AppNavigation.instance.openReader(
                    surah: parsed.$1,
                    ayah: parsed.$2.first,
                  );
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _uiText(languageCode, 'read'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 18),
            Text(
              _uiText(languageCode, 'source'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'Tanzil.net · CC BY 3.0'
                  : '${sourceInfo?.publisher ?? ''}\n${sourceInfo?.source ?? ''} · ${sourceInfo?.version ?? ''}',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
