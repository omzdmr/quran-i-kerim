import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'dhikr_history_store.dart';

class DhikrHistoryScreen extends StatelessWidget {
  const DhikrHistoryScreen({super.key, required this.records});

  final List<DhikrDailyHistoryRecord> records;

  String _label(
    BuildContext context,
    DhikrDailyHistoryRecord record,
    String id,
  ) {
    final language = Localizations.localeOf(context).languageCode;
    const builtIns = <String, Map<String, String>>{
      'subhanallah': <String, String>{'tr': 'Sübhanallah', 'en': 'SubhanAllah', 'fr': 'SubhanAllah', 'ar': 'سبحان الله', 'az': 'Sübhanallah', 'ru': 'Субханаллах'},
      'alhamdulillah': <String, String>{'tr': 'Elhamdülillah', 'en': 'Alhamdulillah', 'fr': 'Alhamdulillah', 'ar': 'الحمد لله', 'az': 'Əlhəmdülillah', 'ru': 'Альхамдулиллях'},
      'allahu_akbar': <String, String>{'tr': 'Allahu Ekber', 'en': 'Allahu Akbar', 'fr': 'Allahu Akbar', 'ar': 'الله أكبر', 'az': 'Allahu Əkbər', 'ru': 'Аллаху Акбар'},
      'salawat': <String, String>{'tr': 'Salavat', 'en': 'Salawat', 'fr': 'Salawat', 'ar': 'الصلاة على النبي', 'az': 'Salavat', 'ru': 'Салават'},
    };
    return builtIns[id]?[language] ??
        builtIns[id]?['en'] ??
        record.customLabels[id] ??
        id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('dhikrHistory'))),
      body: records.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  l10n.text('dhikrHistoryEmpty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              itemCount: records.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    l10n.text('dhikrHistorySubtitle'),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  );
                }
                final record = records[index - 1];
                final items = record.counts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                return Semantics(
                  container: true,
                  label: '${record.dateKey}, ${l10n.text('dhikrHistoryTotal')} ${record.total}',
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  record.dateKey,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                '${l10n.text('dhikrHistoryTotal')}: ${record.total}',
                                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final item in items)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Expanded(child: Text(_label(context, record, item.key))),
                                  Text('${item.value}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
