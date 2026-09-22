import Foundation
import SwiftUI
import WidgetKit

/// Mirrors WidgetPrayerSnapshot's persisted v1 JSON without importing Runner code into the extension.
/// JSONEncoder(.millisecondsSince1970) stores Date values as millisecond numbers.
private struct PrayerSnapshot: Decodable {
  static let schemaVersion = 1
  let version: Int
  let generatedAt: Double
  let validUntil: Double
  let timeZoneIdentifier: String
  let calculationFingerprint: String
  let nextPrayerID: String?
  let nextPrayerAt: Double?
  let displayName: String?
  let privacyMode: String

  enum Freshness {
    case fresh
    case unsupportedSchema
    case malformed
    case generatedInFuture
    case expired
    case timeZoneChanged
    case prayerBoundaryPassed
  }

  func freshness(now: Date = Date(), currentTimeZone: TimeZone = .autoupdatingCurrent) -> Freshness {
    let nowMs = now.timeIntervalSince1970 * 1000
    guard version == Self.schemaVersion else { return .unsupportedSchema }
    let prayerID = nextPrayerID?.trimmingCharacters(in: .whitespacesAndNewlines)
    let hasPrayerID = !(prayerID?.isEmpty ?? true)
    let hasPrayerTime = nextPrayerAt != nil
    guard generatedAt < validUntil,
          privacyMode == "standard" || privacyMode == "redacted",
          TimeZone(identifier: timeZoneIdentifier) != nil,
          !calculationFingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          hasPrayerID == hasPrayerTime,
          nextPrayerAt.map({ $0 > generatedAt && $0 <= validUntil }) ?? true else { return .malformed }
    guard generatedAt <= nowMs else { return .generatedInFuture }
    guard nowMs < validUntil else { return .expired }
    guard timeZoneIdentifier == currentTimeZone.identifier else { return .timeZoneChanged }
    if let nextPrayerAt, nextPrayerAt <= nowMs { return .prayerBoundaryPassed }
    return .fresh
  }

  var isRedacted: Bool { privacyMode == "redacted" }
}

private enum SnapshotReader {
  static let suiteName = "group.app.quranikerim.shared"
  static let payloadKey = "widget.prayer.snapshot.v1"

  struct Result {
    let snapshot: PrayerSnapshot?
    let freshness: PrayerSnapshot.Freshness?
  }

  static func read(now: Date = Date(), timeZone: TimeZone = .autoupdatingCurrent) -> Result {
    guard let defaults = UserDefaults(suiteName: suiteName), let data = defaults.data(forKey: payloadKey) else {
      return Result(snapshot: nil, freshness: nil)
    }
    guard let snapshot = try? JSONDecoder().decode(PrayerSnapshot.self, from: data) else {
      return Result(snapshot: nil, freshness: .malformed)
    }
    let freshness = snapshot.freshness(now: now, currentTimeZone: timeZone)
    return Result(snapshot: freshness == .fresh ? snapshot : nil, freshness: freshness)
  }
}

private struct PrayerEntry: TimelineEntry {
  let date: Date
  let snapshot: PrayerSnapshot?
  let freshness: PrayerSnapshot.Freshness?
}

private struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry { PrayerEntry(date: Date(), snapshot: nil, freshness: nil) }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    let now = Date(), result = SnapshotReader.read(now: now)
    completion(PrayerEntry(date: now, snapshot: result.snapshot, freshness: result.freshness))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let now = Date(), result = SnapshotReader.read(now: now)
    var refresh = now.addingTimeInterval(15 * 60)
    if let snapshot = result.snapshot {
      let expiry = Date(timeIntervalSince1970: snapshot.validUntil / 1000)
      if expiry > now { refresh = min(refresh, expiry) }
      if let next = snapshot.nextPrayerAt {
        let boundary = Date(timeIntervalSince1970: next / 1000)
        if boundary > now { refresh = min(refresh, boundary) }
      }
    } else if result.freshness != nil {
      // Invalid/stale data must never linger for a long timeline window. Ask WidgetKit
      // for a near-term retry while the app has a chance to republish a valid snapshot.
      refresh = now.addingTimeInterval(5 * 60)
    }
    completion(Timeline(entries: [PrayerEntry(date: now, snapshot: result.snapshot, freshness: result.freshness)], policy: .after(refresh)))
  }
}

