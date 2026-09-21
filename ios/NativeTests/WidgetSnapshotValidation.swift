import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
  guard condition() else { fputs("WidgetSnapshotValidation failed: \(message)\n", stderr); exit(1) }
}

private func expectInvalid(_ snapshot: WidgetPrayerSnapshot, store: WidgetSnapshotStore, now: Date, _ message: String) {
  do { try store.save(snapshot, now: now); expect(false, message) }
  catch WidgetSnapshotStore.StoreError.invalidSnapshot { }
  catch { expect(false, "unexpected error: \(error)") }
}

@main
struct WidgetSnapshotValidation {
  static func main() throws {
    let suite = "WidgetSnapshotValidation.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else { exit(2) }
    defer { defaults.removePersistentDomain(forName: suite) }

    let store = WidgetSnapshotStore(defaults: defaults)
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let shanghai = TimeZone(identifier: "Asia/Shanghai")!
    let istanbul = TimeZone(identifier: "Europe/Istanbul")!
    let nextPrayer = now.addingTimeInterval(600)
    let policy = "method=MWL;asr=standard;offsets=0"
    let snapshot = WidgetPrayerSnapshot(generatedAt: now.addingTimeInterval(-30), validUntil: now.addingTimeInterval(900), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: policy, nextPrayerID: "asr", nextPrayerAt: nextPrayer, displayName: "Asr", privacyMode: .standard)

    try store.save(snapshot, now: now)
    expect(store.load() == snapshot, "snapshot must round-trip through shared defaults")
    expect(snapshot.freshness(at: now, currentTimeZone: shanghai) == .fresh, "fresh snapshot should report a useful freshness state")
    expect(snapshot.freshness(at: now, currentTimeZone: istanbul) == .timeZoneChanged, "timezone changes must be distinguishable from generic staleness")
    expect(snapshot.freshness(at: nextPrayer, currentTimeZone: shanghai) == .prayerBoundaryPassed, "prayer boundary must invalidate the previous countdown exactly on time")
    expect(snapshot.freshness(at: now.addingTimeInterval(901), currentTimeZone: shanghai) == .expired, "validUntil must be a hard display boundary")
    expect(snapshot.presentation(at: nextPrayer, currentTimeZone: shanghai) == .stale, "details must become stale exactly when the next prayer begins")

    let redacted = WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "same-policy", nextPrayerID: "maghrib", nextPrayerAt: now.addingTimeInterval(200), displayName: "Maghrib", privacyMode: .redacted)
    expect(redacted.presentation(at: now, currentTimeZone: shanghai) == .redacted, "privacy mode must suppress lock-screen prayer details")

    expectInvalid(WidgetPrayerSnapshot(generatedAt: now.addingTimeInterval(-100), validUntil: now.addingTimeInterval(-1), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: nil, nextPrayerAt: nil, displayName: nil, privacyMode: .standard), store: store, now: now, "expired snapshots must be rejected")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: nil, displayName: "Fajr", privacyMode: .standard), store: store, now: now, "prayer id without a prayer time must be rejected")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: now.addingTimeInterval(-1), displayName: "Fajr", privacyMode: .standard), store: store, now: now, "prayer time before generation must be rejected")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: "Not/A_TimeZone", calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: now.addingTimeInterval(200), displayName: "Fajr", privacyMode: .standard), store: store, now: now, "unknown timezone identifiers must be rejected")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: now.addingTimeInterval(301), displayName: "Fajr", privacyMode: .standard), store: store, now: now, "next prayer cannot outlive the snapshot validity window")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now.addingTimeInterval(61), validUntil: now.addingTimeInterval(400), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: now.addingTimeInterval(300), displayName: "Fajr", privacyMode: .standard), store: store, now: now, "snapshots generated materially in the future must be rejected")

    try store.save(snapshot, now: now)
    expect(!store.purgeIfStale(now: now, timeZone: shanghai), "fresh state must not be purged")
    expect(store.purgeIfStale(now: now, timeZone: istanbul), "timezone drift must purge stale prayer projection")
    expect(store.load() == nil, "timezone purge must remove projection")

    try store.save(snapshot, now: now)
    expect(store.purgeIfStale(now: nextPrayer, timeZone: shanghai), "crossing prayer boundary must make projection purgeable")
    expect(store.load() == nil, "prayer-boundary purge must clear projection")

    try store.save(snapshot, now: now)
    expect(!store.purgeIfPolicyChanged(currentFingerprint: policy), "same calculation policy must preserve a valid projection")
    expect(store.load() != nil, "same policy must keep snapshot")
    expect(store.purgeIfPolicyChanged(currentFingerprint: "method=Karachi;asr=hanafi;offsets=0"), "calculation policy changes must invalidate projected prayer data")
    expect(store.load() == nil, "policy invalidation must remove the old projection")

    print("WidgetSnapshotValidation passed")
  }
}
