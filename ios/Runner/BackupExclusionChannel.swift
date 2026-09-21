import Flutter
import Foundation

/// Flutter-facing boundary for iOS backup exclusion.
///
/// It intentionally exposes only exclusion and status checks. User-created data
/// must never be routed through this channel by the shared storage layer.
final class BackupExclusionChannel {
  static let name = "com.omzdmr.quran_i_kerim/backup_exclusion"
  static let excludeMethod = "excludeReproducibleContent"
  static let statusMethod = "getBackupExclusionStatus"

  private let coordinator: BackupExclusionCoordinator
  private let channel: FlutterMethodChannel

  init(
    binaryMessenger: FlutterBinaryMessenger,
    coordinator: BackupExclusionCoordinator = BackupExclusionCoordinator()
  ) {
    self.coordinator = coordinator
    channel = FlutterMethodChannel(
      name: Self.name,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  func detach() {
    channel.setMethodCallHandler(nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      call.method == Self.excludeMethod || call.method == Self.statusMethod
    else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard
      let arguments = call.arguments as? [String: Any],
      let storageArea = arguments["storageArea"] as? String,
      let relativePath = arguments["relativePath"] as? String
    else {
      result(
        FlutterError(
          code: "invalid_backup_exclusion_arguments",
          message: "storageArea and relativePath are required.",
          details: nil
        )
      )
      return
    }

    do {
      let status: BackupExclusionCoordinator.Status
      switch call.method {
      case Self.excludeMethod:
        status = try coordinator.exclude(
          storageArea: storageArea,
          relativePath: relativePath
        )
      case Self.statusMethod:
        status = try coordinator.status(
          storageArea: storageArea,
          relativePath: relativePath
        )
      default:
        result(FlutterMethodNotImplemented)
        return
      }
      result(status.dictionary)
    } catch {
      result(
        FlutterError(
          code: "backup_exclusion_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }
}
