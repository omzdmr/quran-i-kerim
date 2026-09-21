import Foundation

struct WidgetPrayerSnapshot: Codable, Equatable {
  static let schemaVersion = 1
  let version: Int; let generatedAt: Date; let validUntil: Date; let timeZoneIdentifier: String; let calculationFingerprint: String; let nextPrayerID: String?; let nextPrayerAt: Date?; let displayName: String?; let privacyMode: PrivacyMode
  enum PrivacyMode: String, Codable { case standard, redacted }
  enum Freshness: String, Equatable { case fresh, unsupportedSchema, malformed, generatedInFuture, expired, timeZoneChanged, prayerBoundaryPassed }
  init(generatedAt: Date, validUntil: Date, timeZoneIdentifier: String, calculationFingerprint: String, nextPrayerID: String?, nextPrayerAt: Date?, displayName: String?, privacyMode: PrivacyMode) { version = Self.schemaVersion; self.generatedAt = generatedAt; self.validUntil = validUntil; self.timeZoneIdentifier = timeZoneIdentifier; self.calculationFingerprint = calculationFingerprint; self.nextPrayerID = nextPrayerID; self.nextPrayerAt = nextPrayerAt; self.displayName = displayName; self.privacyMode = privacyMode }
  private var structurallyValid: Bool { let prayerID = nextPrayerID?.trimmingCharacters(in: .whitespacesAndNewlines); let hasPrayerID = !(prayerID?.isEmpty ?? true), hasPrayerTime = nextPrayerAt != nil; let prayerTimeIsPlausible = nextPrayerAt.map { $0 > generatedAt && $0 <= validUntil } ?? true; return generatedAt < validUntil && TimeZone(identifier: timeZoneIdentifier) != nil && !calculationFingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasPrayerID == hasPrayerTime && prayerTimeIsPlausible }
  func freshness(at date: Date, currentTimeZone: TimeZone = .autoupdatingCurrent) -> Freshness { guard version == Self.schemaVersion else { return .unsupportedSchema }; guard structurallyValid else { return .malformed }; guard generatedAt <= date else { return .generatedInFuture }; guard date < validUntil else { return .expired }; guard timeZoneIdentifier == currentTimeZone.identifier else { return .timeZoneChanged }; if let nextPrayerAt, nextPrayerAt <= date { return .prayerBoundaryPassed }; return .fresh }
  func isFresh(at date: Date, currentTimeZone: TimeZone = .autoupdatingCurrent) -> Bool { freshness(at: date, currentTimeZone: currentTimeZone) == .fresh }
  func presentation(at date: Date, currentTimeZone: TimeZone = .autoupdatingCurrent) -> Presentation { guard freshness(at: date, currentTimeZone: currentTimeZone) == .fresh else { return .stale }; guard privacyMode == .standard else { return .redacted }; guard let nextPrayerID, let nextPrayerAt else { return .stale }; return .prayer(id: nextPrayerID, at: nextPrayerAt, displayName: displayName) }
  enum Presentation: Equatable { case prayer(id: String, at: Date, displayName: String?), redacted, stale }
}

