import AVFAudio
import Foundation
import MediaPlayer

final class AudioSessionCoordinator {
  static let shared = AudioSessionCoordinator()
  static let interruptionBeganNotification = Notification.Name("QuranAudioSessionInterruptionBegan")
  static let interruptionEndedNotification = Notification.Name("QuranAudioSessionInterruptionEnded")
  static let routeChangedNotification = Notification.Name("QuranAudioSessionRouteChanged")
  static let mediaServicesResetNotification = Notification.Name("QuranAudioMediaServicesReset")
  private let session: AVAudioSession
  private let notificationCenter: NotificationCenter
  private var observers: [NSObjectProtocol] = []
  private(set) var isConfigured = false
  init(session: AVAudioSession = .sharedInstance(), notificationCenter: NotificationCenter = .default) { self.session = session; self.notificationCenter = notificationCenter }
  func start() { guard observers.isEmpty else { return }; configurePolicy(); observers = [notificationCenter.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] in self?.handleInterruption($0) }, notificationCenter.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: .main) { [weak self] in self?.handleRouteChange($0) }, notificationCenter.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: session, queue: .main) { [weak self] _ in guard let self else { return }; let configured = self.configurePolicy(); self.notificationCenter.post(name: Self.mediaServicesResetNotification, object: self, userInfo: ["configured": configured]) }] }
  func stop() { observers.forEach(notificationCenter.removeObserver); observers.removeAll() }
  @discardableResult func configurePolicy() -> Bool { do { try session.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetoothA2DP]); isConfigured = true; return true } catch { isConfigured = false; NSLog("Unable to configure Quran audio session: %@", String(describing: error)); return false } }
  private func handleInterruption(_ notification: Notification) { guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }; switch type { case .began: notificationCenter.post(name: Self.interruptionBeganNotification, object: self); case .ended: let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0, shouldResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume); configurePolicy(); notificationCenter.post(name: Self.interruptionEndedNotification, object: self, userInfo: ["shouldResume": shouldResume]); @unknown default: break } }
  private func handleRouteChange(_ notification: Notification) { guard let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt, let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) else { return }; let shouldPause = reason == .oldDeviceUnavailable; notificationCenter.post(name: Self.routeChangedNotification, object: self, userInfo: ["reason": reason.rawValue, "shouldPause": shouldPause]) }
}

final class NowPlayingCoordinator {
  static let serviceIdentifier = "com.omzdmr.quranIKerim.native-now-playing"
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
  private var ownsNowPlayingInfo = false
  private var lastPublishedInfo: [String: Any]?
  private var previousInfo: [String: Any]?
  private var previousPlaybackState: MPNowPlayingPlaybackState?
  private var previousCommandStates: [ObjectIdentifier: Bool] = [:]
  private var isStarted = false
  init(infoCenter: MPNowPlayingInfoCenter = .default(), commandCenter: MPRemoteCommandCenter = .shared()) { self.infoCenter = infoCenter; self.commandCenter = commandCenter }

  /// Registration alone must not compete with audio_service for MPRemoteCommandCenter.
  /// Native command targets are installed only after this channel actually publishes metadata.
  func start() { isStarted = true }
  func stop() { if ownsNowPlayingInfo { clear() }; removeCommandTargets(); isStarted = false }

