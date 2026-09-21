import AVFAudio
import Foundation
import MediaPlayer

final class AudioSessionCoordinator {
  static let shared = AudioSessionCoordinator()
  static let interruptionBeganNotification = Notification.Name("QuranAudioSessionInterruptionBegan")
  static let interruptionEndedNotification = Notification.Name("QuranAudioSessionInterruptionEnded")
  static let routeChangedNotification = Notification.Name("QuranAudioSessionRouteChanged")
  private let session: AVAudioSession
  private let notificationCenter: NotificationCenter
  private var observers: [NSObjectProtocol] = []
  private(set) var isConfigured = false
  init(session: AVAudioSession = .sharedInstance(), notificationCenter: NotificationCenter = .default) { self.session = session; self.notificationCenter = notificationCenter }
  func start() { guard observers.isEmpty else { return }; configurePolicy(); observers = [notificationCenter.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] in self?.handleInterruption($0) }, notificationCenter.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: .main) { [weak self] in self?.handleRouteChange($0) }, notificationCenter.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: session, queue: .main) { [weak self] _ in self?.configurePolicy() }] }
  func stop() { observers.forEach(notificationCenter.removeObserver); observers.removeAll() }
  @discardableResult func configurePolicy() -> Bool { do { try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothA2DP]); isConfigured = true; return true } catch { isConfigured = false; NSLog("Unable to configure Quran audio session: %@", String(describing: error)); return false } }
  private func handleInterruption(_ notification: Notification) { guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }; switch type { case .began: notificationCenter.post(name: Self.interruptionBeganNotification, object: self); case .ended: let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0, shouldResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume); configurePolicy(); notificationCenter.post(name: Self.interruptionEndedNotification, object: self, userInfo: ["shouldResume": shouldResume]); @unknown default: break } }
  private func handleRouteChange(_ notification: Notification) { guard let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt, let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) else { return }; notificationCenter.post(name: Self.routeChangedNotification, object: self, userInfo: ["reason": reason.rawValue]) }
}

final class NowPlayingCoordinator {
  enum RemoteCommand: String { case play, pause, next, previous, seek }
  struct Metadata {
    let title: String, subtitle: String?, albumTitle: String?
    let duration: TimeInterval?, elapsed: TimeInterval, playbackRate: Double
    let canGoNext: Bool, canGoPrevious: Bool
    init(title: String, subtitle: String?, albumTitle: String?, duration: TimeInterval?, elapsed: TimeInterval, playbackRate: Double, canGoNext: Bool = true, canGoPrevious: Bool = true) { self.title = title; self.subtitle = subtitle; self.albumTitle = albumTitle; self.duration = duration; self.elapsed = elapsed; self.playbackRate = playbackRate; self.canGoNext = canGoNext; self.canGoPrevious = canGoPrevious }
  }
  var onRemoteCommand: ((RemoteCommand, TimeInterval?) -> Void)?
  private let infoCenter: MPNowPlayingInfoCenter
  private let commandCenter: MPRemoteCommandCenter
  private var commandTargets: [(MPRemoteCommand, Any)] = []
  init(infoCenter: MPNowPlayingInfoCenter = .default(), commandCenter: MPRemoteCommandCenter = .shared()) { self.infoCenter = infoCenter; self.commandCenter = commandCenter }
  func start() { guard commandTargets.isEmpty else { return }; register(commandCenter.playCommand, command: .play); register(commandCenter.pauseCommand, command: .pause); register(commandCenter.nextTrackCommand, command: .next); register(commandCenter.previousTrackCommand, command: .previous); let seekTarget = commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in guard let self, self.commandCenter.changePlaybackPositionCommand.isEnabled, let seekEvent = event as? MPChangePlaybackPositionCommandEvent, self.onRemoteCommand != nil else { return .commandFailed }; self.onRemoteCommand?(.seek, seekEvent.positionTime); return .success }; commandTargets.append((commandCenter.changePlaybackPositionCommand, seekTarget)) }
  func stop() { for (command, target) in commandTargets { command.removeTarget(target) }; commandTargets.removeAll(); clear() }
  func update(_ metadata: Metadata) {
    let duration = metadata.duration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }, elapsed = duration.map { min(max(0, metadata.elapsed), $0) } ?? max(0, metadata.elapsed)
    var info: [String: Any] = [MPMediaItemPropertyTitle: metadata.title, MPMediaItemPropertyMediaType: MPMediaType.anyAudio.rawValue, MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed, MPNowPlayingInfoPropertyPlaybackRate: metadata.playbackRate, MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0]
    if let subtitle = metadata.subtitle, !subtitle.isEmpty { info[MPMediaItemPropertyArtist] = subtitle }; if let albumTitle = metadata.albumTitle, !albumTitle.isEmpty { info[MPMediaItemPropertyAlbumTitle] = albumTitle }; if let duration { info[MPMediaItemPropertyPlaybackDuration] = duration }
    commandCenter.changePlaybackPositionCommand.isEnabled = duration != nil; commandCenter.nextTrackCommand.isEnabled = metadata.canGoNext; commandCenter.previousTrackCommand.isEnabled = metadata.canGoPrevious; infoCenter.nowPlayingInfo = info
    if #available(iOS 13.0, *) { infoCenter.playbackState = metadata.playbackRate > 0 ? .playing : .paused }
  }
  func clear() { infoCenter.nowPlayingInfo = nil; commandCenter.changePlaybackPositionCommand.isEnabled = false; if #available(iOS 13.0, *) { infoCenter.playbackState = .stopped } }
  private func register(_ remote: MPRemoteCommand, command: RemoteCommand) { remote.isEnabled = true; let target = remote.addTarget { [weak self, weak remote] _ in guard let self, remote?.isEnabled == true, self.onRemoteCommand != nil else { return .commandFailed }; self.onRemoteCommand?(command, nil); return .success }; commandTargets.append((remote, target)) }
}
