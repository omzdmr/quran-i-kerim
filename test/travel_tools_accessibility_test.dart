import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_screen.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_screen.dart';
import 'package:quran_i_kerim/src/features/discover/travel_packing_screen.dart';

void main(){
  setUp(()=>SharedPreferences.setMockInitialValues(<String,Object>{}));
  Widget app(Widget home,{Locale locale=const Locale('ar')})=>MaterialApp(locale:locale,supportedLocales:const[Locale('ar'),Locale('en')],localizationsDelegates:GlobalMaterialLocalizations.delegates,home:home);

  testWidgets('meeting point follows Arabic RTL direction',(tester) async{
    await tester.pumpWidget(app(const TravelMeetingPointScreen()));await tester.pumpAndSettle();
    final directionality=tester.widget<Directionality>(find.ancestor(of:find.text('نقطة اللقاء'),matching:find.byType(Directionality)).first);
    expect(directionality.textDirection,TextDirection.rtl);
  });

  testWidgets('dietary card follows Arabic RTL and keeps editor reachable',(tester) async{
    await tester.pumpWidget(app(const TravelDietaryCardScreen()));await tester.pumpAndSettle();
    expect(find.text('بطاقة التواصل الغذائي'),findsOneWidget);
    final directionality=tester.widget<Directionality>(find.ancestor(of:find.text('بطاقة التواصل الغذائي'),matching:find.byType(Directionality)).first);
    expect(directionality.textDirection,TextDirection.rtl);
    expect(find.byType(TextField),findsNWidgets(3));
  });

  testWidgets('packing checklist exposes progress semantics',(tester) async{
    final handle=tester.ensureSemantics();addTearDown(handle.dispose);
    await tester.pumpWidget(app(const TravelPackingScreen(),locale:const Locale('en')));await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'Ready: 0 / 0')),findsOneWidget);
  });
}
