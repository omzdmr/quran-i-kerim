import Foundation

struct WidgetPrayerSnapshot: Codable, Equatable {
  static let schemaVersion = 1
  let version: Int
  let generatedAt: Date
  let validUntil: Date
  let timeZoneIdentifier: String
  let calculationFingerprint: String
  let nextPrayerID: String?
  let nextPrayerAt: Date?
  let displayName: String?
  let privacyMode: PrivacyMode

  enum PrivacyMode: String, Codable { case standard, redacted }

  init(generatedAt: Date, validUntil: Date, timeZoneIdentifier: String, calculationFingerprint: String, nextPrayerID: String?, nextPrayerAt: Date?, displayName: String?, privacyMode: PrivacyMode) {
    version = Self.schemaVersion; self.generatedAt = generatedAt; self.validUntil = validUntil; self.timeZoneIdentifier = timeZoneIdentifier; self.calculationFingerprint = calculationFingerprint; self.nextPrayerID = nextPrayerID; self.nextPrayerAt = nextPrayerAt; self.displayName = displayName; self.privacyMode = privacyMode
  }

  func isFresh(at date: Date, currentTimeZone: TimeZone = .current) -> Bool { version == Self.schemaVersion && generatedAt <= date && date < validUntil && timeZoneIdentifier == currentTimeZone.identifier }
  func presentation(at date: Date, currentTimeZone: TimeZone = .current) -> Presentation {
    guard isFresh(at: date, currentTimeZone: currentTimeZone) else { return .stale }
    guard privacyMode == .standard else { return .redacted }
    guard let nextPrayerID, let nextPrayerAt, nextPrayerAt > date else { return .stale }
    return .prayer(id: nextPrayerID, at: nextPrayerAt, displayName: displayName)
  }
  enum Presentation: Equatable { case prayer(id: String, at: Date, displayName: String?); case redacted; case stale }
}

final class WidgetSnapshotStore {
  static let appGroupIdentifier = "group.app.quranikerim.shared"
  static let snapshotKey = "widget.prayer.snapshot.v1"
  enum StoreError: LocalizedError {
    case appGroupUnavailable, invalidSnapshot
    var errorDescription: String? { switch self { case .appGroupUnavailable: return "Shared widget storage is unavailable."; case .invalidSnapshot: return "The widget snapshot is invalid or already expired." } }
  }
  private let defaults: UserDefaults
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init?(suiteName: String = appGroupIdentifier) {
    guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
    self.defaults = defaults; encoder = JSONEncoder(); decoder = JSONDecoder(); encoder.dateEncodingStrategy = .millisecondsSince1970; decoder.dateDecodingStrategy = .millisecondsSince1970
  }
  init(defaults: UserDefaults) { self.defaults = defaults; encoder = JSONEncoder(); decoder = JSONDecoder(); encoder.dateEncodingStrategy = .millisecondsSince1970; decoder.dateDecodingStrategy = .millisecondsSince1970 }

  func save(_ snapshot: WidgetPrayerSnapshot, now: Date = Date()) throws {
    let hasPrayerID = !(snapshot.nextPrayerID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    let hasPrayerTime = snapshot.nextPrayerAt != nil
    let prayerPairIsConsistent = hasPrayerID == hasPrayerTime
    let prayerTimeIsPlausible = snapshot.nextPrayerAt.map { $0 > snapshot.generatedAt } ?? true
    guard snapshot.validUntil > now,
          snapshot.generatedAt <= snapshot.validUntil,
          !snapshot.timeZoneIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          !snapshot.calculationFingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          prayerPairIsConsistent,
          prayerTimeIsPlausible else { throw StoreError.invalidSnapshot }
    defaults.set(try encoder.encode(snapshot), forKey: Self.snapshotKey)
  }

  func load() -> WidgetPrayerSnapshot? { guard let data = defaults.data(forKey: Self.snapshotKey) else { return nil }; return try? decoder.decode(WidgetPrayerSnapshot.self, from: data) }
  func presentation(now: Date = Date(), timeZone: TimeZone = .current) -> WidgetPrayerSnapshot.Presentation { load()?.presentation(at: now, currentTimeZone: timeZone) ?? .stale }
  func clear() { defaults.removeObject(forKey: Self.snapshotKey) }
}
