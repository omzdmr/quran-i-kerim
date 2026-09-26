import ActivityKit
import Flutter
import Foundation
import UIKit

final class PrayerLiveActivityChannel {
  static let channelName = "app.quranikerim/native_prayer_live_activity"
  private let channel: FlutterMethodChannel
  private var foregroundObserver: NSObjectProtocol?

  init(binaryMessenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
    foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
      guard let self else { return }
      self.purgeExpiredActivities()
      if #available(iOS 16.1, *) { self.channel.invokeMethod("authorizationChanged", arguments: ["activitiesEnabled": ActivityAuthorizationInfo().areActivitiesEnabled]) }
    }
    purgeExpiredActivities()
  }

  func detach() {
    if let foregroundObserver { NotificationCenter.default.removeObserver(foregroundObserver); self.foregroundObserver = nil }
    channel.setMethodCallHandler(nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      if call.method == "capabilities" { result(["supported": false, "finalProvider": false]); return }
      result(FlutterError(code: "live_activity_unsupported", message: "Live Activities require iOS 16.1 or later.", details: nil))
      return
    }
    switch call.method {
    case "capabilities":
      result(["supported": true, "activitiesEnabled": ActivityAuthorizationInfo().areActivitiesEnabled, "lockScreen": true, "dynamicIslandConfiguration": true, "privacyRedaction": true, "expiredAutoCleanup": true, "finalProvider": false])
    case "status":
      let activities = Activity<PrayerActivityAttributes>.activities
      result([
        "activitiesEnabled": ActivityAuthorizationInfo().areActivitiesEnabled,
        "activeCount": activities.count,
        "activeIDs": activities.map(\.id),
        "activities": activities.map { activityStatus($0) },
      ])
    case "start":
      start(call.arguments, result: result)
    case "update":
      update(call.arguments, result: result)
    case "end":
      end(call.arguments, result: result)
    case "endAll":
      endAll(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func purgeExpiredActivities() {
    guard #available(iOS 16.1, *) else { return }
    let now = Date().timeIntervalSince1970 * 1000
    let expired = Activity<PrayerActivityAttributes>.activities.filter { $0.contentState.prayerAtMilliseconds <= now }
    guard !expired.isEmpty else { return }
    Task { for activity in expired { await activity.end(using: activity.contentState, dismissalPolicy: .immediate) } }
  }

  @available(iOS 16.1, *)
  private func start(_ arguments: Any?, result: @escaping FlutterResult) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      result(FlutterError(code: "live_activity_disabled", message: "Live Activities are disabled for this app.", details: nil)); return
    }
    let now = Date().timeIntervalSince1970 * 1000
    do {
      let state = try parseState(arguments)
      let activities = Activity<PrayerActivityAttributes>.activities
      if let matching = activities.first(where: { activityMatches($0, state: state) }) {
        result(["id": matching.id, "started": false, "alreadyActive": true, "stateMatched": true])
        return
      }
      let conflicting = activities.filter { $0.contentState.prayerAtMilliseconds > now }
      if !conflicting.isEmpty {
        Task {
          for activity in conflicting {
            await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
          }
          do {
            let activity = try self.requestActivity(state: state)
            await MainActor.run { result(["id": activity.id, "started": true, "replacedCount": conflicting.count]) }
          } catch {
            await MainActor.run { result(FlutterError(code: "live_activity_start_failed", message: error.localizedDescription, details: nil)) }
          }
        }
        return
      }
      let activity = try requestActivity(state: state)
      result(["id": activity.id, "started": true, "replacedCount": 0])
    } catch let error as LiveActivityInputError {
      result(FlutterError(code: "invalid_live_activity", message: error.localizedDescription, details: nil))
    } catch {
      result(FlutterError(code: "live_activity_start_failed", message: error.localizedDescription, details: nil))
    }
  }

  @available(iOS 16.1, *)
  private func requestActivity(state: PrayerActivityAttributes.ContentState) throws -> Activity<PrayerActivityAttributes> {
    let attributes = PrayerActivityAttributes(createdAtMilliseconds: Date().timeIntervalSince1970 * 1000)
    if #available(iOS 16.2, *) {
      let content = ActivityContent(state: state, staleDate: Date(timeIntervalSince1970: state.prayerAtMilliseconds / 1000))
      return try Activity<PrayerActivityAttributes>.request(attributes: attributes, content: content, pushType: nil)
    }
    return try Activity<PrayerActivityAttributes>.request(attributes: attributes, contentState: state, pushType: nil)
  }

  @available(iOS 16.1, *)
  private func activityMatches(_ activity: Activity<PrayerActivityAttributes>, state: PrayerActivityAttributes.ContentState) -> Bool {
    let current = activity.contentState
    return current.prayerID == state.prayerID &&
      current.prayerAtMilliseconds == state.prayerAtMilliseconds &&
      current.timeZoneIdentifier == state.timeZoneIdentifier &&
      current.localeIdentifier == state.localeIdentifier &&
      current.calculationFingerprint == state.calculationFingerprint &&
      current.isRedacted == state.isRedacted
  }

  @available(iOS 16.1, *)
  private func activityStatus(_ activity: Activity<PrayerActivityAttributes>) -> [String: Any] {
    let state = activity.contentState
    return ["id": activity.id, "prayerID": state.prayerID, "prayerAtMilliseconds": state.prayerAtMilliseconds, "timeZoneIdentifier": state.timeZoneIdentifier, "localeIdentifier": state.localeIdentifier, "calculationFingerprint": state.calculationFingerprint, "isRedacted": state.isRedacted]
  }

  @available(iOS 16.1, *)
  private func update(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let id = args["id"] as? String, !id.isEmpty else {
      result(FlutterError(code: "invalid_live_activity", message: "update requires an activity id.", details: nil)); return
    }
    do {
      let state = try parseState(arguments)
      guard let activity = Activity<PrayerActivityAttributes>.activities.first(where: { $0.id == id }) else {
        result(FlutterError(code: "live_activity_not_found", message: "The requested Live Activity is not active.", details: nil)); return
      }
      Task {
        if #available(iOS 16.2, *) {
          let content = ActivityContent(state: state, staleDate: Date(timeIntervalSince1970: state.prayerAtMilliseconds / 1000))
          await activity.update(content)
        } else {
          await activity.update(using: state)
        }
        await MainActor.run { result(["updated": true, "id": id]) }
      }
    } catch {
      result(FlutterError(code: "invalid_live_activity", message: error.localizedDescription, details: nil))
    }
  }

  @available(iOS 16.1, *)
  private func end(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let id = args["id"] as? String, !id.isEmpty else {
      result(FlutterError(code: "invalid_live_activity", message: "end requires an activity id.", details: nil)); return
    }
    guard let activity = Activity<PrayerActivityAttributes>.activities.first(where: { $0.id == id }) else {
      result(["ended": false, "id": id]); return
    }
    Task { await activity.end(using: activity.contentState, dismissalPolicy: .immediate); await MainActor.run { result(["ended": true, "id": id]) } }
  }

  @available(iOS 16.1, *)
  private func endAll(result: @escaping FlutterResult) {
    let activities = Activity<PrayerActivityAttributes>.activities
    Task {
      for activity in activities { await activity.end(using: activity.contentState, dismissalPolicy: .immediate) }
      await MainActor.run { result(["endedCount": activities.count]) }
    }
  }

  @available(iOS 16.1, *)
  private func parseState(_ arguments: Any?) throws -> PrayerActivityAttributes.ContentState {
    guard let args = arguments as? [String: Any],
          let prayerID = nonBlank(args["prayerID"] as? String),
          let displayName = nonBlank(args["displayName"] as? String),
          let prayerAt = (args["prayerAtMilliseconds"] as? NSNumber)?.doubleValue,
          let timeZone = nonBlank(args["timeZoneIdentifier"] as? String),
          TimeZone(identifier: timeZone) != nil,
          let locale = nonBlank(args["localeIdentifier"] as? String),
          let fingerprint = nonBlank(args["calculationFingerprint"] as? String),
          let redacted = args["isRedacted"] as? Bool,
          prayerAt > Date().timeIntervalSince1970 * 1000 else { throw LiveActivityInputError.invalidState }
    return PrayerActivityAttributes.ContentState(prayerID: prayerID, displayName: displayName, prayerAtMilliseconds: prayerAt, timeZoneIdentifier: timeZone, localeIdentifier: locale, calculationFingerprint: fingerprint, isRedacted: redacted)
  }

  private func nonBlank(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private enum LiveActivityInputError: LocalizedError {
    case invalidState
    var errorDescription: String? { "Live Activity state is incomplete, invalid, or already expired." }
  }
}
