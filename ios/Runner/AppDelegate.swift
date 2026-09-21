import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let audioSessionCoordinator = AudioSessionCoordinator.shared
  private var backupExclusionChannel: BackupExclusionChannel?
  private var nowPlayingChannel: NowPlayingChannel?
  private var audioLifecycleChannel: AudioLifecycleChannel?
  private var notificationPermissionChannel: NotificationPermissionChannel?
  private var locationHeadingChannel: LocationHeadingChannel?

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
    locationHeadingChannel?.detach()
    notificationPermissionChannel?.detach()
    audioLifecycleChannel?.detach()
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
    let messenger = controller.binaryMessenger
    backupExclusionChannel = BackupExclusionChannel(binaryMessenger: messenger)
    nowPlayingChannel = NowPlayingChannel(binaryMessenger: messenger)
    audioLifecycleChannel = AudioLifecycleChannel(binaryMessenger: messenger)
    notificationPermissionChannel = NotificationPermissionChannel(binaryMessenger: messenger)
    locationHeadingChannel = LocationHeadingChannel(binaryMessenger: messenger)
  }
}
