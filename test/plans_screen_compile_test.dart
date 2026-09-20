import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/plans/plans_screen.dart';

void main() {
  test('plans screen compiles with khatm archive feature', () {
    const screen = PlansScreen();
    expect(screen, isA<PlansScreen>());
  });
}
