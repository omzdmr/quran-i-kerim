import Flutter
import Foundation
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Persists small native lifecycle facts so Flutter can distinguish cold launch,
/// resume, OS background eviction, termination recovery and protected-data availability.
final class NativeLifecycleStateChannel {
  static let channelName = "app.quranikerim/native_lifecycle_state"
  static let prayerWidgetKind = "PrayerTimesWidget"

  private enum Key {
    static let lastBackgroundAt = "native.lifecycle.lastBackgroundAt"
    static let lastForegroundAt = "native.lifecycle.lastForegroundAt"
    static let cleanTermination = "native.lifecycle.cleanTermination"
    static let launchCount = "native.lifecycle.launchCount"
    static let lastKnownTimeZone = "native.lifecycle.lastKnownTimeZone"
    static let lastKnownLocale = "native.lifecycle.lastKnownLocale"
    static let lastProtectedDataAvailableAt = "native.lifecycle.lastProtectedDataAvailableAt"
    static let lastLifecycleState = "native.lifecycle.lastLifecycleState"
  }

  private let channel: FlutterMethodChannel
  private let defaults: UserDefaults
  private let center: NotificationCenter
  private var observers: [NSObjectProtocol] = []
  private let hadPreviousSession: Bool
  private let previousCleanTermination: Bool
  private let previousLifecycleState: String?
  private let launchedAt = Date()
  private var restoreAcknowledged = false

