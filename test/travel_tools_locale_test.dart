import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const cases = <String, List<String>>{
    'tr': ['Seyahat araçları', 'Buluşma noktası', 'Seyahat listesi'],
    'en': ['Travel tools', 'Meeting point', 'Travel checklist'],
    'fr': ['Outils de voyage', 'Point de rendez-vous', 'Liste de voyage'],
    'ar': ['أدوات السفر', 'نقطة اللقاء', 'قائمة السفر'],
    'az': ['Səyahət alətləri', 'Görüş yeri', 'Səyahət siyahısı'],
    'ru': ['Инструменты поездки', 'Место встречи', 'Список в поездку'],
  };

  for (final entry in cases.entries) {
    testWidgets('travel hub supports ${entry.key}', (tester) async {
      await tester.pumpWidget(MaterialApp(locale: Locale(entry.key), home: const TravelToolsScreen()));
      await tester.pumpAndSettle();
      for (final text in entry.value) {
        expect(find.text(text), findsOneWidget);
      }
    });
  }
}