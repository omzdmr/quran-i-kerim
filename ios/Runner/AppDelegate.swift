import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let audioSessionCoordinator = AudioSessionCoordinator.shared
  private var backupExclusionChannel: BackupExclusionChannel?
  private var nowPlayingChannel: NowPlayingChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    audioSessionCoordinator.start()
    GeneratedPluginRegistrant.register(with: self)
    configureNativeChannels()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    nowPlayingChannel?.detach()
    backupExclusionChannel?.detach()
    audioSessionCoordinator.stop()
    super.applicationWillTerminate(application)
  }

  private func configureNativeChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      NSLog("Unable to install native channels: Flutter view controller unavailable.")
      return
    }

    backupExclusionChannel = BackupExclusionChannel(binaryMessenger: controller.binaryMessenger)
    nowPlayingChannel = NowPlayingChannel(binaryMessenger: controller.binaryMessenger)
  }
}