  init(binaryMessenger: FlutterBinaryMessenger, defaults: UserDefaults = .standard, notificationCenter: NotificationCenter = .default) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    self.defaults = defaults; center = notificationCenter
    let previousLaunchCount = defaults.integer(forKey: Key.launchCount)
    hadPreviousSession = previousLaunchCount > 0; previousCleanTermination = hadPreviousSession && defaults.bool(forKey: Key.cleanTermination); previousLifecycleState = defaults.string(forKey: Key.lastLifecycleState)
    defaults.set(false, forKey: Key.cleanTermination); defaults.set("launching", forKey: Key.lastLifecycleState); defaults.set(previousLaunchCount + 1, forKey: Key.launchCount); defaults.set(TimeZone.current.identifier, forKey: Key.lastKnownTimeZone); defaults.set(Locale.autoupdatingCurrent.identifier, forKey: Key.lastKnownLocale)
    if UIApplication.shared.isProtectedDataAvailable { defaults.set(Date(), forKey: Key.lastProtectedDataAvailableAt) }
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }; observeLifecycle()
  }

  func markCleanTermination() { defaults.set("terminated", forKey: Key.lastLifecycleState); defaults.set(true, forKey: Key.cleanTermination) }
  func detach() { observers.forEach(center.removeObserver); observers.removeAll(); channel.setMethodCallHandler(nil) }

  private func observeLifecycle() {
    observers = [
      center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
        guard let self else { return }
        let scenes = self.sceneActivitySnapshot()
        guard scenes.foregroundCount == 0 else {
          self.emit("sceneBackgrounded", extras: ["foregroundSceneCount": scenes.foregroundCount, "connectedSceneCount": scenes.connectedCount])
          return
        }
        self.record(Key.lastBackgroundAt)
        self.recordLifecycleState("background")
        self.emit("background", extras: ["foregroundSceneCount": 0, "connectedSceneCount": scenes.connectedCount])
      },
      center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in self?.record(Key.lastForegroundAt); self?.recordLifecycleState("foreground"); self?.reconcilePrayerProjection(reason: "foreground"); self?.emit("foreground") },
      center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in self?.recordLifecycleState("active"); self?.reconcilePrayerProjection(reason: "active"); self?.emit("active", extras: ["protectedDataAvailable": UIApplication.shared.isProtectedDataAvailable]) },
      center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in self?.recordLifecycleState("inactive"); self?.emit("inactive") },
      center.addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil, queue: .main) { [weak self] _ in self?.protectedDataBecameAvailable() },
      center.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil, queue: .main) { [weak self] _ in self?.emit("protectedDataUnavailable", extras: ["protectedDataAvailable": false]) },
      center.addObserver(forName: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil, queue: .main) { [weak self] _ in self?.handleTimeZoneChange() },
      center.addObserver(forName: NSLocale.currentLocaleDidChangeNotification, object: nil, queue: .main) { [weak self] _ in self?.handleLocaleChange() },
      center.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in self?.reconcilePrayerProjection(reason: "significantTimeChange"); self?.emit("significantTimeChange", extras: ["timeZone": TimeZone.current.identifier]) },
    ]
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "snapshot": result(snapshot())
    case "acknowledgeRestore":
      restoreAcknowledged = true
      defaults.removeObject(forKey: Key.lastBackgroundAt)
      result(nil)
    case "capabilities": result(["coldLaunchDetection": true, "firstLaunchDistinction": true, "backgroundGap": true, "lifecycleEvents": true, "persistent": true, "timeZoneEvents": true, "systemLocaleEvents": true, "significantTimeChange": true, "widgetStaleReconciliation": true, "protectedDataAvailability": true, "targetedWidgetReload": true, "widgetKind": Self.prayerWidgetKind, "backgroundEvictionDetection": true, "previousLifecycleState": true, "restoreAcknowledgement": true, "multiSceneAwareBackground": true])
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func snapshot() -> [String: Any] {
    let likelyBackgroundEviction = !restoreAcknowledged && hadPreviousSession && !previousCleanTermination && previousLifecycleState == "background"
    let scenes = sceneActivitySnapshot()
    var payload: [String: Any] = ["foregroundSceneCount": scenes.foregroundCount, "connectedSceneCount": scenes.connectedCount, "launchedAtMs": milliseconds(launchedAt), "launchCount": defaults.integer(forKey: Key.launchCount), "hadPreviousSession": hadPreviousSession, "previousCleanTermination": previousCleanTermination, "likelyBackgroundEviction": likelyBackgroundEviction, "restoreAcknowledged": restoreAcknowledged, "applicationState": stateName(UIApplication.shared.applicationState), "timeZone": TimeZone.current.identifier, "systemLocale": Locale.autoupdatingCurrent.identifier, "protectedDataAvailable": UIApplication.shared.isProtectedDataAvailable]
    if let previousLifecycleState { payload["previousLifecycleState"] = previousLifecycleState }
    if let date = defaults.object(forKey: Key.lastBackgroundAt) as? Date { payload["lastBackgroundAtMs"] = milliseconds(date); payload["backgroundGapMs"] = max(0, milliseconds(Date()) - milliseconds(date)) }
    if let date = defaults.object(forKey: Key.lastForegroundAt) as? Date { payload["lastForegroundAtMs"] = milliseconds(date) }
    if let date = defaults.object(forKey: Key.lastProtectedDataAvailableAt) as? Date { payload["lastProtectedDataAvailableAtMs"] = milliseconds(date) }
    return payload
  }

  private func sceneActivitySnapshot() -> (foregroundCount: Int, connectedCount: Int) {
    let scenes = UIApplication.shared.connectedScenes
    let foregroundCount = scenes.reduce(into: 0) { count, scene in
      if scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive { count += 1 }
    }
    return (foregroundCount, scenes.count)
  }

  private func protectedDataBecameAvailable() { record(Key.lastProtectedDataAvailableAt); reconcilePrayerProjection(reason: "protectedDataAvailable"); emit("protectedDataAvailable", extras: ["protectedDataAvailable": true]) }
  private func handleTimeZoneChange() { let previous = defaults.string(forKey: Key.lastKnownTimeZone); let current = TimeZone.current.identifier; defaults.set(current, forKey: Key.lastKnownTimeZone); let purged = purgeStalePrayerProjection(); emit("timeZoneChanged", extras: ["previousTimeZone": previous ?? "", "timeZone": current, "widgetSnapshotPurged": purged]) }
  private func handleLocaleChange() { let previous = defaults.string(forKey: Key.lastKnownLocale); let current = Locale.autoupdatingCurrent.identifier; defaults.set(current, forKey: Key.lastKnownLocale); reloadPrayerWidget(); emit("systemLocaleChanged", extras: ["previousLocale": previous ?? "", "systemLocale": current, "widgetReloadRequested": true]) }
  private func reconcilePrayerProjection(reason: String) { let purged = purgeStalePrayerProjection(); guard purged else { return }; emit("widgetSnapshotInvalidated", extras: ["reason": reason, "timeZone": TimeZone.current.identifier]) }
  private func purgeStalePrayerProjection() -> Bool { guard UIApplication.shared.isProtectedDataAvailable, let store = WidgetSnapshotStore(), store.purgeIfStale() else { return false }; reloadPrayerWidget(); return true }
  private func reloadPrayerWidget() {
#if canImport(WidgetKit)
    if #available(iOS 14.0, *) { WidgetCenter.shared.reloadTimelines(ofKind: Self.prayerWidgetKind) }
#endif
  }
  private func record(_ key: String) { defaults.set(Date(), forKey: key) }
  private func recordLifecycleState(_ state: String) { defaults.set(state, forKey: Key.lastLifecycleState) }
  private func emit(_ state: String, extras: [String: Any] = [:]) { var payload: [String: Any] = ["state": state, "atMs": milliseconds(Date())]; extras.forEach { payload[$0.key] = $0.value }; channel.invokeMethod("lifecycleChanged", arguments: payload) }
  private func milliseconds(_ date: Date) -> Int64 { Int64(date.timeIntervalSince1970 * 1000) }
  private func stateName(_ state: UIApplication.State) -> String { switch state { case .active: return "active"; case .inactive: return "inactive"; case .background: return "background"; @unknown default: return "unknown" } }
}
