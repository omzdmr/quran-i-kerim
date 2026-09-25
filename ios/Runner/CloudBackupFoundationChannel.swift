import Flutter
import Foundation

final class CloudBackupFoundationChannel {
  static let name = "app.quranikerim/native_icloud_foundation"
  private let channel: FlutterMethodChannel
  private let foundation: CloudBackupFoundation
  private let notificationCenter: NotificationCenter
  private var identityObserver: NSObjectProtocol?

  init(binaryMessenger: FlutterBinaryMessenger, foundation: CloudBackupFoundation = CloudBackupFoundation(), notificationCenter: NotificationCenter = .default) {
    self.foundation = foundation
    self.notificationCenter = notificationCenter
    channel = FlutterMethodChannel(name: Self.name, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
    identityObserver = notificationCenter.addObserver(forName: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil, queue: .main) { [weak self] _ in
      guard let self else { return }
      self.channel.invokeMethod("statusChanged", arguments: self.foundation.status().dictionary)
    }
  }

  func detach() {
    channel.setMethodCallHandler(nil)
    if let identityObserver { notificationCenter.removeObserver(identityObserver) }
    identityObserver = nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities":
      result([
        "foundationOnly": true,
        "finalProvider": false,
        "accountAvailability": true,
        "accountChangeEvents": true,
        "atomicFileOperations": true,
        "protectedTemporaryStaging": true,
        "containerIdentifier": CloudBackupFoundation.containerIdentifier
      ])
    case "status":
      result(foundation.status().dictionary)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
