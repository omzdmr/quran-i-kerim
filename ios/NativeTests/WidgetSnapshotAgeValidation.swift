import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
  guard condition() else { fputs("WidgetSnapshotAgeValidation failed: \(message)\n", stderr); exit(1) }
}

@main struct WidgetSnapshotAgeValidation {
  static func main() throws {
    let suite = "WidgetSnapshotAgeValidation.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else { exit(2) }
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = WidgetSnapshotStore(defaults: defaults)
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let zone = TimeZone(identifier: "Asia/Shanghai")!
    let locale = Locale(identifier: "en_US")

    func snapshot(age: TimeInterval, validity: TimeInterval = 48 * 60 * 60) -> WidgetPrayerSnapshot {
      let generated = now.addingTimeInterval(-age)
      return WidgetPrayerSnapshot(
        generatedAt: generated,
        validUntil: generated.addingTimeInterval(validity),
        timeZoneIdentifier: zone.identifier,
        localeIdentifier: locale.identifier,
        calculationFingerprint: "method=MWL;asr=standard;offsets=0",
        nextPrayerID: "fajr",
        nextPrayerAt: now.addingTimeInterval(60 * 60),
        displayName: "Fajr",
        privacyMode: .standard
      )
    }

    let withinLimit = snapshot(age: WidgetPrayerSnapshot.maximumAge - 1)
    require(withinLimit.freshness(at: now, currentTimeZone: zone, currentLocale: locale) == .fresh, "snapshot just inside age ceiling must stay fresh")

    let tooOld = snapshot(age: WidgetPrayerSnapshot.maximumAge + 1)
    require(tooOld.freshness(at: now, currentTimeZone: zone, currentLocale: locale) == .generatedTooOld, "aged snapshot must fail closed")
    do {
      try store.save(tooOld, now: now)
      require(false, "producer must reject already-aged snapshot")
    } catch WidgetSnapshotStore.StoreError.invalidSnapshot { }

    let initiallyFresh = WidgetPrayerSnapshot(
      generatedAt: now,
      validUntil: now.addingTimeInterval(48 * 60 * 60),
      timeZoneIdentifier: zone.identifier,
      localeIdentifier: locale.identifier,
      calculationFingerprint: "method=MWL;asr=standard;offsets=0",
      nextPrayerID: "isha",
      nextPrayerAt: now.addingTimeInterval(40 * 60 * 60),
      displayName: "Isha",
      privacyMode: .standard
    )
    try store.save(initiallyFresh, now: now)
    let agedNow = now.addingTimeInterval(WidgetPrayerSnapshot.maximumAge + 1)
    require(store.purgeIfStale(now: agedNow, timeZone: zone, locale: locale), "aged stored snapshot must purge")
    require(store.lastInvalidationReason() == "generatedTooOld", "age purge must preserve diagnostic reason")
    require(store.load() == nil, "aged payload must not survive purge")

    print("WidgetSnapshotAgeValidation passed")
  }
}
