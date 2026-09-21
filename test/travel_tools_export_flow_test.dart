import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_i_kerim/src/features/discover/travel_meeting_point_store.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_screen.dart';

void main() {
  testWidgets('travel export is explicit and user initiated', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const TravelMeetingPointStore().save(TravelMeetingPoint(
      name: 'Camp',
      address: 'North gate',
      note: '',
      updatedAt: DateTime(2026, 9, 22),
    ));

    await tester.pumpWidget(const MaterialApp(home: TravelToolsScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('excluded from automatic backup'), findsOneWidget);

    await tester.tap(find.text('Copy travel data'));
    await tester.pumpAndSettle();
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final json = jsonDecode(clipboard!.text!) as Map<String, dynamic>;
    expect((json['meetingPoint'] as Map<String, dynamic>)['name'], 'Camp');
    expect(find.text('Travel data copied'), findsOneWidget);
  });
}