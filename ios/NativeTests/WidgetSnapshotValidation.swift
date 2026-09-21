import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) { guard condition() else { fputs("WidgetSnapshotValidation failed: \(message)\n", stderr); exit(1) } }
private func expectInvalid(_ snapshot: WidgetPrayerSnapshot, store: WidgetSnapshotStore, now: Date, _ message: String) { do { try store.save(snapshot, now: now); expect(false, message) } catch WidgetSnapshotStore.StoreError.invalidSnapshot { } catch { expect(false, "unexpected error: \(error)") } }

@main struct WidgetSnapshotValidation {
  static func main() throws {
    let suite = "WidgetSnapshotValidation.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else { exit(2) }
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = WidgetSnapshotStore(defaults: defaults), now = Date(timeIntervalSince1970: 1_800_000_000)
    let shanghai = TimeZone(identifier: "Asia/Shanghai")!, istanbul = TimeZone(identifier: "Europe/Istanbul")!
    let nextPrayer = now.addingTimeInterval(600), policy = "method=MWL;asr=standard;offsets=0"
    let snapshot = WidgetPrayerSnapshot(generatedAt: now.addingTimeInterval(-30), validUntil: now.addingTimeInterval(900), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: policy, nextPrayerID: "asr", nextPrayerAt: nextPrayer, displayName: "Asr", privacyMode: .standard)

    try store.save(snapshot, now: now)
    expect(store.load() == snapshot, "snapshot must round-trip through shared defaults")
    expect(store.lastInvalidationReason() == nil, "successful publish must clear prior invalidation diagnostics")
    expect(snapshot.freshness(at: now, currentTimeZone: shanghai) == .fresh, "fresh snapshot should report fresh")
    expect(snapshot.freshness(at: now, currentTimeZone: istanbul) == .timeZoneChanged, "timezone drift must be explicit")
    expect(snapshot.freshness(at: nextPrayer, currentTimeZone: shanghai) == .prayerBoundaryPassed, "prayer boundary must invalidate exactly on time")
    expect(snapshot.freshness(at: now.addingTimeInterval(901), currentTimeZone: shanghai) == .expired, "validUntil must be hard")

    let redacted = WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "same-policy", nextPrayerID: "maghrib", nextPrayerAt: now.addingTimeInterval(200), displayName: "Maghrib", privacyMode: .redacted)
    expect(redacted.presentation(at: now, currentTimeZone: shanghai) == .redacted, "privacy mode must suppress lock-screen details")

    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: "Not/A_TimeZone", calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: now.addingTimeInterval(200), displayName: "Fajr", privacyMode: .standard), store: store, now: now, "unknown timezone must reject without crashing")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: " ", nextPrayerID: nil, nextPrayerAt: nil, displayName: nil, privacyMode: .standard), store: store, now: now, "blank fingerprint must reject")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: nil, displayName: nil, privacyMode: .standard), store: store, now: now, "unpaired prayer id must reject")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now.addingTimeInterval(61), validUntil: now.addingTimeInterval(400), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: now.addingTimeInterval(300), displayName: nil, privacyMode: .standard), store: store, now: now, "future generation must reject")

    try store.save(snapshot, now: now)
    expect(store.purgeIfStale(now: now, timeZone: istanbul), "timezone drift must purge")
    expect(store.load() == nil && store.lastInvalidationReason() == "stale", "stale purge must retain diagnostic reason")
    try store.save(snapshot, now: now)
    expect(store.purgeIfPolicyChanged(currentFingerprint: "method=Karachi"), "policy change must purge")
    expect(store.lastInvalidationReason() == "policyChanged", "policy purge must be diagnosable")

    // Simulate damaged App Group bytes from an interrupted/legacy write. The first validated read
    // must quarantine them rather than feeding an endless decode failure to app + extension.
    defaults.set(Data("not-json".utf8), forKey: WidgetSnapshotStore.snapshotKey)
    expect(store.validatedLoad(now: now, timeZone: shanghai) == nil, "corrupt payload must not escape validated load")
    expect(defaults.object(forKey: WidgetSnapshotStore.snapshotKey) == nil, "corrupt payload must be removed")
    expect(store.lastInvalidationReason() == "corruptPayload", "corruption quarantine must leave diagnostics")

    // A structurally impossible but decodable payload is equally unsafe.
    let malformedJSON = "{\"version\":1,\"generatedAt\":1800000000000,\"validUntil\":1800000300000,\"timeZoneIdentifier\":\"Asia/Shanghai\",\"calculationFingerprint\":\"\",\"privacyMode\":\"standard\"}"
    defaults.set(Data(malformedJSON.utf8), forKey: WidgetSnapshotStore.snapshotKey)
    expect(store.validatedLoad(now: now, timeZone: shanghai) == nil, "structurally malformed payload must be quarantined")
    expect(store.lastInvalidationReason() == "corruptPayload", "malformed quarantine must be diagnosable")

    try store.save(snapshot, now: now)
    expect(store.lastInvalidationReason() == nil, "a healthy republish must clear old quarantine diagnostics")
    store.clear()
    expect(store.lastInvalidationReason() == "explicitClear", "explicit clear must be distinguishable from failure")
    print("WidgetSnapshotValidation passed")
  }
}
