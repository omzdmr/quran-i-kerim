import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'travel_dietary_card_store.dart';

class TravelDietaryPresentationScreen extends StatelessWidget {
  const TravelDietaryPresentationScreen({required this.card, super.key});
  final TravelDietaryCard card;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final copyLabel = _copyLabel[locale] ?? _copyLabel['en']!;
    final closeLabel = _closeLabel[locale] ?? _closeLabel['en']!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(card.languageLabel.isEmpty ? ' ' : card.languageLabel),
        actions: [IconButton(onPressed: () => Navigator.pop(context), tooltip: closeLabel, icon: const Icon(Icons.close_rounded))],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              container: true,
              liveRegion: true,
              label: card.staffText,
              child: ExcludeSemantics(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SelectableText(
                    card.staffText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.55),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: card.staffText));
                      HapticFeedback.selectionClick();
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(copyLabel),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _copyLabel = <String,String>{'tr':'Metni kopyala','en':'Copy text','fr':'Copier le texte','ar':'نسخ النص','az':'Mətni kopyala','ru':'Копировать текст'};
const _closeLabel = <String,String>{'tr':'Kapat','en':'Close','fr':'Fermer','ar':'إغلاق','az':'Bağla','ru':'Закрыть'};
