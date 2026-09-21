import SwiftUI
import WidgetKit

private let appGroup = "group.app.quranikerim.shared"
private let snapshotKey = "widget.prayer.snapshot.v1"
private struct PrayerSnapshot: Decodable { let version: Int; let generatedAt: Date; let validUntil: Date; let timeZoneIdentifier: String; let calculationFingerprint: String; let nextPrayerID: String?; let nextPrayerAt: Date?; let displayName: String?; let privacyMode: String; func isFresh(at date: Date, timeZone: TimeZone = .current) -> Bool { version == 1 && generatedAt <= date && date < validUntil && timeZoneIdentifier == timeZone.identifier } }
private struct PrayerEntry: TimelineEntry { let date: Date; let snapshot: PrayerSnapshot?; var canShowDetails: Bool { guard let snapshot else { return false }; return snapshot.isFresh(at: date) && snapshot.privacyMode == "standard" && (snapshot.nextPrayerAt ?? .distantPast) > date } }
private struct PrayerProvider: TimelineProvider {
  private let decoder: JSONDecoder = { let d = JSONDecoder(); d.dateDecodingStrategy = .millisecondsSince1970; return d }()
  func placeholder(in context: Context) -> PrayerEntry { PrayerEntry(date: Date(), snapshot: nil) }
  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) { completion(PrayerEntry(date: Date(), snapshot: load())) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let now = Date(), snapshot = load(); var entries = [PrayerEntry(date: now, snapshot: snapshot)]
    if let snapshot { let boundary = min(snapshot.validUntil, snapshot.nextPrayerAt ?? snapshot.validUntil); if boundary > now { entries.append(PrayerEntry(date: boundary, snapshot: snapshot)) } }
    let refresh: Date
    if let snapshot { let boundary = min(snapshot.validUntil, snapshot.nextPrayerAt ?? snapshot.validUntil); refresh = max(now.addingTimeInterval(60), min(boundary, now.addingTimeInterval(1800))) } else { refresh = now.addingTimeInterval(300) }
    completion(Timeline(entries: entries, policy: .after(refresh)))
  }
  private func load() -> PrayerSnapshot? { guard let d = UserDefaults(suiteName: appGroup)?.data(forKey: snapshotKey), let s = try? decoder.decode(PrayerSnapshot.self, from: d), s.version == 1 else { return nil }; return s }
}

private struct PrayerWidgetView: View {
  let entry: PrayerEntry
  @Environment(\.widgetFamily) private var family
  var body: some View {
    Group {
      if entry.canShowDetails, let snapshot = entry.snapshot, let nextAt = snapshot.nextPrayerAt { prayerContent(snapshot, nextAt) }
      else if entry.snapshot?.privacyMode == "redacted" { stateContent(icon: "lock.fill", title: "Prayer times hidden", accessibility: "Prayer times hidden for privacy") }
      else { stateContent(icon: "arrow.clockwise", title: "Open app to refresh", accessibility: "Prayer information needs to be refreshed in the app") }
    }.containerBackground(.fill.tertiary, for: .widget)
  }
  @ViewBuilder private func prayerContent(_ snapshot: PrayerSnapshot, _ nextAt: Date) -> some View {
    let name = snapshot.displayName ?? snapshot.nextPrayerID ?? String(localized: "Prayer")
    if family == .accessoryRectangular {
      HStack { VStack(alignment: .leading, spacing: 1) { Text(name).font(.headline).lineLimit(1); Text(nextAt, style: .timer).font(.caption.monospacedDigit()) }; Spacer(minLength: 4); Image(systemName: "clock").accessibilityHidden(true) }
        .privacySensitive().accessibilityElement(children: .combine).accessibilityLabel(Text("\(name), \(nextAt.formatted(date: .omitted, time: .shortened))"))
    } else {
      VStack(alignment: .leading, spacing: 4) { Text(name).font(.headline).lineLimit(1).minimumScaleFactor(0.75); Text(nextAt, style: .timer).font(.title3.monospacedDigit()).accessibilityLabel("Time remaining"); Text(nextAt, style: .time).font(.caption).foregroundStyle(.secondary) }
        .privacySensitive().accessibilityElement(children: .combine)
    }
  }
  private func stateContent(icon: String, title: LocalizedStringKey, accessibility: LocalizedStringKey) -> some View { VStack(alignment: .leading, spacing: 5) { Image(systemName: icon).accessibilityHidden(true); Text(title).font(.headline) }.accessibilityElement(children: .ignore).accessibilityLabel(accessibility) }
}

struct PrayerTimesWidget: Widget { let kind = "PrayerTimesWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind: kind, provider: PrayerProvider()) { PrayerWidgetView(entry: $0) }.configurationDisplayName("Prayer Times").description("Shows the next prayer from your on-device schedule.").supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular]) } }
@main struct PrayerWidgetBundle: WidgetBundle { var body: some Widget { PrayerTimesWidget() } }
