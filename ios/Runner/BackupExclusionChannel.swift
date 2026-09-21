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
      result(flutterError(from: error))
    }
  }

  private func flutterError(from error: Error) -> FlutterError {
    let code: String
    switch error {
    case BackupExclusionCoordinator.ExclusionError.unsupportedStorageArea:
      code = "unsupported_backup_storage_area"
    case BackupExclusionCoordinator.ExclusionError.invalidRelativePath:
      code = "invalid_backup_relative_path"
    case BackupExclusionCoordinator.ExclusionError.baseDirectoryUnavailable:
      code = "backup_directory_unavailable"
    case BackupExclusionCoordinator.ExclusionError.itemDoesNotExist:
      code = "backup_item_not_found"
    default:
      code = "backup_exclusion_failed"
    }

    return FlutterError(
      code: code,
      message: error.localizedDescription,
      details: nil
    )
  }
}
