import Flutter
import Foundation
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Persists small native lifecycle facts so Flutter can distinguish cold launch, resume,
/// termination recovery and background gaps without requiring a backend.
final class NativeLifecycleStateChannel {
  static let channelName = "app.quranikerim/native_lifecycle_state"

  private enum Key {
    static let lastBackgroundAt = "native.lifecycle.lastBackgroundAt"
    static let lastForegroundAt = "native.lifecycle.lastForegroundAt"
    static let cleanTermination = "native.lifecycle.cleanTermination"
    static let launchCount = "native.lifecycle.launchCount"
    static let lastKnownTimeZone = "native.lifecycle.lastKnownTimeZone"
  }

  private let channel: FlutterMethodChannel
  private let defaults: UserDefaults
  private let center: NotificationCenter
  private var observers: [NSObjectProtocol] = []
  private let hadPreviousSession: Bool
  private let previousCleanTermination: Bool
  private let launchedAt = Date()

  init(binaryMessenger: FlutterBinaryMessenger, defaults: UserDefaults = .standard, notificationCenter: NotificationCenter = .default) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    self.defaults = defaults
    center = notificationCenter
    let previousLaunchCount = defaults.integer(forKey: Key.launchCount)
    hadPreviousSession = previousLaunchCount > 0
    previousCleanTermination = hadPreviousSession && defaults.bool(forKey: Key.cleanTermination)
    defaults.set(false, forKey: Key.cleanTermination)
    defaults.set(previousLaunchCount + 1, forKey: Key.launchCount)
    defaults.set(TimeZone.current.identifier, forKey: Key.lastKnownTimeZone)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
    observeLifecycle()
  }

  func markCleanTermination() { defaults.set(true, forKey: Key.cleanTermination) }

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
        self?.reconcilePrayerProjection(reason: "foreground")
        self?.emit("foreground")
      },
      center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
        self?.reconcilePrayerProjection(reason: "active")
        self?.emit("active")
      },
      center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
        self?.emit("inactive")
      },
      center.addObserver(forName: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil, queue: .main) { [weak self] _ in
        self?.handleTimeZoneChange()
      },
      center.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in
        self?.reconcilePrayerProjection(reason: "significantTimeChange")
        self?.emit("significantTimeChange", extras: ["timeZone": TimeZone.current.identifier])
      }
    ]
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "snapshot": result(snapshot())
    case "acknowledgeRestore": defaults.removeObject(forKey: Key.lastBackgroundAt); result(nil)
    case "capabilities":
      result([
        "coldLaunchDetection": true,
        "firstLaunchDistinction": true,
        "backgroundGap": true,
        "lifecycleEvents": true,
        "persistent": true,
        "timeZoneEvents": true,
        "significantTimeChange": true,
        "widgetStaleReconciliation": true
      ])
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func snapshot() -> [String: Any] {
    var payload: [String: Any] = [
      "launchedAtMs": milliseconds(launchedAt),
      "launchCount": defaults.integer(forKey: Key.launchCount),
      "hadPreviousSession": hadPreviousSession,
      "previousCleanTermination": previousCleanTermination,
      "applicationState": stateName(UIApplication.shared.applicationState),
      "timeZone": TimeZone.current.identifier
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

  private func handleTimeZoneChange() {
    let previous = defaults.string(forKey: Key.lastKnownTimeZone)
    let current = TimeZone.current.identifier
    defaults.set(current, forKey: Key.lastKnownTimeZone)
    let purged = purgeStalePrayerProjection()
    emit("timeZoneChanged", extras: [
      "previousTimeZone": previous ?? "",
      "timeZone": current,
      "widgetSnapshotPurged": purged
    ])
  }

  private func reconcilePrayerProjection(reason: String) {
    let purged = purgeStalePrayerProjection()
    guard purged else { return }
    emit("widgetSnapshotInvalidated", extras: ["reason": reason, "timeZone": TimeZone.current.identifier])
  }

  private func purgeStalePrayerProjection() -> Bool {
    guard let store = WidgetSnapshotStore(), store.purgeIfStale() else { return false }
    #if canImport(WidgetKit)
    if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
    #endif
    return true
  }

  private func record(_ key: String) { defaults.set(Date(), forKey: key) }

  private func emit(_ state: String, extras: [String: Any] = [:]) {
    var payload: [String: Any] = ["state": state, "atMs": milliseconds(Date())]
    extras.forEach { payload[$0.key] = $0.value }
    channel.invokeMethod("lifecycleChanged", arguments: payload)
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
