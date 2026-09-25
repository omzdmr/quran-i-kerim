import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct PrayerActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    let prayerID: String
    let displayName: String
    let prayerAtMilliseconds: Double
    let timeZoneIdentifier: String
    let localeIdentifier: String
    let calculationFingerprint: String
    let isRedacted: Bool
  }

  let createdAtMilliseconds: Double
}
