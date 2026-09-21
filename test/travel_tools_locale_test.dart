import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String,Object>{}));
  const cases=<String,List<String>>{
    'tr':['Seyahat araçları','Buluşma noktası','Seyahat listesi','Yemek iletişim kartı'],
    'en':['Travel tools','Meeting point','Travel checklist','Dietary communication card'],
    'fr':['Outils de voyage','Point de rendez-vous','Liste de voyage','Carte de communication alimentaire'],
    'ar':['أدوات السفر','نقطة اللقاء','قائمة السفر','بطاقة التواصل الغذائي'],
    'az':['Səyahət alətləri','Görüş yeri','Səyahət siyahısı','Qida ünsiyyət kartı'],
    'ru':['Инструменты поездки','Место встречи','Список в поездку','Карточка питания'],
  };
  for(final entry in cases.entries){
    testWidgets('travel hub supports ${entry.key}',(tester) async{
      await tester.pumpWidget(MaterialApp(locale:Locale(entry.key),home:const TravelToolsScreen()));
      await tester.pumpAndSettle();
      for(final text in entry.value){expect(find.text(text),findsOneWidget);}
    });
  }
}
