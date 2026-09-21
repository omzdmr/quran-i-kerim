import SwiftUI
import WidgetKit

private let appGroup = "group.app.quranikerim.shared"
private let snapshotKey = "widget.prayer.snapshot.v1"

private struct PrayerSnapshot: Decodable {
  let version: Int
  let generatedAt: Date
  let validUntil: Date
  let timeZoneIdentifier: String
  let calculationFingerprint: String
  let nextPrayerID: String?
  let nextPrayerAt: Date?
  let displayName: String?
  let privacyMode: String

  func isFresh(at date: Date, timeZone: TimeZone = .current) -> Bool {
    version == 1 && generatedAt <= date && date < validUntil && timeZoneIdentifier == timeZone.identifier
  }
}

private struct PrayerEntry: TimelineEntry {
  let date: Date
  let snapshot: PrayerSnapshot?

  var canShowDetails: Bool {
    guard let snapshot else { return false }
    return snapshot.isFresh(at: date) && snapshot.privacyMode == "standard" && (snapshot.nextPrayerAt ?? .distantPast) > date
  }
}

private struct PrayerProvider: TimelineProvider {
  private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    return decoder
  }()

  func placeholder(in context: Context) -> PrayerEntry { PrayerEntry(date: Date(), snapshot: nil) }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(PrayerEntry(date: Date(), snapshot: load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let now = Date()
    let snapshot = load()
    let entry = PrayerEntry(date: now, snapshot: snapshot)
    // Never let a prayer countdown live past the producer's validity boundary.
    // A short fallback retry also recovers after first install before Flutter publishes.
    let refresh = snapshot.map { max(now.addingTimeInterval(60), min($0.validUntil, now.addingTimeInterval(30 * 60))) }
      ?? now.addingTimeInterval(5 * 60)
    completion(Timeline(entries: [entry], policy: .after(refresh)))
  }

  private func load() -> PrayerSnapshot? {
    guard let defaults = UserDefaults(suiteName: appGroup),
          let data = defaults.data(forKey: snapshotKey),
          let snapshot = try? decoder.decode(PrayerSnapshot.self, from: data),
          snapshot.version == 1 else { return nil }
    return snapshot
  }
}

private struct PrayerWidgetView: View {
  let entry: PrayerEntry

  var body: some View {
    Group {
      if entry.canShowDetails, let snapshot = entry.snapshot, let nextAt = snapshot.nextPrayerAt {
        VStack(alignment: .leading, spacing: 4) {
          Text(snapshot.displayName ?? snapshot.nextPrayerID ?? String(localized: "Prayer"))
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
          Text(nextAt, style: .timer)
            .font(.title3.monospacedDigit())
            .accessibilityLabel("Time remaining")
          Text(nextAt, style: .time)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .privacySensitive()
        .accessibilityElement(children: .combine)
      } else if entry.snapshot?.privacyMode == "redacted" {
        VStack(alignment: .leading, spacing: 5) {
          Image(systemName: "lock.fill")
            .accessibilityHidden(true)
          Text("Prayer times hidden").font(.headline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Prayer times hidden for privacy")
      } else {
        VStack(alignment: .leading, spacing: 5) {
          Image(systemName: "arrow.clockwise")
            .accessibilityHidden(true)
          Text("Open app to refresh").font(.headline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Prayer information needs to be refreshed in the app")
      }
    }
    .containerBackground(.fill.tertiary, for: .widget)
  }
}

struct PrayerTimesWidget: Widget {
  let kind = "PrayerTimesWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
      PrayerWidgetView(entry: entry)
    }
    .configurationDisplayName("Prayer Times")
    .description("Shows the next prayer from your on-device schedule.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

@main
struct PrayerWidgetBundle: WidgetBundle {
  var body: some Widget { PrayerTimesWidget() }
}
