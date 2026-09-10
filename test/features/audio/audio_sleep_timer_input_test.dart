import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/audio/application/audio_sleep_timer_input.dart';

void main() {
  group('parseAudioSleepTimerDuration', () {
    test('accepts custom minute values', () {
      expect(
        parseAudioSleepTimerDuration('45', AudioSleepTimerUnit.minutes),
        const Duration(minutes: 45),
      );
    });

    test('accepts custom hour values', () {
      expect(
        parseAudioSleepTimerDuration('2', AudioSleepTimerUnit.hours),
        const Duration(hours: 2),
      );
    });

    test('rejects invalid, zero and excessive values', () {
      expect(parseAudioSleepTimerDuration('', AudioSleepTimerUnit.minutes), isNull);
      expect(parseAudioSleepTimerDuration('0', AudioSleepTimerUnit.hours), isNull);
      expect(parseAudioSleepTimerDuration('1441', AudioSleepTimerUnit.minutes), isNull);
      expect(parseAudioSleepTimerDuration('25', AudioSleepTimerUnit.hours), isNull);
    });
  });

  group('formatAudioSleepTimerRemaining', () {
    test('formats minutes and mixed hours', () {
      expect(formatAudioSleepTimerRemaining(const Duration(minutes: 30)), '30 dk');
      expect(formatAudioSleepTimerRemaining(const Duration(minutes: 90)), '1 sa 30 dk');
    });
  });
}
