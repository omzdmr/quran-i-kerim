import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let audioSessionCoordinator = AudioSessionCoordinator.shared

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    audioSessionCoordinator.start()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    audioSessionCoordinator.stop()
    super.applicationWillTerminate(application)
  }
}
