import Flutter
import Foundation

/// Flutter-facing boundary for iOS backup exclusion.
final class BackupExclusionChannel {
  static let name = "com.omzdmr.quran_i_kerim/backup_exclusion"
  static let excludeMethod = "excludeReproducibleContent"
  static let statusMethod = "getBackupExclusionStatus"

  private let coordinator: BackupExclusionCoordinator
  private let channel: FlutterMethodChannel

  init(binaryMessenger: FlutterBinaryMessenger, coordinator: BackupExclusionCoordinator = BackupExclusionCoordinator()) {
    self.coordinator = coordinator
    channel = FlutterMethodChannel(name: Self.name, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }

  func detach() { channel.setMethodCallHandler(nil) }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == Self.excludeMethod || call.method == Self.statusMethod else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let arguments = call.arguments as? [String: Any],
          let storageArea = arguments["storageArea"] as? String,
          let relativePath = arguments["relativePath"] as? String else {
      result(FlutterError(code: "invalid_backup_exclusion_arguments", message: "storageArea and relativePath are required.", details: nil))
      return
    }
    do {
      let status: BackupExclusionCoordinator.Status
      switch call.method {
      case Self.excludeMethod:
        status = try coordinator.exclude(storageArea: storageArea, relativePath: relativePath)
      case Self.statusMethod:
        status = try coordinator.status(storageArea: storageArea, relativePath: relativePath)
      default:
        result(FlutterMethodNotImplemented)
        return
      }
      result(status.dictionary)
    } catch {
      result(flutterError(from: error))
    }
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

/// Native-only bridge for lock-screen / Control Center metadata and commands.
/// Shared Dart may adopt this stable contract later without changing native
/// MediaPlayer ownership. Until then, remote commands fail closed rather than
/// pretending playback changed.
final class NowPlayingChannel {
  static let name = "com.omzdmr.quran_i_kerim/now_playing"
  private let coordinator: NowPlayingCoordinator
  private let channel: FlutterMethodChannel

  init(binaryMessenger: FlutterBinaryMessenger, coordinator: NowPlayingCoordinator = NowPlayingCoordinator()) {
    self.coordinator = coordinator
    channel = FlutterMethodChannel(name: Self.name, binaryMessenger: binaryMessenger)
    coordinator.onRemoteCommand = { [weak channel] command, position in
      var payload: [String: Any] = ["command": command.rawValue]
      if let position { payload["positionSeconds"] = position }
      channel?.invokeMethod("remoteCommand", arguments: payload)
    }
    coordinator.start()
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }

  func detach() {
    channel.setMethodCallHandler(nil)
    coordinator.onRemoteCommand = nil
    coordinator.stop()
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateNowPlaying":
      guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        result(FlutterError(code: "invalid_now_playing_metadata", message: "A non-empty title is required.", details: nil))
        return
      }
      let elapsed = (args["elapsedSeconds"] as? NSNumber)?.doubleValue ?? 0
      let rate = (args["playbackRate"] as? NSNumber)?.doubleValue ?? 0
      let duration = (args["durationSeconds"] as? NSNumber)?.doubleValue
      guard elapsed.isFinite, elapsed >= 0, rate.isFinite, rate >= 0,
            duration == nil || (duration!.isFinite && duration! > 0) else {
        result(FlutterError(code: "invalid_now_playing_timing", message: "Playback timing values are invalid.", details: nil))
        return
      }
      coordinator.update(.init(
        title: title,
        subtitle: args["subtitle"] as? String,
        albumTitle: args["albumTitle"] as? String,
        duration: duration,
        elapsed: elapsed,
        playbackRate: rate
      ))
      result(nil)

    case "clearNowPlaying":
      coordinator.clear()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