private struct PrayerWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PrayerEntry

  var body: some View {
    widgetBackground {
      Group {
        if let snapshot = entry.snapshot {
          if snapshot.isRedacted { privacyRedacted } else { content(snapshot) }
        } else { unavailable }
      }
      .widgetURL(URL(string: "quranikerim://prayer"))
      .privacySensitive()
    }
  }

  @ViewBuilder private func content(_ snapshot: PrayerSnapshot) -> some View {
    if let id = snapshot.nextPrayerID, let at = snapshot.nextPrayerAt {
      if #available(iOSApplicationExtension 16.0, *), family == .accessoryInline { inline(id: id, at: at) }
      else if #available(iOSApplicationExtension 16.0, *), family == .accessoryCircular { circular(id: id, at: at) }
      else if #available(iOSApplicationExtension 16.0, *), family == .accessoryRectangular { rectangular(id: id, at: at) }
      else { homeScreen(id: id, at: at) }
    } else { unavailable }
  }

  @available(iOSApplicationExtension 16.0, *) private func inline(id: String, at: Double) -> some View {
    Text("\(localizedPrayerName(id)) · \(time(at))")
      .lineLimit(1)
      .accessibilityLabel(accessibilityLabel(id: id, at: at))
  }
  @available(iOSApplicationExtension 16.0, *) private func circular(id: String, at: Double) -> some View {
    VStack(spacing: 1) { Text(localizedPrayerName(id)).font(.caption2).lineLimit(1).minimumScaleFactor(0.7); Text(time(at)).font(.caption.bold()).minimumScaleFactor(0.65) }
      .accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(id: id, at: at))
  }
  @available(iOSApplicationExtension 16.0, *) private func rectangular(id: String, at: Double) -> some View {
    VStack(alignment: .leading, spacing: 2) { Text(String(localized: "Prayer Times", table: "Localizable")).font(.caption2).foregroundStyle(.secondary).lineLimit(1); Text("\(localizedPrayerName(id))  \(time(at))").font(.headline).minimumScaleFactor(0.75) }
      .accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(id: id, at: at))
  }

  @ViewBuilder private func homeScreen(id: String, at: Double) -> some View {
    if family == .systemLarge || family == .systemExtraLarge {
      VStack(alignment: .leading, spacing: 12) { Text(String(localized: "Prayer Times", table: "Localizable")).font(.headline); Spacer(minLength: 4); Text(localizedPrayerName(id)).font(.title2.weight(.semibold)).minimumScaleFactor(0.75); Text(time(at)).font(.system(.largeTitle, design: .rounded).bold().monospacedDigit()).minimumScaleFactor(0.65); Spacer(minLength: 4); Text(String(localized: "Shows the next prayer from your on-device schedule.", table: "Localizable")).font(.caption).foregroundStyle(.secondary) }
        .accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(id: id, at: at))
    } else {
      VStack(alignment: .leading, spacing: 6) { Text(String(localized: "Prayer Times", table: "Localizable")).font(.caption).foregroundStyle(.secondary); Spacer(minLength: 2); Text(localizedPrayerName(id)).font(.headline); Text(time(at)).font(.title2.bold().monospacedDigit()).minimumScaleFactor(0.7) }
        .accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(id: id, at: at))
    }
  }

  @ViewBuilder private var privacyRedacted: some View {
    if #available(iOSApplicationExtension 16.0, *), family == .accessoryInline {
      Text(String(localized: "Prayer times hidden", table: "Localizable")).accessibilityLabel(String(localized: "Prayer times hidden for privacy", table: "Localizable"))
    } else {
      VStack(alignment: .leading, spacing: 4) { Text(String(localized: "Prayer times hidden", table: "Localizable")).font(.headline); Text(String(localized: "Prayer times hidden for privacy", table: "Localizable")).font(.caption).foregroundStyle(.secondary) }.accessibilityElement(children: .combine)
    }
  }
  @ViewBuilder private var unavailable: some View {
    if #available(iOSApplicationExtension 16.0, *), family == .accessoryInline {
      Text(String(localized: "Open app to refresh", table: "Localizable"))
    } else {
      VStack(alignment: .leading, spacing: 4) {
        Text(String(localized: "Prayer Times", table: "Localizable")).font(.headline)
        Text(String(localized: "Open app to refresh", table: "Localizable")).font(.caption).foregroundStyle(.secondary)
      }
      .accessibilityElement(children: .combine)
    }
  }
  private func time(_ milliseconds: Double) -> String { let formatter = DateFormatter(); formatter.locale = .autoupdatingCurrent; formatter.timeZone = .autoupdatingCurrent; formatter.timeStyle = .short; formatter.dateStyle = .none; return formatter.string(from: Date(timeIntervalSince1970: milliseconds / 1000)) }
  private func localizedPrayerName(_ id: String) -> String {
    let normalized = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "_", with: "").replacingOccurrences(of: "-", with: "")
    let key: String
    switch normalized { case "fajr", "imsak": key = "Fajr"; case "sunrise", "shuruq", "shurooq": key = "Sunrise"; case "dhuhr", "zuhr", "noon": key = "Dhuhr"; case "asr": key = "Asr"; case "maghrib", "sunset": key = "Maghrib"; case "isha", "ishaa": key = "Isha"; default: return String(localized: "Prayer", table: "Localizable") }
    return String(localized: String.LocalizationValue(key), table: "Localizable")
  }
  private func accessibilityLabel(id: String, at: Double) -> String { [String(localized: "Prayer Times", table: "Localizable"), localizedPrayerName(id), time(at)].joined(separator: ", ") }

  @ViewBuilder private func widgetBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    if #available(iOS 17.0, *) { content().containerBackground(for: .widget) { Color(uiColor: .secondarySystemBackground) }.padding() }
    else { content().padding().background(Color(uiColor: .secondarySystemBackground)) }
  }
}

@main struct PrayerTimesWidget: Widget {
  private var supportedFamilies: [WidgetFamily] { var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]; if #available(iOSApplicationExtension 16.0, *) { families.append(contentsOf: [.accessoryInline, .accessoryCircular, .accessoryRectangular]) }; return families }
  var body: some WidgetConfiguration { StaticConfiguration(kind: "PrayerTimesWidget", provider: PrayerProvider()) { entry in PrayerWidgetView(entry: entry) }.configurationDisplayName(String(localized: "Prayer Times", table: "Localizable")).description(String(localized: "Shows the next prayer from your on-device schedule.", table: "Localizable")).supportedFamilies(supportedFamilies) }
}
