import 'package:flutter/material.dart';

import '../../data/backup/backup_import_plan.dart';

class BackupRestoreImpactList extends StatelessWidget {
  const BackupRestoreImpactList({
    required this.plan,
    super.key,
  });

  final BackupImportPlan plan;

  @override
  Widget build(BuildContext context) {
    final copy = _ImpactCopy.forLocale(Localizations.localeOf(context));
    final changed = plan.changedSections;
    if (changed.isEmpty) {
      return Semantics(
        container: true,
        label: copy.noChanges,
        child: Text(copy.noChanges),
      );
    }

    return Semantics(
      container: true,
      label: copy.summary(changed.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final impact in changed)
            _ImpactRow(impact: impact, copy: copy),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.impact, required this.copy});

  final BackupSectionImpact impact;
  final _ImpactCopy copy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = copy.sectionLabel(impact.section);
    final detail = copy.detail(impact);
    final destructive = impact.localOnlyRecords > 0;

    return Semantics(
      container: true,
      label: '$label. $detail',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: destructive
                ? scheme.errorContainer.withValues(alpha: 0.35)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                destructive
                    ? Icons.warning_amber_rounded
                    : Icons.folder_copy_outlined,
                size: 20,
                color: destructive ? scheme.error : scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
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
}

class _ImpactCopy {
  const _ImpactCopy({
    required this.title,
    required this.noChanges,
    required this.sectionsChanged,
    required this.conflicts,
    required this.added,
    required this.deviceOnly,
    required this.labels,
  });

  final String title;
  final String noChanges;
  final String sectionsChanged;
  final String conflicts;
  final String added;
  final String deviceOnly;
  final Map<String, String> labels;

  String summary(int count) => sectionsChanged.replaceAll('{count}', '$count');

  String sectionLabel(String section) => labels[section] ?? section;

  String detail(BackupSectionImpact impact) => [
        if (impact.conflictingRecords > 0)
          '$conflicts: ${impact.conflictingRecords}',
        if (impact.incomingOnlyRecords > 0)
          '$added: ${impact.incomingOnlyRecords}',
        if (impact.localOnlyRecords > 0)
          '$deviceOnly: ${impact.localOnlyRecords}',
      ].join(' · ');

  static _ImpactCopy forLocale(Locale locale) =>
      _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, _ImpactCopy>{
  'tr': _ImpactCopy(
    title: 'Bölümlere göre değişiklikler',
    noChanges: 'Bu yedek cihazdaki kayıtları değiştirmiyor.',
    sectionsChanged: '{count} bölümde değişiklik var.',
    conflicts: 'Çakışan',
    added: 'Yedekten gelecek',
    deviceOnly: 'Yalnız cihazda',
    labels: {
      'reader': 'Okuma ve son konum',
      'bookmarks': 'Yer imleri',
      'notes': 'Notlar',
      'highlights': 'Vurgular',
      'hifz': 'Ezber ve tekrar',
      'plans': 'Planlar ve ilerleme',
      'fasting': 'Oruç kayıtları',
      'settings': 'Tercihler',
      'travel': 'Seyahat verileri',
    },
  ),
  'en': _ImpactCopy(
    title: 'Changes by section',
    noChanges: 'This backup does not change records on this device.',
    sectionsChanged: '{count} sections have changes.',
    conflicts: 'Conflicts',
    added: 'From backup',
    deviceOnly: 'Device only',
    labels: {
      'reader': 'Reading and last position',
      'bookmarks': 'Bookmarks',
      'notes': 'Notes',
      'highlights': 'Highlights',
      'hifz': 'Hifz and review',
      'plans': 'Plans and progress',
      'fasting': 'Fasting records',
      'settings': 'Preferences',
      'travel': 'Travel data',
    },
  ),
  'fr': _ImpactCopy(
    title: 'Modifications par section',
    noChanges: 'Cette sauvegarde ne modifie aucun enregistrement sur cet appareil.',
    sectionsChanged: '{count} sections comportent des modifications.',
    conflicts: 'Conflits',
    added: 'Depuis la sauvegarde',
    deviceOnly: 'Appareil seulement',
    labels: {
      'reader': 'Lecture et dernière position',
      'bookmarks': 'Signets',
      'notes': 'Notes',
      'highlights': 'Surlignages',
      'hifz': 'Mémorisation et révision',
      'plans': 'Plans et progression',
      'fasting': 'Jeûne',
      'settings': 'Préférences',
      'travel': 'Voyage',
    },
  ),
  'ar': _ImpactCopy(
    title: 'التغييرات حسب القسم',
    noChanges: 'هذه النسخة لا تغيّر سجلات هذا الجهاز.',
    sectionsChanged: 'توجد تغييرات في {count} أقسام.',
    conflicts: 'متعارضة',
    added: 'من النسخة',
    deviceOnly: 'على الجهاز فقط',
    labels: {
      'reader': 'القراءة وآخر موضع',
      'bookmarks': 'الإشارات المرجعية',
      'notes': 'الملاحظات',
      'highlights': 'التمييز',
      'hifz': 'الحفظ والمراجعة',
      'plans': 'الخطط والتقدم',
      'fasting': 'سجلات الصيام',
      'settings': 'التفضيلات',
      'travel': 'بيانات السفر',
    },
  ),
  'az': _ImpactCopy(
    title: 'Bölmələr üzrə dəyişikliklər',
    noChanges: 'Bu yedək cihazdakı qeydləri dəyişmir.',
    sectionsChanged: '{count} bölmədə dəyişiklik var.',
    conflicts: 'Ziddiyyətli',
    added: 'Yedəkdən gələcək',
    deviceOnly: 'Yalnız cihazda',
    labels: {
      'reader': 'Oxu və son mövqe',
      'bookmarks': 'Əlfəcinlər',
      'notes': 'Qeydlər',
      'highlights': 'Vurğular',
      'hifz': 'Əzbər və təkrar',
      'plans': 'Planlar və irəliləyiş',
      'fasting': 'Oruc qeydləri',
      'settings': 'Seçimlər',
      'travel': 'Səyahət məlumatları',
    },
  ),
  'ru': _ImpactCopy(
    title: 'Изменения по разделам',
    noChanges: 'Эта копия не изменяет записи на устройстве.',
    sectionsChanged: 'Изменения затрагивают разделы: {count}.',
    conflicts: 'Конфликты',
    added: 'Из копии',
    deviceOnly: 'Только на устройстве',
    labels: {
      'reader': 'Чтение и последняя позиция',
      'bookmarks': 'Закладки',
      'notes': 'Заметки',
      'highlights': 'Выделения',
      'hifz': 'Хифз и повторение',
      'plans': 'Планы и прогресс',
      'fasting': 'Записи поста',
      'settings': 'Настройки',
      'travel': 'Данные поездок',
    },
  ),
};
