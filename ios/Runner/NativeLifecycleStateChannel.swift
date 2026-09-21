import Flutter
import Foundation
import UIKit

/// Persists small native lifecycle facts so Flutter can distinguish cold launch, resume,
/// termination recovery and background gaps without requiring a backend.
final class NativeLifecycleStateChannel {
  static let channelName = "app.quranikerim/native_lifecycle_state"

  private enum Key {
    static let lastBackgroundAt = "native.lifecycle.lastBackgroundAt"
    static let lastForegroundAt = "native.lifecycle.lastForegroundAt"
    static let cleanTermination = "native.lifecycle.cleanTermination"
    static let launchCount = "native.lifecycle.launchCount"
  }

  private let channel: FlutterMethodChannel
  private let defaults: UserDefaults
  private let center: NotificationCenter
  private var observers: [NSObjectProtocol] = []
  private let previousCleanTermination: Bool
  private let launchedAt = Date()

  init(
    binaryMessenger: FlutterBinaryMessenger,
    defaults: UserDefaults = .standard,
    notificationCenter: NotificationCenter = .default
  ) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    self.defaults = defaults
    center = notificationCenter
    previousCleanTermination = defaults.bool(forKey: Key.cleanTermination)
    defaults.set(false, forKey: Key.cleanTermination)
    defaults.set(defaults.integer(forKey: Key.launchCount) + 1, forKey: Key.launchCount)

    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
    observeLifecycle()
  }

  func markCleanTermination() {
    defaults.set(true, forKey: Key.cleanTermination)
  }

  func detach() {
    observers.forEach(center.removeObserver)
    observers.removeAll()
    channel.setMethodCallHandler(nil)
  }

  private func observeLifecycle() {
    observers = [
      center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
        self?.record(Key.lastBackgroundAt)
        self?.emit("background")
      },
      center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
        self?.record(Key.lastForegroundAt)
        self?.emit("foreground")
      },
      center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
        self?.emit("active")
      },
      center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
        self?.emit("inactive")
      }
    ]
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "snapshot": result(snapshot())
    case "acknowledgeRestore":
      defaults.removeObject(forKey: Key.lastBackgroundAt)
      result(nil)
    case "capabilities":
      result(["coldLaunchDetection": true, "backgroundGap": true, "lifecycleEvents": true, "persistent": true])
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func snapshot() -> [String: Any] {
    var payload: [String: Any] = [
      "launchedAtMs": milliseconds(launchedAt),
      "launchCount": defaults.integer(forKey: Key.launchCount),
      "previousCleanTermination": previousCleanTermination,
      "applicationState": stateName(UIApplication.shared.applicationState)
    ]
    if let date = defaults.object(forKey: Key.lastBackgroundAt) as? Date {
      payload["lastBackgroundAtMs"] = milliseconds(date)
      payload["backgroundGapMs"] = max(0, milliseconds(Date()) - milliseconds(date))
    }
    if let date = defaults.object(forKey: Key.lastForegroundAt) as? Date {
      payload["lastForegroundAtMs"] = milliseconds(date)
    }
    return payload
  }

  private func record(_ key: String) { defaults.set(Date(), forKey: key) }

  private func emit(_ state: String) {
    channel.invokeMethod("lifecycleChanged", arguments: ["state": state, "atMs": milliseconds(Date())])
  }

  private func milliseconds(_ date: Date) -> Int64 { Int64(date.timeIntervalSince1970 * 1000) }

  private func stateName(_ state: UIApplication.State) -> String {
    switch state {
    case .active: return "active"
    case .inactive: return "inactive"
    case .background: return "background"
    @unknown default: return "unknown"
    }
  }
}
