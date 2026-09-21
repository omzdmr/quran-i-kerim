import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) { guard condition() else { fputs("WidgetSnapshotValidation failed: \(message)\n", stderr); exit(1) } }
private func expectInvalid(_ snapshot: WidgetPrayerSnapshot, store: WidgetSnapshotStore, now: Date, _ message: String) {
  do { try store.save(snapshot, now: now); expect(false, message) } catch WidgetSnapshotStore.StoreError.invalidSnapshot { } catch { expect(false, "unexpected error: \(error)") }
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
    let nextPrayer = now.addingTimeInterval(600)
    let snapshot = WidgetPrayerSnapshot(generatedAt: now.addingTimeInterval(-30), validUntil: now.addingTimeInterval(900), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "method=MWL;asr=standard;offsets=0", nextPrayerID: "asr", nextPrayerAt: nextPrayer, displayName: "Asr", privacyMode: .standard)
    try store.save(snapshot, now: now)
    expect(store.load() == snapshot, "snapshot must round-trip through shared defaults")
    expect(snapshot.isFresh(at: now, currentTimeZone: shanghai), "fresh snapshot should be accepted")
    expect(!snapshot.isFresh(at: now, currentTimeZone: TimeZone(identifier: "Europe/Istanbul")!), "timezone changes must invalidate cached prayer state")
    expect(snapshot.presentation(at: nextPrayer, currentTimeZone: shanghai) == .stale, "details must become stale exactly when the next prayer begins")
    expect(snapshot.presentation(at: now.addingTimeInterval(901), currentTimeZone: shanghai) == .stale, "expired snapshots must never present a prayer countdown")

    let redacted = WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "same-policy", nextPrayerID: "maghrib", nextPrayerAt: now.addingTimeInterval(200), displayName: "Maghrib", privacyMode: .redacted)
    expect(redacted.presentation(at: now, currentTimeZone: shanghai) == .redacted, "privacy mode must suppress lock-screen prayer details")

    expectInvalid(WidgetPrayerSnapshot(generatedAt: now.addingTimeInterval(-100), validUntil: now.addingTimeInterval(-1), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: nil, nextPrayerAt: nil, displayName: nil, privacyMode: .standard), store: store, now: now, "expired snapshots must be rejected")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: nil, displayName: "Fajr", privacyMode: .standard), store: store, now: now, "prayer id without a prayer time must be rejected")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: now.addingTimeInterval(-1), displayName: "Fajr", privacyMode: .standard), store: store, now: now, "prayer time before generation must be rejected")

    store.clear(); expect(store.load() == nil, "clear must remove widget projection")
    print("WidgetSnapshotValidation passed")
  }
}