final class WidgetSnapshotStore {
  static let appGroupIdentifier = "group.app.quranikerim.shared", snapshotKey = "widget.prayer.snapshot.v1", lastInvalidationKey = "widget.prayer.lastInvalidation.v1"
  enum StoreError: LocalizedError { case appGroupUnavailable, invalidSnapshot; var errorDescription: String? { switch self { case .appGroupUnavailable: return "Shared widget storage is unavailable."; case .invalidSnapshot: return "The widget snapshot is invalid, stale or already expired." } } }
  enum InvalidationReason: String { case explicitClear, policyChanged, corruptPayload, generatedInFuture, expired, timeZoneChanged, prayerBoundaryPassed }
  private let defaults: UserDefaults, encoder: JSONEncoder, decoder: JSONDecoder
  init?(suiteName: String = appGroupIdentifier) { guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }; self.defaults = defaults; encoder = JSONEncoder(); decoder = JSONDecoder(); configureCoders() }
  init(defaults: UserDefaults) { self.defaults = defaults; encoder = JSONEncoder(); decoder = JSONDecoder(); configureCoders() }
  private func configureCoders() { encoder.dateEncodingStrategy = .millisecondsSince1970; decoder.dateDecodingStrategy = .millisecondsSince1970 }

  func save(_ snapshot: WidgetPrayerSnapshot, now: Date = Date()) throws {
    guard let snapshotTimeZone = TimeZone(identifier: snapshot.timeZoneIdentifier), snapshot.version == WidgetPrayerSnapshot.schemaVersion, snapshot.freshness(at: now, currentTimeZone: snapshotTimeZone) == .fresh else { throw StoreError.invalidSnapshot }
    defaults.set(try encoder.encode(snapshot), forKey: Self.snapshotKey); defaults.removeObject(forKey: Self.lastInvalidationKey)
  }
  func load() -> WidgetPrayerSnapshot? { guard let data = defaults.data(forKey: Self.snapshotKey) else { return nil }; return try? decoder.decode(WidgetPrayerSnapshot.self, from: data) }
  func validatedLoad(now: Date = Date(), timeZone: TimeZone = .autoupdatingCurrent) -> WidgetPrayerSnapshot? { guard defaults.object(forKey: Self.snapshotKey) != nil else { return nil }; guard let snapshot = load() else { invalidate(.corruptPayload); return nil }; let freshness = snapshot.freshness(at: now, currentTimeZone: timeZone); if freshness == .malformed || freshness == .unsupportedSchema { invalidate(.corruptPayload); return nil }; return snapshot }
  func freshness(now: Date = Date(), timeZone: TimeZone = .autoupdatingCurrent) -> WidgetPrayerSnapshot.Freshness? { validatedLoad(now: now, timeZone: timeZone)?.freshness(at: now, currentTimeZone: timeZone) }
  func presentation(now: Date = Date(), timeZone: TimeZone = .autoupdatingCurrent) -> WidgetPrayerSnapshot.Presentation { validatedLoad(now: now, timeZone: timeZone)?.presentation(at: now, currentTimeZone: timeZone) ?? .stale }
  @discardableResult func purgeIfStale(now: Date = Date(), timeZone: TimeZone = .autoupdatingCurrent) -> Bool { let hadStoredPayload = defaults.object(forKey: Self.snapshotKey) != nil; guard let snapshot = validatedLoad(now: now, timeZone: timeZone) else { return hadStoredPayload && defaults.object(forKey: Self.snapshotKey) == nil }; let freshness = snapshot.freshness(at: now, currentTimeZone: timeZone); let reason: InvalidationReason; switch freshness { case .fresh: return false; case .generatedInFuture: reason = .generatedInFuture; case .expired: reason = .expired; case .timeZoneChanged: reason = .timeZoneChanged; case .prayerBoundaryPassed: reason = .prayerBoundaryPassed; case .malformed, .unsupportedSchema: reason = .corruptPayload }; invalidate(reason); return true }
  @discardableResult func purgeIfPolicyChanged(currentFingerprint: String) -> Bool { let normalized = currentFingerprint.trimmingCharacters(in: .whitespacesAndNewlines); guard !normalized.isEmpty, let snapshot = validatedLoad(), snapshot.calculationFingerprint != normalized else { return false }; invalidate(.policyChanged); return true }
  func clear() { invalidate(.explicitClear) }
  func lastInvalidationReason() -> String? { defaults.string(forKey: Self.lastInvalidationKey) }
  private func invalidate(_ reason: InvalidationReason) { defaults.removeObject(forKey: Self.snapshotKey); defaults.set(reason.rawValue, forKey: Self.lastInvalidationKey) }
}
