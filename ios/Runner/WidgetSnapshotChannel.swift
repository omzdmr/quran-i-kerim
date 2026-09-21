import Flutter
import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Native boundary for publishing a compact widget projection from Flutter-owned prayer state.
/// No prayer calculation is performed here; this prevents the iOS extension from inventing
/// religious data or drifting from the shared calculation policy.
final class WidgetSnapshotChannel {
  static let channelName = "app.quranikerim/native_widget_snapshot"

  private let channel: FlutterMethodChannel
  private let store: WidgetSnapshotStore?

  init(binaryMessenger: FlutterBinaryMessenger, store: WidgetSnapshotStore? = WidgetSnapshotStore()) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    self.store = store
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  func detach() {
    channel.setMethodCallHandler(nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities":
      result([
        "schemaVersion": WidgetPrayerSnapshot.schemaVersion,
        "appGroup": store != nil,
        "freshnessRequired": true,
        "privacyRedaction": true
      ])
    case "publish":
      publish(call.arguments, result: result)
    case "clear":
      store?.clear()
      reloadWidgets()
      result(nil)
    case "status":
      result(statusPayload())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func publish(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let store else {
      result(FlutterError(code: "app_group_unavailable", message: "Shared widget storage is unavailable.", details: nil))
      return
    }
    guard let args = arguments as? [String: Any],
          let generatedMs = number(args["generatedAtMs"]),
          let validUntilMs = number(args["validUntilMs"]),
          let timeZone = args["timeZone"] as? String,
          let fingerprint = args["calculationFingerprint"] as? String else {
      result(FlutterError(code: "invalid_arguments", message: "publish requires generatedAtMs, validUntilMs, timeZone and calculationFingerprint.", details: nil))
      return
    }

    let privacyRaw = (args["privacyMode"] as? String) ?? "standard"
    guard let privacy = WidgetPrayerSnapshot.PrivacyMode(rawValue: privacyRaw) else {
      result(FlutterError(code: "invalid_privacy_mode", message: "privacyMode must be standard or redacted.", details: nil))
      return
    }

    let nextPrayerMs = number(args["nextPrayerAtMs"])
    let snapshot = WidgetPrayerSnapshot(
      generatedAt: Date(timeIntervalSince1970: generatedMs / 1000),
      validUntil: Date(timeIntervalSince1970: validUntilMs / 1000),
      timeZoneIdentifier: timeZone,
      calculationFingerprint: fingerprint,
      nextPrayerID: args["nextPrayerId"] as? String,
      nextPrayerAt: nextPrayerMs.map { Date(timeIntervalSince1970: $0 / 1000) },
      displayName: args["displayName"] as? String,
      privacyMode: privacy
    )

    do {
      try store.save(snapshot)
      reloadWidgets()
      result(["stored": true, "validUntilMs": validUntilMs])
    } catch {
      result(FlutterError(code: "snapshot_rejected", message: error.localizedDescription, details: nil))
    }
  }

  private func statusPayload() -> [String: Any] {
    guard let store, let snapshot = store.load() else {
      return ["available": store != nil, "hasSnapshot": false, "fresh": false]
    }
    let now = Date()
    return [
      "available": true,
      "hasSnapshot": true,
      "fresh": snapshot.isFresh(at: now),
      "generatedAtMs": Int64(snapshot.generatedAt.timeIntervalSince1970 * 1000),
      "validUntilMs": Int64(snapshot.validUntil.timeIntervalSince1970 * 1000),
      "timeZone": snapshot.timeZoneIdentifier,
      "privacyMode": snapshot.privacyMode.rawValue
    ]
  }

  private func number(_ value: Any?) -> Double? {
    if let number = value as? NSNumber { return number.doubleValue }
    if let value = value as? Double { return value }
    if let value = value as? Int64 { return Double(value) }
    if let value = value as? Int { return Double(value) }
    return nil
  }

  private func reloadWidgets() {
    #if canImport(WidgetKit)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
    #endif
  }
}
