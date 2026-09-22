import 'package:flutter/material.dart';

import '../../data/backup/backup_import_plan.dart';
import '../../data/backup/backup_preview.dart';
import '../../data/backup/local_backup_service.dart';
import 'backup_restore_impact_list.dart';

class BackupRestoreDialog extends StatefulWidget {
  const BackupRestoreDialog({super.key, required this.preview, required this.plan});
  final BackupPreview preview;
  final BackupImportPlan plan;

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  BackupRestoreMode _mode = BackupRestoreMode.merge;

  Future<void> _continue(BackupRestoreCopy copy) async {
    if (_mode == BackupRestoreMode.replace && widget.plan.localOnlyRecords > 0) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(copy.replaceConfirmTitle),
              content: Text(copy.replaceConfirmBody(widget.plan.localOnlyRecords)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(copy.replaceTitle),
                ),
              ],
            ),
          ) ??
          false;
      if (!mounted || !confirmed) return;
    }
    Navigator.of(context).pop(_mode);
  }

  @override
  Widget build(BuildContext context) {
    final copy = BackupRestoreCopy.forLocale(Localizations.localeOf(context));
    final scheme = Theme.of(context).colorScheme;
    final plan = widget.plan;
    return AlertDialog(
      title: Text(copy.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.intro),
            const SizedBox(height: 10),
            Semantics(
              container: true,
              label: copy.previewSemantics(widget.preview, context),
              child: ExcludeSemantics(child: Text(copy.previewSummary(widget.preview, context), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600))),
            ),
            const SizedBox(height: 16),
            Semantics(
              container: true,
              label: copy.summarySemantics(plan),
              child: ExcludeSemantics(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CountChip(icon: Icons.call_merge_rounded, label: copy.conflicts, count: plan.conflictingRecords, emphasized: plan.hasConflicts),
                    _CountChip(icon: Icons.download_done_rounded, label: copy.incomingOnly, count: plan.incomingOnlyRecords),
                    _CountChip(icon: Icons.phone_android_rounded, label: copy.localOnly, count: plan.localOnlyRecords),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            BackupRestoreImpactList(plan: plan, mode: _mode),
            const SizedBox(height: 16),
            Semantics(
              container: true,
              label: copy.safetyNote,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.shield_outlined, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(child: Text(copy.safetyNote, style: TextStyle(color: scheme.onPrimaryContainer))),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            Text(copy.chooseMode, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            RadioListTile<BackupRestoreMode>(contentPadding: EdgeInsets.zero, groupValue: _mode, value: BackupRestoreMode.merge, onChanged: (value) { if (value != null) setState(() => _mode = value); }, title: Text(copy.mergeTitle), subtitle: Text(copy.mergeBody)),
            RadioListTile<BackupRestoreMode>(contentPadding: EdgeInsets.zero, groupValue: _mode, value: BackupRestoreMode.replace, onChanged: (value) { if (value != null) setState(() => _mode = value); }, title: Text(copy.replaceTitle), subtitle: Text(copy.replaceBody)),
            if (_mode == BackupRestoreMode.replace) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
                  const SizedBox(width: 10),
                  Expanded(child: Text(copy.replaceWarning, style: TextStyle(color: scheme.onErrorContainer))),
                ]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
        FilledButton(onPressed: () => _continue(copy), child: Text(copy.continueLabel)),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.icon, required this.label, required this.count, this.emphasized = false});
  final IconData icon;
  final String label;
  final int count;
  final bool emphasized;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(avatar: Icon(icon, size: 18), label: Text('$label: $count'), backgroundColor: emphasized ? scheme.tertiaryContainer : null);
  }
}

