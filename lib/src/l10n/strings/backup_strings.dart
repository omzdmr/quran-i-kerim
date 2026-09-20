import 'backup_strings_fr.dart';
import 'backup_strings_legacy.dart' as legacy;

const backupStrings = <String, Map<String, String>>{
  ...legacy.backupStrings,
  'fr': backupStringsFr,
};
