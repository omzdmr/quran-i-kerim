import 'package:flutter/foundation.dart';

enum ReaderAutoScrollSpeed { slow, normal, fast }

extension ReaderAutoScrollSpeedValue on ReaderAutoScrollSpeed {
  double get pixelsPerSecond => switch (this) {
    ReaderAutoScrollSpeed.slow => 12,
    ReaderAutoScrollSpeed.normal => 24,
    ReaderAutoScrollSpeed.fast => 40,
  };
}

/// Session-scoped focus controls for the Reader.
///
/// These choices intentionally reset when the Reader is left so fullscreen,
/// screen dimming and wake lock can never surprise the user on the next visit.
class ReaderFocusController extends ChangeNotifier {
  bool _fullScreen = false;
  bool _dimmed = false;
  bool _keepAwake = false;
  bool _autoScroll = false;
  ReaderAutoScrollSpeed _autoScrollSpeed = ReaderAutoScrollSpeed.normal;

  bool get fullScreen => _fullScreen;
  bool get dimmed => _dimmed;
  bool get keepAwake => _keepAwake;
  bool get autoScroll => _autoScroll;
  ReaderAutoScrollSpeed get autoScrollSpeed => _autoScrollSpeed;

  void setFullScreen(bool value) {
    if (_fullScreen == value) return;
    _fullScreen = value;
    notifyListeners();
  }

  void setDimmed(bool value) {
    if (_dimmed == value) return;
    _dimmed = value;
    notifyListeners();
  }

  void setKeepAwake(bool value) {
    if (_keepAwake == value) return;
    _keepAwake = value;
    notifyListeners();
  }

  void setAutoScroll(bool value) {
    if (_autoScroll == value) return;
    _autoScroll = value;
    notifyListeners();
  }

  void setAutoScrollSpeed(ReaderAutoScrollSpeed value) {
    if (_autoScrollSpeed == value) return;
    _autoScrollSpeed = value;
    notifyListeners();
  }

  bool pauseAutoScrollForInteraction() {
    if (!_autoScroll) return false;
    _autoScroll = false;
    notifyListeners();
    return true;
  }

  void reset() {
    final changed =
        _fullScreen || _dimmed || _keepAwake || _autoScroll ||
        _autoScrollSpeed != ReaderAutoScrollSpeed.normal;
    _fullScreen = false;
    _dimmed = false;
    _keepAwake = false;
    _autoScroll = false;
    _autoScrollSpeed = ReaderAutoScrollSpeed.normal;
    if (changed) notifyListeners();
  }
}
