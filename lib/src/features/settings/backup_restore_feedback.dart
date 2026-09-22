import 'package:flutter/material.dart';

import '../../data/backup/backup_file_service.dart';

/// User-facing completion feedback for a successful backup restore.
///
/// The restore receipt already points at the exact pre-restore snapshot. This
/// surface makes that safety mechanism discoverable immediately instead of
/// forcing the user to understand backup filenames in Recent backups.
class BackupRestoreFeedback {
  const BackupRestoreFeedback._();

  static Future<bool> show({
    required BuildContext context,
    required BackupFileService service,
    required BackupRestoreReceipt receipt,
    Future<void> Function()? afterUndo,
  }) async {
    final copy = BackupRestoreFeedbackCopy.forLocale(Localizations.localeOf(context));
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    var undone = false;
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          label: copy.restored,
          child: Text(copy.restored),
        ),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: copy.undo,
          onPressed: () async {
            try {
              await service.undoRestore(receipt);
              if (afterUndo != null) await afterUndo();
              undone = true;
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Semantics(
                      liveRegion: true,
                      label: copy.undone,
                      child: Text(copy.undone),
                    ),
                  ),
                );
            } catch (_) {
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Semantics(
                      liveRegion: true,
                      label: copy.undoFailed,
                      child: Text(copy.undoFailed),
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
    await controller.closed;
    return undone;
  }
}

class BackupRestoreFeedbackCopy {
  const BackupRestoreFeedbackCopy({
    required this.restored,
    required this.undo,
    required this.undone,
    required this.undoFailed,
  });

  final String restored;
  final String undo;
  final String undone;
  final String undoFailed;

  static BackupRestoreFeedbackCopy forLocale(Locale locale) =>
      _copies[locale.languageCode] ?? _copies['en']!;
}

const _copies = <String, BackupRestoreFeedbackCopy>{
  'tr': BackupRestoreFeedbackCopy(restored: 'Yedek geri yüklendi.', undo: 'Geri al', undone: 'Geri yükleme geri alındı. Önceki verileriniz geri geldi.', undoFailed: 'Geri alma tamamlanamadı. Güvenlik kopyanız Son yedekler bölümünde duruyor.'),
  'en': BackupRestoreFeedbackCopy(restored: 'Backup restored.', undo: 'Undo', undone: 'Restore undone. Your previous data is back.', undoFailed: 'Undo could not be completed. Your safety copy is still available in Recent backups.'),
  'fr': BackupRestoreFeedbackCopy(restored: 'Sauvegarde restaurée.', undo: 'Annuler', undone: 'Restauration annulée. Vos données précédentes sont rétablies.', undoFailed: 'Impossible d’annuler. Votre copie de sécurité reste disponible dans les sauvegardes récentes.'),
  'ar': BackupRestoreFeedbackCopy(restored: 'تمت استعادة النسخة الاحتياطية.', undo: 'تراجع', undone: 'تم التراجع عن الاستعادة وعادت بياناتك السابقة.', undoFailed: 'تعذر التراجع. لا تزال نسخة الأمان متاحة ضمن النسخ الأخيرة.'),
  'az': BackupRestoreFeedbackCopy(restored: 'Yedək bərpa edildi.', undo: 'Geri al', undone: 'Bərpa geri alındı. Əvvəlki məlumatlarınız qaytarıldı.', undoFailed: 'Geri alma tamamlanmadı. Təhlükəsizlik nüsxəniz Son yedəklərdə qalır.'),
  'ru': BackupRestoreFeedbackCopy(restored: 'Резервная копия восстановлена.', undo: 'Отменить', undone: 'Восстановление отменено. Предыдущие данные возвращены.', undoFailed: 'Не удалось отменить восстановление. Защитная копия остаётся в списке последних копий.'),
};
