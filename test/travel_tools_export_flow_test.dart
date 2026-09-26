import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_dietary_card_store.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_store.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_screen.dart';

void main() {
  testWidgets('travel export and restore are explicit user actions', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const meetingStore = TravelMeetingPointStore();
    const dietaryStore = TravelDietaryCardStore();
    await meetingStore.save(TravelMeetingPoint(name:'Camp',address:'North gate',note:'',updatedAt:DateTime(2026,9,22)));
    await dietaryStore.save(const TravelDietaryCard(languageLabel:'Français',staffText:'trusted staff text',note:'private note'));

    await tester.pumpWidget(const MaterialApp(home: TravelToolsScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('excluded from automatic backup'), findsOneWidget);

    await tester.tap(find.text('Copy travel data'));
    await tester.pumpAndSettle();
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final json = jsonDecode(clipboard!.text!) as Map<String,dynamic>;
    expect((json['meetingPoint'] as Map<String,dynamic>)['name'], 'Camp');
    expect((json['dietaryCard'] as Map<String,dynamic>)['staffText'], 'trusted staff text');

    await meetingStore.clear();
    await dietaryStore.clear();
    await tester.tap(find.text('Restore from clipboard'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Camp'), findsOneWidget);
    expect(find.textContaining('Français'), findsOneWidget);
    expect(find.textContaining('private note'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await meetingStore.load(), isNull);
    expect(await dietaryStore.load(), isNull);

    await tester.tap(find.text('Restore from clipboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect((await meetingStore.load())?.name, 'Camp');
    expect((await dietaryStore.load())?.staffText, 'trusted staff text');
    expect((await dietaryStore.load())?.note, 'private note');
    expect(find.text('Travel data restored'), findsOneWidget);
  });
}
