import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/strings/learn_reference_strings.dart';
import '../application/learn_reference_catalog.dart';
import 'article_grid.dart';

class LearnReferenceOverview extends StatelessWidget {
  const LearnReferenceOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final items = curatedLearnReferences.map((reference) {
      return LearnArticleCardData(
        id: reference.id,
        title: learnReferenceText(languageCode, reference.titleKey),
        summary: learnReferenceText(languageCode, reference.summaryKey),
        category: learnReferenceText(languageCode, 'learnReferenceCategoryV1'),
        icon: _iconFor(reference.id),
      );
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            learnReferenceText(languageCode, 'learnReferenceSectionBodyV1'),
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        LearnArticleSection(
          title: learnReferenceText(
            languageCode,
            'learnReferenceSectionTitleV1',
          ),
          items: items,
          previewCount: items.length,
          onOpen: (item) {
            final reference = curatedLearnReferences.firstWhere(
              (candidate) => candidate.id == item.id,
            );
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LearnReferenceScreen(reference: reference),
              ),
            );
          },
        ),
      ],
    );
  }
}

IconData _iconFor(String id) {
  return switch (id) {
    'quran-text-tanzil-v1' => Icons.menu_book_rounded,
    'translations-quranenc-v1' => Icons.translate_rounded,
    _ => Icons.fact_check_outlined,
  };
}

class LearnReferenceScreen extends StatelessWidget {
  const LearnReferenceScreen({
    required this.reference,
    super.key,
  });

  final LearnReferenceDefinition reference;

  Future<void> _openSource() async {
    final raw = reference.sourceUrl;
    if (raw == null) return;
    await launchUrl(Uri.parse(raw), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final title = learnReferenceText(languageCode, reference.titleKey);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
          children: [
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _iconFor(reference.id),
                  color: scheme.primary,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              learnReferenceText(languageCode, reference.summaryKey),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SelectableText(
                learnReferenceText(languageCode, reference.bodyKey),
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),
            if (reference.sourceUrl != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _openSource();
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(
                  learnReferenceText(
                    languageCode,
                    'learnReferenceOpenSourceV1',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
