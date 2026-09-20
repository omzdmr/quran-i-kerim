import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/features/reader/reader_sleep_timer.dart';

void main() {
  test('custom sleep timer supports hour and minute combinations', () {
    final timer = ReaderSleepTimerValue.custom(hours: 2, minutes: 15);

    expect(timer.duration, const Duration(hours: 2, minutes: 15));
    expect(timer.totalMinutes, 135);
    expect(timer.hoursPart, 2);
    expect(timer.minutesPart, 15);
  });

  test('custom sleep timer supports whole hours', () {
    final timer = ReaderSleepTimerValue.custom(hours: 2, minutes: 0);

    expect(timer.duration, const Duration(hours: 2));
    expect(timer.totalMinutes, 120);
    expect(timer.hoursPart, 2);
    expect(timer.minutesPart, 0);
  });

  test('custom sleep timer rejects zero and values over 24 hours', () {
    expect(
      () => ReaderSleepTimerValue.custom(hours: 0, minutes: 0),
      throwsArgumentError,
    );
    expect(
      () => ReaderSleepTimerValue.custom(hours: 24, minutes: 1),
      throwsArgumentError,
    );
  });

  test('end of surah and off remain distinct states', () {
    const end = ReaderSleepTimerValue.endOfSurah();
    const off = ReaderSleepTimerValue.off();

    expect(end.endOfSurah, isTrue);
    expect(end.isOff, isFalse);
    expect(off.endOfSurah, isFalse);
    expect(off.isOff, isTrue);
  });
}