class BackupRestoreCopy {
  const BackupRestoreCopy({required this.title, required this.intro, required this.conflicts, required this.incomingOnly, required this.localOnly, required this.safetyNote, required this.chooseMode, required this.mergeTitle, required this.mergeBody, required this.replaceTitle, required this.replaceBody, required this.replaceWarning, required this.replaceConfirmTitle, required this.replaceConfirmTemplate, required this.continueLabel, required this.backupLabel, required this.recordsLabel, required this.versionLabel});
  final String title, intro, conflicts, incomingOnly, localOnly, safetyNote, chooseMode, mergeTitle, mergeBody, replaceTitle, replaceBody, replaceWarning, replaceConfirmTitle, replaceConfirmTemplate, continueLabel, backupLabel, recordsLabel, versionLabel;
  String replaceConfirmBody(int count) => replaceConfirmTemplate.replaceAll('{count}', '$count');
  String summarySemantics(BackupImportPlan plan) => '$conflicts: ${plan.conflictingRecords}. $incomingOnly: ${plan.incomingOnlyRecords}. $localOnly: ${plan.localOnlyRecords}.';
  String previewSummary(BackupPreview preview, BuildContext context) {
    final createdAt = preview.createdAt?.toLocal();
    final date = createdAt == null ? '—' : '${MaterialLocalizations.of(context).formatMediumDate(createdAt)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(createdAt))}';
    return '$backupLabel: $date · $recordsLabel: ${preview.totalRecords} · $versionLabel: ${preview.version ?? '?'}';
  }
  String previewSemantics(BackupPreview preview, BuildContext context) => previewSummary(preview, context);
  static BackupRestoreCopy forLocale(Locale locale) => _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, BackupRestoreCopy>{
  'tr': BackupRestoreCopy(title: 'Yedeği nasıl geri yükleyelim?', intro: 'Dosya mevcut cihaz verinizle karşılaştırıldı. Devam etmeden önce neyin değişeceğini kontrol edin.', conflicts: 'Çakışan', incomingOnly: 'Yalnız yedekte', localOnly: 'Yalnız cihazda', safetyNote: 'Geri yüklemeden hemen önce mevcut verilerinizin otomatik güvenlik kopyası alınır. İşlem bittiğinde ekrandaki Geri al düğmesiyle önceki duruma hemen dönebilirsiniz; güvenlik kopyası ayrıca Son yedeklerde kalır.', chooseMode: 'Geri yükleme biçimi', mergeTitle: 'Birleştir', mergeBody: 'Cihazdaki verileri korur; yedekteki yeni ve güncel kayıtları üzerine ekler.', replaceTitle: 'Değiştir', replaceBody: 'Yedekte bulunan bölümleri yedekteki durumla değiştirir.', replaceWarning: 'Değiştir seçeneği, yedekte olmayan yerel kayıtları ilgili bölümlerden kaldırabilir.', replaceConfirmTitle: 'Cihazdaki kayıtlar kaldırılsın mı?', replaceConfirmTemplate: 'Bu yedek, Değiştir modunda yalnızca cihazda bulunan {count} kaydı kaldıracak. Geri yüklemeden önce güvenlik kopyası alınacak ve işlem sonrasında Geri al kullanılabilecek.', continueLabel: 'Devam et', backupLabel: 'Yedek', recordsLabel: 'kayıt', versionLabel: 'sürüm'),
  'en': BackupRestoreCopy(title: 'How should this backup be restored?', intro: 'The file was compared with data on this device. Review what will change before continuing.', conflicts: 'Conflicts', incomingOnly: 'Backup only', localOnly: 'Device only', safetyNote: 'A safety copy of the current device data is created immediately before restore. When restore finishes, use the on-screen Undo action to return to the previous state; the safety copy also remains in Recent backups.', chooseMode: 'Restore mode', mergeTitle: 'Merge', mergeBody: 'Keeps device data and applies new or updated records from the backup.', replaceTitle: 'Replace', replaceBody: 'Replaces included sections with the state stored in the backup.', replaceWarning: 'Replace may remove local records from included sections when they are absent from the backup.', replaceConfirmTitle: 'Remove device-only records?', replaceConfirmTemplate: 'In Replace mode this backup will remove {count} records that exist only on this device. A safety copy will be created before restore and Undo will remain available afterwards.', continueLabel: 'Continue', backupLabel: 'Backup', recordsLabel: 'records', versionLabel: 'version'),
  'ar': BackupRestoreCopy(title: 'كيف تريد استعادة النسخة؟', intro: 'تمت مقارنة الملف ببيانات هذا الجهاز. راجع التغييرات قبل المتابعة.', conflicts: 'متعارضة', incomingOnly: 'في النسخة فقط', localOnly: 'في الجهاز فقط', safetyNote: 'سيتم إنشاء نسخة أمان لبيانات الجهاز الحالية قبل الاستعادة مباشرة. بعد اكتمالها يمكنك استخدام زر التراجع الظاهر للعودة فورًا إلى الحالة السابقة، وتبقى نسخة الأمان أيضًا ضمن النسخ الأخيرة.', chooseMode: 'طريقة الاستعادة', mergeTitle: 'دمج', mergeBody: 'يحافظ على بيانات الجهاز ويضيف السجلات الجديدة أو المحدّثة من النسخة.', replaceTitle: 'استبدال', replaceBody: 'يستبدل الأقسام المشمولة بالحالة المحفوظة في النسخة.', replaceWarning: 'قد يؤدي الاستبدال إلى حذف سجلات محلية غير موجودة في النسخة.', replaceConfirmTitle: 'حذف السجلات الموجودة على الجهاز فقط؟', replaceConfirmTemplate: 'في وضع الاستبدال ستزيل هذه النسخة {count} سجلات موجودة على هذا الجهاز فقط. سيتم إنشاء نسخة أمان قبل الاستعادة وسيظل التراجع متاحًا بعدها.', continueLabel: 'متابعة', backupLabel: 'النسخة', recordsLabel: 'سجلات', versionLabel: 'الإصدار'),
  'az': BackupRestoreCopy(title: 'Yedək necə bərpa edilsin?', intro: 'Fayl bu cihazdakı məlumatlarla müqayisə edildi. Davam etməzdən əvvəl dəyişiklikləri yoxlayın.', conflicts: 'Ziddiyyətli', incomingOnly: 'Yalnız yedəkdə', localOnly: 'Yalnız cihazda', safetyNote: 'Bərpadan dərhal əvvəl cari cihaz məlumatlarının təhlükəsizlik nüsxəsi yaradılır. Bərpa bitəndə ekrandakı Geri al əməliyyatı ilə əvvəlki vəziyyətə dərhal qayıda bilərsiniz; təhlükəsizlik nüsxəsi Son yedəklərdə də qalır.', chooseMode: 'Bərpa üsulu', mergeTitle: 'Birləşdir', mergeBody: 'Cihaz məlumatlarını saxlayır və yedəkdəki yeni və yenilənmiş qeydləri əlavə edir.', replaceTitle: 'Əvəz et', replaceBody: 'Daxil edilmiş bölmələri yedəkdə saxlanılan vəziyyətlə əvəz edir.', replaceWarning: 'Əvəz etmə yedəkdə olmayan yerli qeydləri silə bilər.', replaceConfirmTitle: 'Yalnız cihazdakı qeydlər silinsin?', replaceConfirmTemplate: 'Əvəz etmə rejimində bu yedək yalnız cihazda olan {count} qeydi siləcək. Bərpadan əvvəl təhlükəsizlik nüsxəsi yaradılacaq və sonra Geri al mümkün olacaq.', continueLabel: 'Davam et', backupLabel: 'Yedək', recordsLabel: 'qeyd', versionLabel: 'versiya'),
  'ru': BackupRestoreCopy(title: 'Как восстановить эту копию?', intro: 'Файл сравнен с данными на устройстве. Проверьте изменения перед продолжением.', conflicts: 'Конфликты', incomingOnly: 'Только в копии', localOnly: 'Только на устройстве', safetyNote: 'Непосредственно перед восстановлением создаётся защитная копия текущих данных. После завершения можно сразу вернуться к прежнему состоянию кнопкой «Отменить» на экране; защитная копия также останется в списке последних копий.', chooseMode: 'Режим восстановления', mergeTitle: 'Объединить', mergeBody: 'Сохраняет данные устройства и применяет новые или обновлённые записи из копии.', replaceTitle: 'Заменить', replaceBody: 'Заменяет включённые разделы состоянием из резервной копии.', replaceWarning: 'Замена может удалить локальные записи, которых нет в резервной копии.', replaceConfirmTitle: 'Удалить записи, которые есть только на устройстве?', replaceConfirmTemplate: 'В режиме замены эта копия удалит {count} записей, существующих только на устройстве. Перед восстановлением будет создана защитная копия, после чего останется доступна отмена.', continueLabel: 'Продолжить', backupLabel: 'Копия', recordsLabel: 'записей', versionLabel: 'версия'),
  'fr': BackupRestoreCopy(title: 'Comment restaurer cette sauvegarde ?', intro: 'Le fichier a été comparé aux données de cet appareil. Vérifiez les changements avant de continuer.', conflicts: 'Conflits', incomingOnly: 'Sauvegarde seulement', localOnly: 'Appareil seulement', safetyNote: 'Une copie de sécurité des données actuelles est créée juste avant la restauration. Une fois celle-ci terminée, utilisez l’action Annuler affichée à l’écran pour revenir immédiatement à l’état précédent ; la copie reste aussi dans les sauvegardes récentes.', chooseMode: 'Mode de restauration', mergeTitle: 'Fusionner', mergeBody: 'Conserve les données de l’appareil et applique les éléments nouveaux ou mis à jour de la sauvegarde.', replaceTitle: 'Remplacer', replaceBody: 'Remplace les sections incluses par l’état enregistré dans la sauvegarde.', replaceWarning: 'Le remplacement peut supprimer des éléments locaux absents de la sauvegarde.', replaceConfirmTitle: 'Supprimer les éléments présents uniquement sur l’appareil ?', replaceConfirmTemplate: 'En mode Remplacer, cette sauvegarde supprimera {count} éléments présents uniquement sur cet appareil. Une copie de sécurité sera créée avant la restauration et l’action Annuler restera disponible ensuite.', continueLabel: 'Continuer', backupLabel: 'Sauvegarde', recordsLabel: 'éléments', versionLabel: 'version'),
};
