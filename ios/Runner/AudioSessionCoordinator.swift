import AVFAudio
import Foundation
import MediaPlayer

/// Owns the application-level audio-session policy for Quran recitation.
final class AudioSessionCoordinator {
  static let shared = AudioSessionCoordinator()

  static let interruptionBeganNotification = Notification.Name("QuranAudioSessionInterruptionBegan")
  static let interruptionEndedNotification = Notification.Name("QuranAudioSessionInterruptionEnded")
  static let routeChangedNotification = Notification.Name("QuranAudioSessionRouteChanged")

  private let session: AVAudioSession
  private let notificationCenter: NotificationCenter
  private var observers: [NSObjectProtocol] = []
  private(set) var isConfigured = false

  init(session: AVAudioSession = .sharedInstance(), notificationCenter: NotificationCenter = .default) {
    self.session = session
    self.notificationCenter = notificationCenter
  }

  func start() {
    guard observers.isEmpty else { return }
    configurePolicy()
    observers = [
      notificationCenter.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] in self?.handleInterruption($0) },
      notificationCenter.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: .main) { [weak self] in self?.handleRouteChange($0) },
      notificationCenter.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: session, queue: .main) { [weak self] _ in self?.configurePolicy() },
    ]
  }

  func stop() {
    observers.forEach(notificationCenter.removeObserver)
    observers.removeAll()
  }

  @discardableResult
  func configurePolicy() -> Bool {
    do {
      try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothA2DP])
      isConfigured = true
      return true
    } catch {
      isConfigured = false
      NSLog("Unable to configure Quran audio session: %@", String(describing: error))
      return false
    }
  }

  private func handleInterruption(_ notification: Notification) {
    guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
    switch type {
    case .began:
      notificationCenter.post(name: Self.interruptionBeganNotification, object: self)
    case .ended:
      let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
      let shouldResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
      configurePolicy()
      notificationCenter.post(name: Self.interruptionEndedNotification, object: self, userInfo: ["shouldResume": shouldResume])
    @unknown default:
      break
    }
  }

  private func handleRouteChange(_ notification: Notification) {
    guard let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) else { return }
    notificationCenter.post(name: Self.routeChangedNotification, object: self, userInfo: ["reason": reason.rawValue])
  }
}

/// Native lock-screen / Control Center boundary for Quran audio.
///
/// This class owns only Apple MediaPlayer state. Playback remains owned by the
/// shared player, which receives remote commands through callbacks and decides
/// whether a command is valid for its current queue.
final class NowPlayingCoordinator {
  enum RemoteCommand: String {
    case play
    case pause
    case next
    case previous
    case seek
  }

  struct Metadata {
    let title: String
    let subtitle: String?
    let albumTitle: String?
    let duration: TimeInterval?
    let elapsed: TimeInterval
    let playbackRate: Double
  }

  var onRemoteCommand: ((RemoteCommand, TimeInterval?) -> Void)?

  private let infoCenter: MPNowPlayingInfoCenter
  private let commandCenter: MPRemoteCommandCenter
  private var commandTargets: [(MPRemoteCommand, Any)] = []

  init(
    infoCenter: MPNowPlayingInfoCenter = .default(),
    commandCenter: MPRemoteCommandCenter = .shared()
  ) {
    self.infoCenter = infoCenter
    self.commandCenter = commandCenter
  }

  func start() {
    guard commandTargets.isEmpty else { return }
    register(commandCenter.playCommand, command: .play)
    register(commandCenter.pauseCommand, command: .pause)
    register(commandCenter.nextTrackCommand, command: .next)
    register(commandCenter.previousTrackCommand, command: .previous)

    commandCenter.changePlaybackPositionCommand.isEnabled = true
    let seekTarget = commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let self,
            let seekEvent = event as? MPChangePlaybackPositionCommandEvent,
            self.onRemoteCommand != nil else { return .commandFailed }
      self.onRemoteCommand?(.seek, seekEvent.positionTime)
      return .success
    }
    commandTargets.append((commandCenter.changePlaybackPositionCommand, seekTarget))
  }

  func stop() {
    for (command, target) in commandTargets { command.removeTarget(target) }
    commandTargets.removeAll()
    clear()
  }

  func update(_ metadata: Metadata) {
    var info: [String: Any] = [
      MPMediaItemPropertyTitle: metadata.title,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: max(0, metadata.elapsed),
      MPNowPlayingInfoPropertyPlaybackRate: metadata.playbackRate,
    ]
    if let subtitle = metadata.subtitle, !subtitle.isEmpty { info[MPMediaItemPropertyArtist] = subtitle }
    if let albumTitle = metadata.albumTitle, !albumTitle.isEmpty { info[MPMediaItemPropertyAlbumTitle] = albumTitle }
    if let duration = metadata.duration, duration.isFinite, duration > 0 { info[MPMediaItemPropertyPlaybackDuration] = duration }
    infoCenter.nowPlayingInfo = info
    if #available(iOS 13.0, *) {
      infoCenter.playbackState = metadata.playbackRate > 0 ? .playing : .paused
    }
  }

  func clear() {
    infoCenter.nowPlayingInfo = nil
    if #available(iOS 13.0, *) { infoCenter.playbackState = .stopped }
  }

  private func register(_ remote: MPRemoteCommand, command: RemoteCommand) {
    remote.isEnabled = true
    let target = remote.addTarget { [weak self] _ in
      guard let self, self.onRemoteCommand != nil else { return .commandFailed }
      self.onRemoteCommand?(command, nil)
      return .success
    }
    commandTargets.append((remote, target))
  }
}
