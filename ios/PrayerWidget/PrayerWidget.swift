import SwiftUI
import WidgetKit

private let appGroup = "group.app.quranikerim.shared"
private let snapshotKey = "widget.prayer.snapshot.v1"

private struct PrayerSnapshot: Decodable {
  let version: Int; let generatedAt: Date; let validUntil: Date; let timeZoneIdentifier: String; let calculationFingerprint: String; let nextPrayerID: String?; let nextPrayerAt: Date?; let displayName: String?; let privacyMode: String
  enum Freshness { case fresh, unsupportedSchema, generatedInFuture, expired, timeZoneChanged, prayerBoundaryPassed, malformed }
  func freshness(at date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> Freshness {
    guard version == 1 else { return .unsupportedSchema }
    guard TimeZone(identifier: timeZoneIdentifier) != nil, !calculationFingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, privacyMode == "standard" || privacyMode == "redacted", generatedAt < validUntil else { return .malformed }
    let prayerID = nextPrayerID?.trimmingCharacters(in: .whitespacesAndNewlines), hasPrayerID = !(prayerID?.isEmpty ?? true), hasPrayerTime = nextPrayerAt != nil
    guard hasPrayerID == hasPrayerTime else { return .malformed }
    if let nextPrayerAt { guard nextPrayerAt > generatedAt, nextPrayerAt <= validUntil else { return .malformed } }
    guard generatedAt <= date else { return .generatedInFuture }; guard date < validUntil else { return .expired }; guard timeZoneIdentifier == timeZone.identifier else { return .timeZoneChanged }
    if let nextPrayerAt, nextPrayerAt <= date { return .prayerBoundaryPassed }; return .fresh
  }
}

private struct PrayerEntry: TimelineEntry {
  let date: Date; let snapshot: PrayerSnapshot?
  var canShowDetails: Bool { guard let snapshot, case .fresh = snapshot.freshness(at: date) else { return false }; return snapshot.privacyMode == "standard" && snapshot.nextPrayerAt != nil }
}

private struct PrayerProvider: TimelineProvider {
  private let decoder: JSONDecoder = { let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .millisecondsSince1970; return decoder }()
  func placeholder(in context: Context) -> PrayerEntry { PrayerEntry(date: Date(), snapshot: nil) }
  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) { completion(PrayerEntry(date: Date(), snapshot: load())) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) { let now = Date(), snapshot = load(); var entries = [PrayerEntry(date: now, snapshot: snapshot)]; if let boundary = nextBoundary(snapshot: snapshot, after: now) { entries.append(PrayerEntry(date: boundary, snapshot: snapshot)) }; completion(Timeline(entries: entries, policy: .after(nextRefresh(snapshot: snapshot, now: now)))) }
  private func nextBoundary(snapshot: PrayerSnapshot?, after now: Date) -> Date? { guard let snapshot else { return nil }; let boundary = min(snapshot.validUntil, snapshot.nextPrayerAt ?? snapshot.validUntil); return boundary > now ? boundary : nil }
  private func nextRefresh(snapshot: PrayerSnapshot?, now: Date) -> Date { guard let boundary = nextBoundary(snapshot: snapshot, after: now) else { return now.addingTimeInterval(snapshot == nil ? 300 : 60) }; return max(now.addingTimeInterval(60), min(boundary, now.addingTimeInterval(1800))) }
  private func load() -> PrayerSnapshot? { guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: snapshotKey), let snapshot = try? decoder.decode(PrayerSnapshot.self, from: data), snapshot.version == 1 else { return nil }; return snapshot }
}

private struct PrayerWidgetView: View {
  let entry: PrayerEntry
  @Environment(\.widgetFamily) private var family
  var body: some View { Group { if entry.canShowDetails, let snapshot = entry.snapshot, let nextAt = snapshot.nextPrayerAt { prayerContent(snapshot, nextAt) } else { unavailableContent } }.containerBackground(.fill.tertiary, for: .widget).widgetURL(URL(string: "quranikerim://prayer")) }

