import Flutter
import Foundation

final class CloudBackupFoundationChannel {
  static let name = "app.quranikerim/native_icloud_foundation"
  private let channel: FlutterMethodChannel
  private let foundation: CloudBackupFoundation

  init(binaryMessenger: FlutterBinaryMessenger, foundation: CloudBackupFoundation = CloudBackupFoundation()) {
    self.foundation = foundation
    channel = FlutterMethodChannel(name: Self.name, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }

  func detach() { channel.setMethodCallHandler(nil) }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities":
      result(["foundationOnly": true, "finalProvider": false, "accountAvailability": true, "atomicFileOperations": true, "protectedTemporaryStaging": true, "containerIdentifier": CloudBackupFoundation.containerIdentifier])
    case "status":
      result(foundation.status().dictionary)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
