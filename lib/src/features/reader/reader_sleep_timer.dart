class ReaderSleepTimerValue {
  const ReaderSleepTimerValue._({this.duration, this.endOfSurah = false});

  const ReaderSleepTimerValue.off() : this._();

  const ReaderSleepTimerValue.endOfSurah()
      : this._(endOfSurah: true);

  factory ReaderSleepTimerValue.custom({
    required int hours,
    required int minutes,
  }) {
    if (hours < 0 || minutes < 0 || minutes > 59) {
      throw ArgumentError('Invalid sleep timer value');
    }
    final totalMinutes = (hours * 60) + minutes;
    if (totalMinutes < 1 || totalMinutes > maxCustomMinutes) {
      throw ArgumentError('Sleep timer must be between 1 minute and 24 hours');
    }
    return ReaderSleepTimerValue._(
      duration: Duration(minutes: totalMinutes),
    );
  }

  static const int maxCustomMinutes = 24 * 60;

  final Duration? duration;
  final bool endOfSurah;

  bool get isOff => duration == null && !endOfSurah;

  int? get totalMinutes => duration?.inMinutes;

  int get hoursPart => (duration?.inMinutes ?? 0) ~/ 60;

  int get minutesPart => (duration?.inMinutes ?? 0) % 60;
}
