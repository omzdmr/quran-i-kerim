import Flutter
import Foundation
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

final class WidgetSnapshotChannel {
  static let channelName = "app.quranikerim/native_widget_snapshot"
  private let channel: FlutterMethodChannel
  private let store: WidgetSnapshotStore?
  private let notificationCenter: NotificationCenter
  private var observers: [NSObjectProtocol] = []

  init(binaryMessenger: FlutterBinaryMessenger, store: WidgetSnapshotStore? = WidgetSnapshotStore(), notificationCenter: NotificationCenter = .default) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger); self.store = store; self.notificationCenter = notificationCenter
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }; installFreshnessObservers()
  }
  deinit { removeFreshnessObservers() }
  func detach() { removeFreshnessObservers(); channel.setMethodCallHandler(nil) }

  private func installFreshnessObservers() {
    let names: [Notification.Name] = [UIApplication.significantTimeChangeNotification, NSNotification.Name.NSSystemTimeZoneDidChange, UIApplication.didBecomeActiveNotification]
    observers = names.map { name in notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in self?.handleFreshnessEvent(notification) } }
  }
  private func removeFreshnessObservers() { observers.forEach(notificationCenter.removeObserver); observers.removeAll() }
  private func handleFreshnessEvent(_ notification: Notification) {
    guard let store else { return }
    let purged = store.purgeIfStale(now: Date(), timeZone: .autoupdatingCurrent)
    if purged || notification.name != UIApplication.didBecomeActiveNotification { reloadWidgets() }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities": result(["schemaVersion": WidgetPrayerSnapshot.schemaVersion, "appGroup": store != nil, "freshnessRequired": true, "freshnessReason": true, "privacyRedaction": true, "stalePurge": true, "corruptPayloadQuarantine": true, "invalidationDiagnostics": true, "policyInvalidation": true, "systemTimeInvalidation": true, "timeZoneInvalidation": true, "foregroundRevalidation": true])
    case "publish": publish(call.arguments, result: result)
    case "clear": store?.clear(); reloadWidgets(); result(nil)
    case "purgeIfStale": let purged = store?.purgeIfStale() ?? false; if purged { reloadWidgets() }; result(["purged": purged, "reason": store?.lastInvalidationReason() as Any])
    case "invalidatePolicy": invalidatePolicy(call.arguments, result: result)
    case "status": result(statusPayload())
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func invalidatePolicy(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let fingerprint = args["calculationFingerprint"] as? String, !fingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { result(FlutterError(code: "invalid_arguments", message: "invalidatePolicy requires calculationFingerprint.", details: nil)); return }
    let purged = store?.purgeIfPolicyChanged(currentFingerprint: fingerprint) ?? false
    if purged { reloadWidgets() }
    result(["purged": purged, "reason": store?.lastInvalidationReason() as Any])
  }

  private func publish(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let store else { result(FlutterError(code: "app_group_unavailable", message: "Shared widget storage is unavailable.", details: nil)); return }
    guard let args = arguments as? [String: Any], let generatedMs = number(args["generatedAtMs"]), let validUntilMs = number(args["validUntilMs"]), let timeZone = args["timeZone"] as? String, let fingerprint = args["calculationFingerprint"] as? String else { result(FlutterError(code: "invalid_arguments", message: "publish requires generatedAtMs, validUntilMs, timeZone and calculationFingerprint.", details: nil)); return }
    let privacyRaw = (args["privacyMode"] as? String) ?? "standard"
    guard let privacy = WidgetPrayerSnapshot.PrivacyMode(rawValue: privacyRaw) else { result(FlutterError(code: "invalid_privacy_mode", message: "privacyMode must be standard or redacted.", details: nil)); return }
    let nextPrayerMs = number(args["nextPrayerAtMs"])
    let snapshot = WidgetPrayerSnapshot(generatedAt: Date(timeIntervalSince1970: generatedMs / 1000), validUntil: Date(timeIntervalSince1970: validUntilMs / 1000), timeZoneIdentifier: timeZone, calculationFingerprint: fingerprint, nextPrayerID: args["nextPrayerId"] as? String, nextPrayerAt: nextPrayerMs.map { Date(timeIntervalSince1970: $0 / 1000) }, displayName: args["displayName"] as? String, privacyMode: privacy)
    do { try store.save(snapshot); reloadWidgets(); result(["stored": true, "validUntilMs": validUntilMs, "freshness": WidgetPrayerSnapshot.Freshness.fresh.rawValue]) }
    catch { result(FlutterError(code: "snapshot_rejected", message: error.localizedDescription, details: nil)) }
  }

  private func statusPayload() -> [String: Any] {
    guard let store else { return ["available": false, "hasSnapshot": false, "fresh": false, "freshness": "missing"] }
    guard let snapshot = store.validatedLoad() else { return ["available": true, "hasSnapshot": false, "fresh": false, "freshness": "missing", "lastInvalidationReason": store.lastInvalidationReason() as Any] }
    let now = Date(), freshness = snapshot.freshness(at: now)
    return ["available": true, "hasSnapshot": true, "fresh": freshness == .fresh, "freshness": freshness.rawValue, "generatedAtMs": Int64(snapshot.generatedAt.timeIntervalSince1970 * 1000), "validUntilMs": Int64(snapshot.validUntil.timeIntervalSince1970 * 1000), "timeZone": snapshot.timeZoneIdentifier, "privacyMode": snapshot.privacyMode.rawValue, "calculationFingerprint": snapshot.calculationFingerprint]
  }

  private func number(_ value: Any?) -> Double? { if let number = value as? NSNumber { return number.doubleValue }; if let value = value as? Double { return value }; if let value = value as? Int64 { return Double(value) }; if let value = value as? Int { return Double(value) }; return nil }
  private func reloadWidgets() { #if canImport(WidgetKit)
    if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
    #endif
  }
}
