import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/prayer/presentation/qibla_launcher_screen.dart';

void main() {
  test('qibla location request gate allows only one in-flight request', () {
    final gate = QiblaLocationRequestGate();

    expect(gate.inFlight, isFalse);
    expect(gate.tryAcquire(), isTrue);
    expect(gate.inFlight, isTrue);
    expect(gate.tryAcquire(), isFalse);

    gate.release();

    expect(gate.inFlight, isFalse);
    expect(gate.tryAcquire(), isTrue);
  });
}
