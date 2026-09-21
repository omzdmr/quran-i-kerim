import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/travel_tools_screen.dart';

void main() {
  testWidgets('travel hub remains usable at large text size', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)), child: child!),
      home: const TravelToolsScreen(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Travel tools'), findsOneWidget);
    expect(find.text('Meeting point'), findsOneWidget);
    expect(find.text('Travel checklist'), findsOneWidget);
    expect(find.text('Dietary communication card'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
