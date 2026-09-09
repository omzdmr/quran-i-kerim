import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/audio/application/audio_sleep_timer.dart';

void main() {
  group('AudioSleepTimer', () {
    test('starts with a custom duration and expires once', () async {
      var expirations = 0;
      final timer = AudioSleepTimer(onExpired: () => expirations++);

      timer.start(const Duration(milliseconds: 25));

      expect(timer.isActive, isTrue);
      expect(timer.remaining, greaterThan(Duration.zero));

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(expirations, 1);
      expect(timer.isActive, isFalse);
      expect(timer.remaining, Duration.zero);
    });

    test('restarting replaces the previous timer', () async {
      var expirations = 0;
      final timer = AudioSleepTimer(onExpired: () => expirations++);

      timer.start(const Duration(milliseconds: 20));
      timer.start(const Duration(milliseconds: 70));

      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(expirations, 0);
      expect(timer.isActive, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(expirations, 1);
    });

    test('cancel prevents expiration', () async {
      var expirations = 0;
      final timer = AudioSleepTimer(onExpired: () => expirations++);

      timer.start(const Duration(milliseconds: 20));
      timer.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(expirations, 0);
      expect(timer.isActive, isFalse);
      expect(timer.deadline, isNull);
    });

    test('minute and hour helpers reject non-positive values', () {
      final timer = AudioSleepTimer(onExpired: () {});

      expect(() => timer.startForMinutes(0), throwsArgumentError);
      expect(() => timer.startForHours(-1), throwsArgumentError);
    });
  });
}
