import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let audioSessionCoordinator = AudioSessionCoordinator.shared
  private var backupExclusionChannel: BackupExclusionChannel?

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
    backupExclusionChannel?.detach()
    audioSessionCoordinator.stop()
    super.applicationWillTerminate(application)
  }

  private func configureBackupExclusionChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      NSLog("Unable to install backup exclusion channel: Flutter view controller unavailable.")
      return
    }

    backupExclusionChannel = BackupExclusionChannel(
      binaryMessenger: controller.binaryMessenger
    )
  }
}
