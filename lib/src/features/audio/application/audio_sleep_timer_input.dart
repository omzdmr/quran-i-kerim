enum AudioSleepTimerUnit { minutes, hours }

Duration? parseAudioSleepTimerDuration(
  String rawValue,
  AudioSleepTimerUnit unit,
) {
  final value = int.tryParse(rawValue.trim());
  if (value == null || value <= 0) return null;

  return switch (unit) {
    AudioSleepTimerUnit.minutes when value <= 1440 => Duration(minutes: value),
    AudioSleepTimerUnit.hours when value <= 24 => Duration(hours: value),
    _ => null,
  };
}

String formatAudioSleepTimerRemaining(Duration remaining) {
  if (remaining <= Duration.zero) return '0 dk';
  final totalMinutes = (remaining.inSeconds / 60).ceil();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes dk';
  if (minutes == 0) return '$hours sa';
  return '$hours sa $minutes dk';
}
