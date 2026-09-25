import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/discover/dhikr_history_store.dart';

void main() {
  const codec = DhikrCounterDocumentCodec();

  test('legacy counter documents migrate with optional sound disabled', () {
    final document = codec.decode('{"subhanallah":33}');
    expect(document.counts['subhanallah'], 33);
    expect(document.soundEnabled, isFalse);
  });

  test('sound preference survives the versioned counter document', () {
    final encoded = codec.encode(
      counts: const <String, int>{'subhanallah': 33},
      history: const <DhikrDailyHistoryRecord>[],
      soundEnabled: true,
    );
    final restored = codec.decode(encoded);
    expect(restored.soundEnabled, isTrue);
    expect(restored.counts['subhanallah'], 33);
  });
}
