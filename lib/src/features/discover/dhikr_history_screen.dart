import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'dhikr_history_store.dart';
import 'dhikr_labels.dart';

class DhikrHistoryScreen extends StatelessWidget {
  const DhikrHistoryScreen({super.key, required this.records});

  final List<DhikrDailyHistoryRecord> records;

  String _label(
    BuildContext context,
    DhikrDailyHistoryRecord record,
    String id,
  ) {
    final language = Localizations.localeOf(context).languageCode;
    return record.customLabels[id] ??
        dhikrBuiltInLabel(id, language, fallback: id);
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
                          Text(
                            record.dateKey,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.text('dhikrHistoryTotal')}: ${record.total}',
                            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800),
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
