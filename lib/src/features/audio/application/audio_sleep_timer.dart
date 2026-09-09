import 'dart:async';

typedef SleepTimerExpired = void Function();

/// Local-only sleep timer for Quran audio playback.
///
/// The timer deliberately has no storage or network dependency. Audio playback
/// can bind [onExpired] to its pause/stop action, while the UI can derive the
/// current remaining duration from [remaining].
class AudioSleepTimer {
  AudioSleepTimer({required SleepTimerExpired onExpired})
      : _onExpired = onExpired;

  final SleepTimerExpired _onExpired;
  Timer? _timer;
  DateTime? _deadline;

  bool get isActive => _timer?.isActive ?? false;

  DateTime? get deadline => _deadline;

  Duration get remaining {
    final deadline = _deadline;
    if (!isActive || deadline == null) return Duration.zero;
    final value = deadline.difference(DateTime.now());
    return value.isNegative ? Duration.zero : value;
  }

  void startForMinutes(int minutes) {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'must be greater than 0');
    }
    start(Duration(minutes: minutes));
  }

  void startForHours(int hours) {
    if (hours <= 0) {
      throw ArgumentError.value(hours, 'hours', 'must be greater than 0');
    }
    start(Duration(hours: hours));
  }

  void start(Duration duration) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'must be greater than 0');
    }

    cancel();
    _deadline = DateTime.now().add(duration);
    _timer = Timer(duration, () {
      _timer = null;
      _deadline = null;
      _onExpired();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _deadline = null;
  }

  void dispose() => cancel();
}