  func update(_ metadata: Metadata) {
    guard isStarted else { return }
    acquireOwnershipIfNeeded()
    installCommandTargetsIfNeeded()
    let duration = metadata.duration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }, elapsed = duration.map { min(max(0, metadata.elapsed), $0) } ?? max(0, metadata.elapsed)
    var info: [String: Any] = [MPNowPlayingInfoPropertyServiceIdentifier: Self.serviceIdentifier, MPMediaItemPropertyTitle: metadata.title, MPMediaItemPropertyMediaType: MPMediaType.anyAudio.rawValue, MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed, MPNowPlayingInfoPropertyPlaybackRate: metadata.playbackRate, MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0]
    if let subtitle = metadata.subtitle, !subtitle.isEmpty { info[MPMediaItemPropertyArtist] = subtitle }; if let albumTitle = metadata.albumTitle, !albumTitle.isEmpty { info[MPMediaItemPropertyAlbumTitle] = albumTitle }; if let duration { info[MPMediaItemPropertyPlaybackDuration] = duration }
    ownsNowPlayingInfo = true; commandCenter.playCommand.isEnabled = true; commandCenter.pauseCommand.isEnabled = true; commandCenter.changePlaybackPositionCommand.isEnabled = duration != nil; commandCenter.nextTrackCommand.isEnabled = metadata.canGoNext; commandCenter.previousTrackCommand.isEnabled = metadata.canGoPrevious; infoCenter.nowPlayingInfo = info
    lastPublishedInfo = info
    if #available(iOS 13.0, *) { infoCenter.playbackState = metadata.playbackRate > 0 ? .playing : .paused }
  }
  func clear() {
    guard ownsNowPlayingInfo else { return }
    let currentInfo = infoCenter.nowPlayingInfo
    let stillOwnsPublishedInfo = currentInfo?[MPNowPlayingInfoPropertyServiceIdentifier] as? String == Self.serviceIdentifier && dictionariesEqual(currentInfo, lastPublishedInfo)
    if stillOwnsPublishedInfo {
      infoCenter.nowPlayingInfo = previousInfo
      restoreCommandStates()
      if #available(iOS 13.0, *), let previousPlaybackState { infoCenter.playbackState = previousPlaybackState }
    }
    ownsNowPlayingInfo = false; lastPublishedInfo = nil; previousInfo = nil; previousPlaybackState = nil; previousCommandStates.removeAll()
    removeCommandTargets()
  }
  private func acquireOwnershipIfNeeded() {
    guard !ownsNowPlayingInfo else { return }
    previousInfo = infoCenter.nowPlayingInfo
    if #available(iOS 13.0, *) { previousPlaybackState = infoCenter.playbackState }
    previousCommandStates = [
      ObjectIdentifier(commandCenter.playCommand): commandCenter.playCommand.isEnabled,
      ObjectIdentifier(commandCenter.pauseCommand): commandCenter.pauseCommand.isEnabled,
      ObjectIdentifier(commandCenter.nextTrackCommand): commandCenter.nextTrackCommand.isEnabled,
      ObjectIdentifier(commandCenter.previousTrackCommand): commandCenter.previousTrackCommand.isEnabled,
      ObjectIdentifier(commandCenter.changePlaybackPositionCommand): commandCenter.changePlaybackPositionCommand.isEnabled,
    ]
  }
  private func dictionariesEqual(_ lhs: [String: Any]?, _ rhs: [String: Any]?) -> Bool {
    switch (lhs, rhs) { case (nil, nil): return true; case let (lhs?, rhs?): return NSDictionary(dictionary: lhs).isEqual(NSDictionary(dictionary: rhs)); default: return false }
  }
  private func restoreCommandStates() {
    for command in [commandCenter.playCommand, commandCenter.pauseCommand, commandCenter.nextTrackCommand, commandCenter.previousTrackCommand, commandCenter.changePlaybackPositionCommand] {
      if let enabled = previousCommandStates[ObjectIdentifier(command)] { command.isEnabled = enabled }
    }
  }
  private func installCommandTargetsIfNeeded() { guard commandTargets.isEmpty else { return }; register(commandCenter.playCommand, command: .play); register(commandCenter.pauseCommand, command: .pause); register(commandCenter.nextTrackCommand, command: .next); register(commandCenter.previousTrackCommand, command: .previous); let seekTarget = commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in guard let self, self.ownsNowPlayingInfo, self.commandCenter.changePlaybackPositionCommand.isEnabled, let seekEvent = event as? MPChangePlaybackPositionCommandEvent, self.onRemoteCommand != nil else { return .commandFailed }; self.onRemoteCommand?(.seek, seekEvent.positionTime); return .success }; commandTargets.append((commandCenter.changePlaybackPositionCommand, seekTarget)) }
  private func removeCommandTargets() { for (command, target) in commandTargets { command.removeTarget(target) }; commandTargets.removeAll() }
  private func disablePlaybackCommands() { commandCenter.playCommand.isEnabled = false; commandCenter.pauseCommand.isEnabled = false; commandCenter.nextTrackCommand.isEnabled = false; commandCenter.previousTrackCommand.isEnabled = false; commandCenter.changePlaybackPositionCommand.isEnabled = false }
  private func register(_ remote: MPRemoteCommand, command: RemoteCommand) { let target = remote.addTarget { [weak self, weak remote] _ in guard let self, self.ownsNowPlayingInfo, remote?.isEnabled == true, self.onRemoteCommand != nil else { return .commandFailed }; self.onRemoteCommand?(command, nil); return .success }; commandTargets.append((remote, target)) }
}
