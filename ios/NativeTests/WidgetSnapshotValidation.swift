import Foundation

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) { guard condition() else { fputs("WidgetSnapshotValidation failed: \(message)\n", stderr); exit(1) } }
private func expectInvalid(_ snapshot: WidgetPrayerSnapshot, store: WidgetSnapshotStore, now: Date, _ message: String) { do { try store.save(snapshot, now: now); expect(false, message) } catch WidgetSnapshotStore.StoreError.invalidSnapshot { } catch { expect(false, "unexpected error: \(error)") } }

@main struct WidgetSnapshotValidation {
  static func main() throws {
    let suite = "WidgetSnapshotValidation.\(UUID().uuidString)"; guard let defaults = UserDefaults(suiteName: suite) else { exit(2) }; defer { defaults.removePersistentDomain(forName: suite) }
    let store = WidgetSnapshotStore(defaults: defaults), now = Date(timeIntervalSince1970: 1_800_000_000), shanghai = TimeZone(identifier: "Asia/Shanghai")!, istanbul = TimeZone(identifier: "Europe/Istanbul")!
    let nextPrayer = now.addingTimeInterval(600), policy = "method=MWL;asr=standard;offsets=0"
    let snapshot = WidgetPrayerSnapshot(generatedAt: now.addingTimeInterval(-30), validUntil: now.addingTimeInterval(900), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: policy, nextPrayerID: "asr", nextPrayerAt: nextPrayer, displayName: "Asr", privacyMode: .standard)
    try store.save(snapshot, now: now)
    expect(store.load() == snapshot, "snapshot must round-trip"); expect(store.lastInvalidationReason() == nil, "publish clears diagnostics")
    expect(snapshot.freshness(at: now, currentTimeZone: shanghai) == .fresh, "fresh snapshot should report fresh"); expect(snapshot.freshness(at: now, currentTimeZone: istanbul) == .timeZoneChanged, "timezone drift must be explicit"); expect(snapshot.freshness(at: nextPrayer, currentTimeZone: shanghai) == .prayerBoundaryPassed, "prayer boundary must invalidate exactly on time"); expect(snapshot.freshness(at: now.addingTimeInterval(901), currentTimeZone: shanghai) == .expired, "validUntil must be hard")
    let redacted = WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "same-policy", nextPrayerID: "maghrib", nextPrayerAt: now.addingTimeInterval(200), displayName: "Maghrib", privacyMode: .redacted); expect(redacted.presentation(at: now, currentTimeZone: shanghai) == .redacted, "privacy mode suppresses details")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: "Not/A_TimeZone", calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: now.addingTimeInterval(200), displayName: "Fajr", privacyMode: .standard), store: store, now: now, "unknown timezone rejects safely")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: " ", nextPrayerID: nil, nextPrayerAt: nil, displayName: nil, privacyMode: .standard), store: store, now: now, "blank fingerprint rejects")
    expectInvalid(WidgetPrayerSnapshot(generatedAt: now, validUntil: now.addingTimeInterval(300), timeZoneIdentifier: shanghai.identifier, calculationFingerprint: "policy", nextPrayerID: "fajr", nextPrayerAt: nil, displayName: nil, privacyMode: .standard), store: store, now: now, "unpaired prayer rejects")
    try store.save(snapshot, now: now); expect(store.purgeIfStale(now: now, timeZone: istanbul), "timezone drift purges"); expect(store.load() == nil && store.lastInvalidationReason() == "stale", "stale reason persists")
    try store.save(snapshot, now: now); expect(store.purgeIfPolicyChanged(currentFingerprint: "method=Karachi"), "policy change purges"); expect(store.lastInvalidationReason() == "policyChanged", "policy reason persists")

    defaults.set(Data("not-json".utf8), forKey: WidgetSnapshotStore.snapshotKey)
    expect(store.purgeIfStale(now: now, timeZone: shanghai), "corrupt quarantine must report a state change so WidgetKit reloads")
    expect(defaults.object(forKey: WidgetSnapshotStore.snapshotKey) == nil, "corrupt payload removed"); expect(store.lastInvalidationReason() == "corruptPayload", "corrupt reason persists")
    let malformedJSON = "{\"version\":1,\"generatedAt\":1800000000000,\"validUntil\":1800000300000,\"timeZoneIdentifier\":\"Asia/Shanghai\",\"calculationFingerprint\":\"\",\"privacyMode\":\"standard\"}"
    defaults.set(Data(malformedJSON.utf8), forKey: WidgetSnapshotStore.snapshotKey)
    expect(store.purgeIfStale(now: now, timeZone: shanghai), "structurally malformed quarantine must request WidgetKit refresh"); expect(store.lastInvalidationReason() == "corruptPayload", "malformed reason persists")
    try store.save(snapshot, now: now); expect(store.lastInvalidationReason() == nil, "healthy republish clears quarantine diagnostics"); store.clear(); expect(store.lastInvalidationReason() == "explicitClear", "explicit clear distinguished")
    print("WidgetSnapshotValidation passed")
  }
}
