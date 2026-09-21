import Flutter
import Foundation
import UserNotifications

final class BackupExclusionChannel {
  static let name = "com.omzdmr.quran_i_kerim/backup_exclusion"
  static let excludeMethod = "excludeReproducibleContent"
  static let statusMethod = "getBackupExclusionStatus"
  private let coordinator: BackupExclusionCoordinator
  private let channel: FlutterMethodChannel
  init(binaryMessenger: FlutterBinaryMessenger, coordinator: BackupExclusionCoordinator = BackupExclusionCoordinator()) {
    self.coordinator = coordinator; channel = FlutterMethodChannel(name: Self.name, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }
  func detach() { channel.setMethodCallHandler(nil) }
  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == Self.excludeMethod || call.method == Self.statusMethod else { result(FlutterMethodNotImplemented); return }
    guard let arguments = call.arguments as? [String: Any], let storageArea = arguments["storageArea"] as? String, let relativePath = arguments["relativePath"] as? String else { result(FlutterError(code: "invalid_backup_exclusion_arguments", message: "storageArea and relativePath are required.", details: nil)); return }
    do {
      let status = call.method == Self.excludeMethod ? try coordinator.exclude(storageArea: storageArea, relativePath: relativePath) : try coordinator.status(storageArea: storageArea, relativePath: relativePath)
      result(status.dictionary)
    } catch { result(flutterError(from: error)) }
  }
  private func flutterError(from error: Error) -> FlutterError {
    let code: String
    switch error {
    case BackupExclusionCoordinator.ExclusionError.unsupportedStorageArea: code = "unsupported_backup_storage_area"
    case BackupExclusionCoordinator.ExclusionError.invalidRelativePath: code = "invalid_backup_relative_path"
    case BackupExclusionCoordinator.ExclusionError.baseDirectoryUnavailable: code = "backup_directory_unavailable"
    case BackupExclusionCoordinator.ExclusionError.itemDoesNotExist: code = "backup_item_not_found"
    default: code = "backup_exclusion_failed"
    }
    return FlutterError(code: code, message: error.localizedDescription, details: nil)
  }
}

final class NowPlayingChannel {
  static let name = "com.omzdmr.quran_i_kerim/now_playing"
  private let coordinator: NowPlayingCoordinator
  private let channel: FlutterMethodChannel
  init(binaryMessenger: FlutterBinaryMessenger, coordinator: NowPlayingCoordinator = NowPlayingCoordinator()) {
    self.coordinator = coordinator; channel = FlutterMethodChannel(name: Self.name, binaryMessenger: binaryMessenger)
    coordinator.onRemoteCommand = { [weak channel] command, position in
      var payload: [String: Any] = ["command": command.rawValue]; if let position { payload["positionSeconds"] = position }
      channel?.invokeMethod("remoteCommand", arguments: payload)
    }
    coordinator.start(); channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }
  func detach() { channel.setMethodCallHandler(nil); coordinator.onRemoteCommand = nil; coordinator.stop() }
  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateNowPlaying":
      guard let args = call.arguments as? [String: Any], let title = args["title"] as? String, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { result(FlutterError(code: "invalid_now_playing_metadata", message: "A non-empty title is required.", details: nil)); return }
      let elapsed = (args["elapsedSeconds"] as? NSNumber)?.doubleValue ?? 0, rate = (args["playbackRate"] as? NSNumber)?.doubleValue ?? 0, duration = (args["durationSeconds"] as? NSNumber)?.doubleValue
      guard elapsed.isFinite, elapsed >= 0, rate.isFinite, rate >= 0, duration == nil || (duration!.isFinite && duration! > 0) else { result(FlutterError(code: "invalid_now_playing_timing", message: "Playback timing values are invalid.", details: nil)); return }
      coordinator.update(.init(title: title, subtitle: args["subtitle"] as? String, albumTitle: args["albumTitle"] as? String, duration: duration, elapsed: elapsed, playbackRate: rate)); result(nil)
    case "clearNowPlaying": coordinator.clear(); result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }
}

final class AudioLifecycleChannel {
  static let name = "com.omzdmr.quran_i_kerim/audio_lifecycle"
  private let channel: FlutterMethodChannel
  private let notificationCenter: NotificationCenter
  private var observers: [NSObjectProtocol] = []
  init(binaryMessenger: FlutterBinaryMessenger, notificationCenter: NotificationCenter = .default) {
    self.notificationCenter = notificationCenter; channel = FlutterMethodChannel(name: Self.name, binaryMessenger: binaryMessenger)
    observers = [
      notificationCenter.addObserver(forName: AudioSessionCoordinator.interruptionBeganNotification, object: nil, queue: .main) { [weak channel] _ in channel?.invokeMethod("interruptionBegan", arguments: nil) },
      notificationCenter.addObserver(forName: AudioSessionCoordinator.interruptionEndedNotification, object: nil, queue: .main) { [weak channel] note in channel?.invokeMethod("interruptionEnded", arguments: ["shouldResume": note.userInfo?["shouldResume"] as? Bool ?? false]) },
      notificationCenter.addObserver(forName: AudioSessionCoordinator.routeChangedNotification, object: nil, queue: .main) { [weak channel] note in channel?.invokeMethod("routeChanged", arguments: ["reason": note.userInfo?["reason"] as? UInt ?? 0]) },
    ]
  }
  func detach() { observers.forEach(notificationCenter.removeObserver); observers.removeAll() }
}

/// Central native notification-permission boundary. Permission is requested only
/// after an explicit shared-layer call; app launch never triggers Apple's prompt.
final class NotificationPermissionChannel {
  static let name = "com.omzdmr.quran_i_kerim/notification_permission"
  private let center: UNUserNotificationCenter
  private let channel: FlutterMethodChannel

  init(binaryMessenger: FlutterBinaryMessenger, center: UNUserNotificationCenter = .current()) {
    self.center = center
    channel = FlutterMethodChannel(name: Self.name, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }
  func detach() { channel.setMethodCallHandler(nil) }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getNotificationPermissionStatus":
      center.getNotificationSettings { settings in
        DispatchQueue.main.async { result(Self.statusName(settings.authorizationStatus)) }
      }
    case "requestNotificationPermission":
      center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        DispatchQueue.main.async {
          if let error { result(FlutterError(code: "notification_permission_failed", message: error.localizedDescription, details: nil)) }
          else { result(["granted": granted]) }
        }
      }
    default: result(FlutterMethodNotImplemented)
    }
  }

  private static func statusName(_ status: UNAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .authorized: return "authorized"
    case .provisional: return "provisional"
    case .ephemeral: return "ephemeral"
    @unknown default: return "unknown"
    }
  }
}