  @ViewBuilder private func prayerContent(_ snapshot: PrayerSnapshot, _ nextAt: Date) -> some View {
    let name = snapshot.displayName ?? snapshot.nextPrayerID ?? String(localized: "Prayer")
    switch family {
    case .accessoryInline:
      Label { Text("\(name) \(nextAt, style: .timer)").lineLimit(1) } icon: { Image(systemName: "clock") }.privacySensitive().accessibilityElement(children: .ignore).accessibilityLabel(Text("\(name), \(nextAt.formatted(date: .omitted, time: .shortened))"))
    case .accessoryCircular:
      VStack(spacing: 1) { Image(systemName: "clock").font(.caption2).accessibilityHidden(true); Text(nextAt, style: .timer).font(.caption2.monospacedDigit()).minimumScaleFactor(0.65) }.privacySensitive().accessibilityElement(children: .ignore).accessibilityLabel(Text("\(name), \(nextAt.formatted(date: .omitted, time: .shortened))"))
    case .accessoryRectangular:
      HStack { VStack(alignment: .leading, spacing: 1) { Text(name).font(.headline).lineLimit(1); Text(nextAt, style: .timer).font(.caption.monospacedDigit()) }; Spacer(minLength: 4); Image(systemName: "clock").accessibilityHidden(true) }.privacySensitive().accessibilityElement(children: .combine).accessibilityLabel(Text("\(name), \(nextAt.formatted(date: .omitted, time: .shortened))"))
    case .systemMedium:
      HStack(spacing: 14) { VStack(alignment: .leading, spacing: 4) { Label(name, systemImage: "moon.stars.fill").font(.headline).lineLimit(1); Text(nextAt, style: .time).font(.title3.weight(.semibold)).monospacedDigit() }; Spacer(minLength: 8); VStack(alignment: .trailing, spacing: 2) { Text("Time remaining").font(.caption).foregroundStyle(.secondary); Text(nextAt, style: .timer).font(.title2.monospacedDigit()).minimumScaleFactor(0.7).lineLimit(1) } }.privacySensitive().accessibilityElement(children: .ignore).accessibilityLabel(Text("\(name), \(nextAt.formatted(date: .omitted, time: .shortened))"))
    case .systemLarge:
      VStack(alignment: .leading, spacing: 16) {
        HStack { Label(name, systemImage: "moon.stars.fill").font(.title2.weight(.semibold)).lineLimit(1); Spacer(); Image(systemName: "clock").font(.title3).accessibilityHidden(true) }
        Spacer(minLength: 0)
        Text(nextAt, style: .time).font(.system(.largeTitle, design: .rounded, weight: .semibold)).monospacedDigit().minimumScaleFactor(0.65).lineLimit(1)
        VStack(alignment: .leading, spacing: 4) { Text("Time remaining").font(.headline).foregroundStyle(.secondary); Text(nextAt, style: .timer).font(.system(.title, design: .rounded).monospacedDigit()).minimumScaleFactor(0.6).lineLimit(1) }
        Spacer(minLength: 0)
      }.privacySensitive().accessibilityElement(children: .ignore).accessibilityLabel(Text("\(name), \(nextAt.formatted(date: .omitted, time: .shortened))"))
    default:
      VStack(alignment: .leading, spacing: 4) { Text(name).font(.headline).lineLimit(1).minimumScaleFactor(0.75); Text(nextAt, style: .timer).font(.title3.monospacedDigit()).accessibilityLabel("Time remaining"); Text(nextAt, style: .time).font(.caption).foregroundStyle(.secondary) }.privacySensitive().accessibilityElement(children: .combine)
    }
  }

  @ViewBuilder private var unavailableContent: some View {
    if entry.snapshot?.privacyMode == "redacted" {
      if family == .accessoryCircular || family == .accessoryInline { Label { Text("Prayer times hidden") } icon: { Image(systemName: "lock.fill") }.accessibilityLabel(Text("Prayer times hidden for privacy")) }
      else { stateContent(icon: "lock.fill", title: "Prayer times hidden", accessibility: "Prayer times hidden for privacy") }
    } else if family == .accessoryCircular || family == .accessoryInline {
      Label { Text("Open app to refresh") } icon: { Image(systemName: "arrow.clockwise") }.accessibilityLabel(Text("Prayer information needs to be refreshed in the app"))
    } else if let snapshot = entry.snapshot {
      switch snapshot.freshness(at: entry.date) {
      case .timeZoneChanged: stateContent(icon: "globe", title: "Location changed", accessibility: "Prayer times need refresh after a time zone change")
      case .prayerBoundaryPassed, .expired: stateContent(icon: "arrow.clockwise", title: "Prayer times need refresh", accessibility: "Prayer information is out of date. Open the app to refresh")
      case .generatedInFuture, .unsupportedSchema, .malformed: stateContent(icon: "exclamationmark.circle", title: "Open app to refresh", accessibility: "Prayer information cannot be shown safely. Open the app to refresh")
      case .fresh: stateContent(icon: "arrow.clockwise", title: "Open app to refresh", accessibility: "Prayer information needs to be refreshed in the app")
      }
    } else { stateContent(icon: "arrow.clockwise", title: "Open app to refresh", accessibility: "Prayer information needs to be refreshed in the app") }
  }
  private func stateContent(icon: String, title: LocalizedStringKey, accessibility: LocalizedStringKey) -> some View { VStack(alignment: .leading, spacing: 5) { Image(systemName: icon).accessibilityHidden(true); Text(title).font(.headline) }.accessibilityElement(children: .ignore).accessibilityLabel(accessibility) }
}

struct PrayerTimesWidget: Widget {
  let kind = "PrayerTimesWidget"
  var body: some WidgetConfiguration { StaticConfiguration(kind: kind, provider: PrayerProvider()) { PrayerWidgetView(entry: $0) }.configurationDisplayName("Prayer Times").description("Shows the next prayer from your on-device schedule.").supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular]) }
}

@main struct PrayerWidgetBundle: WidgetBundle { var body: some Widget { PrayerTimesWidget() } }
