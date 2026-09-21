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
  enum Freshness: String, Equatable {
    case fresh
    case unsupportedSchema
    case generatedInFuture
    case expired
    case timeZoneChanged
    case prayerBoundaryPassed
  }

  init(generatedAt: Date, validUntil: Date, timeZoneIdentifier: String, calculationFingerprint: String, nextPrayerID: String?, nextPrayerAt: Date?, displayName: String?, privacyMode: PrivacyMode) {
    version = Self.schemaVersion
    self.generatedAt = generatedAt
    self.validUntil = validUntil
    self.timeZoneIdentifier = timeZoneIdentifier
    self.calculationFingerprint = calculationFingerprint
    self.nextPrayerID = nextPrayerID
    self.nextPrayerAt = nextPrayerAt
    self.displayName = displayName
    self.privacyMode = privacyMode
  }

  func freshness(at date: Date, currentTimeZone: TimeZone = .current) -> Freshness {
    guard version == Self.schemaVersion else { return .unsupportedSchema }
    guard generatedAt <= date else { return .generatedInFuture }
    guard date < validUntil else { return .expired }
    guard timeZoneIdentifier == currentTimeZone.identifier else { return .timeZoneChanged }
    if let nextPrayerAt, nextPrayerAt <= date { return .prayerBoundaryPassed }
    return .fresh
  }

  func isFresh(at date: Date, currentTimeZone: TimeZone = .current) -> Bool {
    freshness(at: date, currentTimeZone: currentTimeZone) == .fresh
  }

  func presentation(at date: Date, currentTimeZone: TimeZone = .current) -> Presentation {
    guard freshness(at: date, currentTimeZone: currentTimeZone) == .fresh else { return .stale }
    guard privacyMode == .standard else { return .redacted }
    guard let nextPrayerID, let nextPrayerAt else { return .stale }
    return .prayer(id: nextPrayerID, at: nextPrayerAt, displayName: displayName)
  }

  enum Presentation: Equatable {
    case prayer(id: String, at: Date, displayName: String?)
    case redacted
    case stale
  }
}

final class WidgetSnapshotStore {
  static let appGroupIdentifier = "group.app.quranikerim.shared"
  static let snapshotKey = "widget.prayer.snapshot.v1"

  enum StoreError: LocalizedError {
    case appGroupUnavailable
    case invalidSnapshot

    var errorDescription: String? {
      switch self {
      case .appGroupUnavailable: return "Shared widget storage is unavailable."
      case .invalidSnapshot: return "The widget snapshot is invalid or already expired."
      }
    }
  }

  private let defaults: UserDefaults
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init?(suiteName: String = appGroupIdentifier) {
    guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
    self.defaults = defaults
    encoder = JSONEncoder()
    decoder = JSONDecoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    decoder.dateDecodingStrategy = .millisecondsSince1970
  }

  init(defaults: UserDefaults) {
    self.defaults = defaults
    encoder = JSONEncoder()
    decoder = JSONDecoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    decoder.dateDecodingStrategy = .millisecondsSince1970
  }

  func save(_ snapshot: WidgetPrayerSnapshot, now: Date = Date()) throws {
    let prayerID = snapshot.nextPrayerID?.trimmingCharacters(in: .whitespacesAndNewlines)
    let hasPrayerID = !(prayerID?.isEmpty ?? true)
    let hasPrayerTime = snapshot.nextPrayerAt != nil
    let prayerPairIsConsistent = hasPrayerID == hasPrayerTime
    let prayerTimeIsPlausible = snapshot.nextPrayerAt.map {
      $0 > snapshot.generatedAt && $0 <= snapshot.validUntil
    } ?? true

    guard snapshot.version == WidgetPrayerSnapshot.schemaVersion,
          snapshot.validUntil > now,
          snapshot.generatedAt <= now.addingTimeInterval(60),
          snapshot.generatedAt < snapshot.validUntil,
          TimeZone(identifier: snapshot.timeZoneIdentifier) != nil,
          !snapshot.calculationFingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          prayerPairIsConsistent,
          prayerTimeIsPlausible else {
      throw StoreError.invalidSnapshot
    }

    defaults.set(try encoder.encode(snapshot), forKey: Self.snapshotKey)
  }

  func load() -> WidgetPrayerSnapshot? {
    guard let data = defaults.data(forKey: Self.snapshotKey) else { return nil }
    return try? decoder.decode(WidgetPrayerSnapshot.self, from: data)
  }

  func freshness(now: Date = Date(), timeZone: TimeZone = .current) -> WidgetPrayerSnapshot.Freshness? {
    load()?.freshness(at: now, currentTimeZone: timeZone)
  }

  func presentation(now: Date = Date(), timeZone: TimeZone = .current) -> WidgetPrayerSnapshot.Presentation {
    load()?.presentation(at: now, currentTimeZone: timeZone) ?? .stale
  }

  @discardableResult
  func purgeIfStale(now: Date = Date(), timeZone: TimeZone = .current) -> Bool {
    guard let snapshot = load(), !snapshot.isFresh(at: now, currentTimeZone: timeZone) else { return false }
    clear()
    return true
  }

  func clear() {
    defaults.removeObject(forKey: Self.snapshotKey)
  }
}
