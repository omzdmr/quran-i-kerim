import AVFAudio
import Foundation

/// Owns the application-level audio-session policy for Quran recitation.
///
/// Player plugins remain responsible for playback state and transport controls.
/// This coordinator deliberately never starts or resumes playback by itself:
/// interruption recovery must respect the user's last explicit player state.
final class AudioSessionCoordinator {
  static let shared = AudioSessionCoordinator()

  static let interruptionBeganNotification =
    Notification.Name("QuranAudioSessionInterruptionBegan")
  static let interruptionEndedNotification =
    Notification.Name("QuranAudioSessionInterruptionEnded")
  static let routeChangedNotification =
    Notification.Name("QuranAudioSessionRouteChanged")

  private let session: AVAudioSession
  private let notificationCenter: NotificationCenter
  private var observers: [NSObjectProtocol] = []

  private(set) var isConfigured = false

  init(
    session: AVAudioSession = .sharedInstance(),
    notificationCenter: NotificationCenter = .default
  ) {
    self.session = session
    self.notificationCenter = notificationCenter
  }

  func start() {
    guard observers.isEmpty else { return }

    configurePolicy()

    observers = [
      notificationCenter.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: session,
        queue: .main
      ) { [weak self] notification in
        self?.handleInterruption(notification)
      },
      notificationCenter.addObserver(
        forName: AVAudioSession.routeChangeNotification,
        object: session,
        queue: .main
      ) { [weak self] notification in
        self?.handleRouteChange(notification)
      },
      notificationCenter.addObserver(
        forName: AVAudioSession.mediaServicesWereResetNotification,
        object: session,
        queue: .main
      ) { [weak self] _ in
        self?.configurePolicy()
      },
    ]
  }

  func stop() {
    observers.forEach(notificationCenter.removeObserver)
    observers.removeAll()
  }

  /// Configures background spoken-audio behavior without activating the session.
  ///
  /// Avoiding activation during launch prevents the app from interrupting audio
  /// that the user was already playing in another application.
  @discardableResult
  func configurePolicy() -> Bool {
    do {
      try session.setCategory(
        .playback,
        mode: .spokenAudio,
        options: [.allowAirPlay, .allowBluetoothA2DP]
      )
      isConfigured = true
      return true
    } catch {
      isConfigured = false
      NSLog("Unable to configure Quran audio session: %@", String(describing: error))
      return false
    }
  }

  private func handleInterruption(_ notification: Notification) {
    guard
      let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: rawType)
    else {
      return
    }

    switch type {
    case .began:
      notificationCenter.post(
        name: Self.interruptionBeganNotification,
        object: self
      )

    case .ended:
      let rawOptions =
        notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
      let shouldResume =
        AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)

      // Media services or another app may have changed the category while this
      // app was interrupted. Reapply policy, but let the player decide whether
      // its pre-interruption state warrants resuming.
      configurePolicy()
      notificationCenter.post(
        name: Self.interruptionEndedNotification,
        object: self,
        userInfo: ["shouldResume": shouldResume]
      )

    @unknown default:
      break
    }
  }

  private func handleRouteChange(_ notification: Notification) {
    guard
      let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
      let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason)
    else {
      return
    }

    // Do not automatically resume after headphones/Bluetooth disappear. The
    // playback plugin and iOS route policy must preserve the user's intent.
    notificationCenter.post(
      name: Self.routeChangedNotification,
      object: self,
      userInfo: ["reason": reason.rawValue]
    )
  }
}
