import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let audioSessionCoordinator = AudioSessionCoordinator.shared
  private let backupExclusionCoordinator = BackupExclusionCoordinator()
  private var backupExclusionChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    audioSessionCoordinator.start()
    GeneratedPluginRegistrant.register(with: self)
    configureBackupExclusionChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    backupExclusionChannel?.setMethodCallHandler(nil)
    audioSessionCoordinator.stop()
    super.applicationWillTerminate(application)
  }

  private func configureBackupExclusionChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      NSLog("Unable to install backup exclusion channel: Flutter view controller unavailable.")
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.omzdmr.quran_i_kerim/backup_exclusion",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(
          FlutterError(
            code: "backup_exclusion_unavailable",
            message: "The native backup exclusion service is unavailable.",
            details: nil
          )
        )
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
        case "excludeReproducibleContent":
          status = try self.backupExclusionCoordinator.exclude(
            storageArea: storageArea,
            relativePath: relativePath
          )
        case "getBackupExclusionStatus":
          status = try self.backupExclusionCoordinator.status(
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
    backupExclusionChannel = channel
  }
}
