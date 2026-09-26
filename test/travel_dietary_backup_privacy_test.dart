import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/backup/shared_preferences_backup_adapter.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dietary communication card stays out of automatic app backup', () async {
    SharedPreferences.setMockInitialValues({TravelDietaryCardStore.key:'{"languageLabel":"fr","staffText":"private dietary request","note":"sensitive note"}','app_locale':'fr'});
    final snapshot=await const SharedPreferencesBackupAdapter().capture();
    expect(snapshot['app_locale'],'fr');
    expect(snapshot.containsKey(TravelDietaryCardStore.key),isFalse);
  });

  test('automatic restore does not erase device-local dietary card', () async {
    SharedPreferences.setMockInitialValues({TravelDietaryCardStore.key:'{"languageLabel":"fr","staffText":"keep me","note":"private"}','app_locale':'fr'});
    await const SharedPreferencesBackupAdapter().restore({'app_locale':'en'});
    expect((await const TravelDietaryCardStore().load())?.staffText,'keep me');
    expect((await SharedPreferences.getInstance()).getString('app_locale'),'en');
  });
}
