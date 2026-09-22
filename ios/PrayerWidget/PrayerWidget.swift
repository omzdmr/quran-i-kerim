import Foundation
import SwiftUI
import WidgetKit

private struct PrayerSnapshot: Decodable {
  let schemaVersion: Int
  let generatedAtMs: Int64
  let validUntilMs: Int64
  let timezone: String
  let locationLabel: String?
  let nextPrayer: Prayer?
  let prayers: [Prayer]

  struct Prayer: Decodable, Identifiable {
    let id: String
    let atMs: Int64
  }

  var isFresh: Bool {
    let now = Int64(Date().timeIntervalSince1970 * 1000)
    return schemaVersion == 1 && generatedAtMs <= now + 300_000 && validUntilMs > now
  }
}

private enum SnapshotReader {
  static let suiteName = "group.app.quranikerim.shared"
  static let payloadKey = "prayer.widget.snapshot.v1"

  static func read() -> PrayerSnapshot? {
    guard let defaults = UserDefaults(suiteName: suiteName), let data = defaults.data(forKey: payloadKey), let snapshot = try? JSONDecoder().decode(PrayerSnapshot.self, from: data), snapshot.isFresh else { return nil }
    return snapshot
  }
}

private struct PrayerEntry: TimelineEntry { let date: Date; let snapshot: PrayerSnapshot? }

private struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry { PrayerEntry(date: Date(), snapshot: nil) }
  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) { completion(PrayerEntry(date: Date(), snapshot: SnapshotReader.read())) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let snapshot = SnapshotReader.read(), now = Date()
    var refresh = now.addingTimeInterval(15 * 60)
    if let snapshot {
      let expiry = Date(timeIntervalSince1970: Double(snapshot.validUntilMs) / 1000)
      if expiry > now { refresh = min(refresh, expiry) }
    }
    completion(Timeline(entries: [PrayerEntry(date: now, snapshot: snapshot)], policy: .after(refresh)))
  }
}

private struct PrayerWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PrayerEntry

  var body: some View {
    widgetBackground {
      Group {
        if let snapshot = entry.snapshot { content(snapshot) } else { unavailable }
      }
      .widgetURL(URL(string: "quranikerim://prayer"))
      .privacySensitive()
    }
  }

  @ViewBuilder private func content(_ snapshot: PrayerSnapshot) -> some View {
    switch family {
    case .accessoryCircular:
      if let next = snapshot.nextPrayer {
        VStack(spacing: 1) { Text(localizedPrayerName(next.id)).font(.caption2).lineLimit(1).minimumScaleFactor(0.7); Text(time(next.atMs)).font(.caption.bold()).minimumScaleFactor(0.65) }
          .accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(next, location: snapshot.locationLabel))
      } else { unavailable }
    case .accessoryRectangular:
      if let next = snapshot.nextPrayer {
        VStack(alignment: .leading, spacing: 2) { Text(snapshot.locationLabel ?? String(localized: "PrayerWidgetTitle", table: "Localizable")).font(.caption2).foregroundStyle(.secondary).lineLimit(1); Text("\(localizedPrayerName(next.id))  \(time(next.atMs))").font(.headline).minimumScaleFactor(0.75) }
          .accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(next, location: snapshot.locationLabel))
      } else { unavailable }
    case .systemLarge:
      VStack(alignment: .leading, spacing: 10) {
        header(snapshot)
        let visible = Array(snapshot.prayers.prefix(6))
        ForEach(visible) { prayer in
          HStack { Text(localizedPrayerName(prayer.id)).font(.body.weight(.medium)); Spacer(); Text(time(prayer.atMs)).font(.body.monospacedDigit()) }
            .accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(prayer, location: nil))
        }
        Spacer(minLength: 0)
      }
    case .systemExtraLarge:
      VStack(alignment: .leading, spacing: 12) {
        header(snapshot)
        let visible = Array(snapshot.prayers.prefix(8))
        ViewThatFits(in: .horizontal) {
          HStack(alignment: .top, spacing: 24) { prayerColumn(Array(visible.prefix(4))); prayerColumn(Array(visible.dropFirst(4))) }
          prayerColumn(visible)
        }
        Spacer(minLength: 0)
      }
    default:
      if let next = snapshot.nextPrayer {
        VStack(alignment: .leading, spacing: 6) { header(snapshot); Spacer(minLength: 2); Text(localizedPrayerName(next.id)).font(.headline); Text(time(next.atMs)).font(.title2.bold().monospacedDigit()).minimumScaleFactor(0.7) }
          .accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(next, location: snapshot.locationLabel))
      } else { unavailable }
    }
  }

  private func header(_ snapshot: PrayerSnapshot) -> some View { VStack(alignment: .leading, spacing: 2) { Text(String(localized: "PrayerWidgetTitle", table: "Localizable")).font(.caption).foregroundStyle(.secondary); if let label = snapshot.locationLabel, !label.isEmpty { Text(label).font(.headline).lineLimit(1) } } }
  private func prayerColumn(_ prayers: [PrayerSnapshot.Prayer]) -> some View { VStack(spacing: 8) { ForEach(prayers) { prayer in HStack { Text(localizedPrayerName(prayer.id)).lineLimit(1); Spacer(); Text(time(prayer.atMs)).monospacedDigit() }.accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(prayer, location: nil)) } } }
  private var unavailable: some View { VStack(alignment: .leading, spacing: 4) { Text(String(localized: "PrayerWidgetTitle", table: "Localizable")).font(.headline); Text(String(localized: "PrayerWidgetOpenApp", table: "Localizable")).font(.caption).foregroundStyle(.secondary) }.accessibilityElement(children: .combine) }
  private func time(_ milliseconds: Int64) -> String { let formatter = DateFormatter(); formatter.locale = .autoupdatingCurrent; formatter.timeZone = .autoupdatingCurrent; formatter.timeStyle = .short; formatter.dateStyle = .none; return formatter.string(from: Date(timeIntervalSince1970: Double(milliseconds) / 1000)) }
  private func localizedPrayerName(_ id: String) -> String { let normalized = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "_", with: "").replacingOccurrences(of: "-", with: ""); let key: String; switch normalized { case "fajr": key = "PrayerNameFajr"; case "sunrise", "shuruq": key = "PrayerNameSunrise"; case "dhuhr", "zuhr": key = "PrayerNameDhuhr"; case "asr": key = "PrayerNameAsr"; case "maghrib": key = "PrayerNameMaghrib"; case "isha": key = "PrayerNameIsha"; case "imsak": key = "PrayerNameImsak"; default: key = "PrayerNameGeneric" }; return String(localized: String.LocalizationValue(key), table: "Localizable") }
  private func accessibilityLabel(_ prayer: PrayerSnapshot.Prayer, location: String?) -> String { [location, localizedPrayerName(prayer.id), time(prayer.atMs)].compactMap { value in guard let value, !value.isEmpty else { return nil }; return value }.joined(separator: ", ") }

  @ViewBuilder private func widgetBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    if #available(iOS 17.0, *) {
      content().containerBackground(for: .widget) { Color(uiColor: .secondarySystemBackground) }.padding()
    } else {
      content().padding().background(Color(uiColor: .secondarySystemBackground))
    }
  }
}

@main struct PrayerTimesWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PrayerTimesWidget", provider: PrayerProvider()) { entry in PrayerWidgetView(entry: entry) }
      .configurationDisplayName(String(localized: "PrayerWidgetTitle", table: "Localizable"))
      .description(String(localized: "PrayerWidgetDescription", table: "Localizable"))
      .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryRectangular])
  }
}
