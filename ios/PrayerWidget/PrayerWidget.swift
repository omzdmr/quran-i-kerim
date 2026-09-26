import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

private struct PrayerSnapshot: Decodable {
  static let schemaVersion = 2
  static let maximumAgeMilliseconds: Double = 36 * 60 * 60 * 1000
  let version: Int
  let generatedAt: Double
  let validUntil: Double
  let timeZoneIdentifier: String
  let localeIdentifier: String
  let calculationFingerprint: String
  let nextPrayerID: String?
  let nextPrayerAt: Double?
  let displayName: String?
  let privacyMode: String
  enum Freshness { case fresh, unsupportedSchema, malformed, generatedInFuture, generatedTooOld, expired, timeZoneChanged, localeChanged, prayerBoundaryPassed }
  func freshness(now: Date = Date(), currentTimeZone: TimeZone = .autoupdatingCurrent, currentLocale: Locale = .autoupdatingCurrent) -> Freshness {
    let nowMs = now.timeIntervalSince1970 * 1000
    guard version == Self.schemaVersion else { return .unsupportedSchema }
    let prayerID = nextPrayerID?.trimmingCharacters(in: .whitespacesAndNewlines), hasPrayerID = !(prayerID?.isEmpty ?? true), hasPrayerTime = nextPrayerAt != nil
    guard generatedAt < validUntil, privacyMode == "standard" || privacyMode == "redacted", TimeZone(identifier: timeZoneIdentifier) != nil, !localeIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !calculationFingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, hasPrayerID == hasPrayerTime, (privacyMode == "redacted" || hasPrayerID), nextPrayerAt.map({ $0 > generatedAt && $0 <= validUntil }) ?? true else { return .malformed }
    guard generatedAt <= nowMs else { return .generatedInFuture }
    guard nowMs - generatedAt <= Self.maximumAgeMilliseconds else { return .generatedTooOld }
    guard nowMs < validUntil else { return .expired }
    guard timeZoneIdentifier == currentTimeZone.identifier else { return .timeZoneChanged }
    guard localeIdentifier == currentLocale.identifier else { return .localeChanged }
    if let nextPrayerAt, nextPrayerAt <= nowMs { return .prayerBoundaryPassed }
    return .fresh
  }
  var isRedacted: Bool { privacyMode == "redacted" }
}

private enum SnapshotReader {
  static let suiteName = "group.app.quranikerim.shared"
  static let payloadKey = "widget.prayer.snapshot.v1"
  struct Result { let snapshot: PrayerSnapshot?; let freshness: PrayerSnapshot.Freshness? }
  static func read(now: Date = Date(), timeZone: TimeZone = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> Result { guard let defaults = UserDefaults(suiteName: suiteName), let data = defaults.data(forKey: payloadKey) else { return Result(snapshot: nil, freshness: nil) }; guard let snapshot = try? JSONDecoder().decode(PrayerSnapshot.self, from: data) else { return Result(snapshot: nil, freshness: .malformed) }; let freshness = snapshot.freshness(now: now, currentTimeZone: timeZone, currentLocale: locale); return Result(snapshot: freshness == .fresh ? snapshot : nil, freshness: freshness) }
}

private struct PrayerEntry: TimelineEntry { let date: Date; let snapshot: PrayerSnapshot?; let freshness: PrayerSnapshot.Freshness? }
private struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry { PrayerEntry(date: Date(), snapshot: nil, freshness: nil) }
  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) { let now = Date(), result = SnapshotReader.read(now: now); completion(PrayerEntry(date: now, snapshot: result.snapshot, freshness: result.freshness)) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let now = Date(), result = SnapshotReader.read(now: now), current = PrayerEntry(date: now, snapshot: result.snapshot, freshness: result.freshness)
    guard let snapshot = result.snapshot else { completion(Timeline(entries: [current], policy: .after(now.addingTimeInterval(result.freshness == nil ? 15 * 60 : 5 * 60)))); return }
    var boundaries: [(Date, PrayerSnapshot.Freshness)] = [(Date(timeIntervalSince1970: snapshot.validUntil / 1000), .expired), (Date(timeIntervalSince1970: (snapshot.generatedAt + PrayerSnapshot.maximumAgeMilliseconds) / 1000), .generatedTooOld)]
    if let next = snapshot.nextPrayerAt { boundaries.append((Date(timeIntervalSince1970: next / 1000), .prayerBoundaryPassed)) }
    guard let boundary = boundaries.filter({ $0.0 > now }).min(by: { $0.0 < $1.0 }) else { completion(Timeline(entries: [current], policy: .after(now.addingTimeInterval(5 * 60)))); return }
    let failClosed = PrayerEntry(date: boundary.0, snapshot: nil, freshness: boundary.1)
    completion(Timeline(entries: [current, failClosed], policy: .after(boundary.0.addingTimeInterval(5 * 60))))
  }
}

private struct PrayerWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PrayerEntry
  var body: some View { widgetBackground { Group { if let snapshot = entry.snapshot { if snapshot.isRedacted { privacyRedacted } else { content(snapshot) } } else { unavailable } }.widgetURL(URL(string: "quranikerim://prayer")).privacySensitive() } }
  @ViewBuilder private func content(_ snapshot: PrayerSnapshot) -> some View { if let id = snapshot.nextPrayerID, let at = snapshot.nextPrayerAt { if #available(iOSApplicationExtension 16.0, *), family == .accessoryInline { inline(id: id, at: at) } else if #available(iOSApplicationExtension 16.0, *), family == .accessoryCircular { circular(id: id, at: at) } else if #available(iOSApplicationExtension 16.0, *), family == .accessoryRectangular { rectangular(id: id, at: at) } else { homeScreen(id: id, at: at) } } else { unavailable } }
  @available(iOSApplicationExtension 16.0, *) private func inline(id: String, at: Double) -> some View { HStack(spacing: 3) { Text(localizedPrayerName(id)); Text("·").accessibilityHidden(true); Text(time(at)).monospacedDigit() }.lineLimit(1).accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(id: id, at: at)) }
  @available(iOSApplicationExtension 16.0, *) private func circular(id: String, at: Double) -> some View { VStack(spacing: 1) { Text(localizedPrayerName(id)).font(.caption2).lineLimit(1).minimumScaleFactor(0.7); Text(time(at)).font(.caption.bold()).minimumScaleFactor(0.65) }.accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(id: id, at: at)) }
  @available(iOSApplicationExtension 16.0, *) private func rectangular(id: String, at: Double) -> some View { VStack(alignment: .leading, spacing: 2) { Text(String(localized: "Prayer Times", table: "Localizable")).font(.caption2).foregroundStyle(.secondary).lineLimit(1); HStack(spacing: 5) { Text(localizedPrayerName(id)); Text(time(at)).monospacedDigit() }.font(.headline).minimumScaleFactor(0.75) }.accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(id: id, at: at)) }
  @ViewBuilder private func homeScreen(id: String, at: Double) -> some View { if family == .systemLarge || family == .systemExtraLarge { VStack(alignment: .leading, spacing: 12) { Text(String(localized: "Prayer Times", table: "Localizable")).font(.headline); Spacer(minLength: 4); Text(localizedPrayerName(id)).font(.title2.weight(.semibold)).minimumScaleFactor(0.75); Text(time(at)).font(.system(.largeTitle, design: .rounded).bold().monospacedDigit()).minimumScaleFactor(0.65); Spacer(minLength: 4); Text(String(localized: "Shows the next prayer from your on-device schedule.", table: "Localizable")).font(.caption).foregroundStyle(.secondary) }.accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(id: id, at: at)) } else { VStack(alignment: .leading, spacing: 6) { Text(String(localized: "Prayer Times", table: "Localizable")).font(.caption).foregroundStyle(.secondary); Spacer(minLength: 2); Text(localizedPrayerName(id)).font(.headline); Text(time(at)).font(.title2.bold().monospacedDigit()).minimumScaleFactor(0.7) }.accessibilityElement(children: .ignore).accessibilityLabel(accessibilityLabel(id: id, at: at)) } }
  @ViewBuilder private var privacyRedacted: some View { if #available(iOSApplicationExtension 16.0, *), family == .accessoryInline { Text(String(localized: "Prayer times hidden", table: "Localizable")).accessibilityLabel(String(localized: "Prayer times hidden for privacy", table: "Localizable")) } else if #available(iOSApplicationExtension 16.0, *), family == .accessoryCircular { Image(systemName: "lock.fill").accessibilityLabel(String(localized: "Prayer times hidden for privacy", table: "Localizable")) } else if #available(iOSApplicationExtension 16.0, *), family == .accessoryRectangular { Text(String(localized: "Prayer times hidden", table: "Localizable")).font(.caption).accessibilityLabel(String(localized: "Prayer times hidden for privacy", table: "Localizable")) } else { VStack(alignment: .leading, spacing: 4) { Text(String(localized: "Prayer times hidden", table: "Localizable")).font(.headline); Text(String(localized: "Prayer times hidden for privacy", table: "Localizable")).font(.caption).foregroundStyle(.secondary) }.accessibilityElement(children: .combine) } }
  @ViewBuilder private var unavailable: some View { if #available(iOSApplicationExtension 16.0, *), family == .accessoryInline { Text(unavailableMessage).lineLimit(1) } else if #available(iOSApplicationExtension 16.0, *), family == .accessoryCircular { Image(systemName: "arrow.clockwise").accessibilityLabel(unavailableMessage) } else if #available(iOSApplicationExtension 16.0, *), family == .accessoryRectangular { Text(unavailableMessage).font(.caption).lineLimit(2) } else { VStack(alignment: .leading, spacing: 4) { Text(String(localized: "Prayer Times", table: "Localizable")).font(.headline); Text(unavailableMessage).font(.caption).foregroundStyle(.secondary) }.accessibilityElement(children: .combine) } }
  private var unavailableMessage: String { switch entry.freshness { case .timeZoneChanged: return String(localized: "Prayer times need refresh after a time zone change", table: "Localizable"); case .localeChanged: return String(localized: "Open app to refresh", table: "Localizable"); case .generatedTooOld, .expired, .prayerBoundaryPassed: return String(localized: "Prayer information is out of date. Open the app to refresh", table: "Localizable"); case .malformed, .unsupportedSchema, .generatedInFuture: return String(localized: "Prayer information cannot be shown safely. Open the app to refresh", table: "Localizable"); case .fresh, .none: return String(localized: "Open app to refresh", table: "Localizable") } }
  private func time(_ milliseconds: Double) -> String { let formatter = DateFormatter(); formatter.locale = .autoupdatingCurrent; formatter.timeZone = .autoupdatingCurrent; formatter.timeStyle = .short; formatter.dateStyle = .none; return formatter.string(from: Date(timeIntervalSince1970: milliseconds / 1000)) }
  private func localizedPrayerName(_ id: String) -> String { let normalized = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "_", with: "").replacingOccurrences(of: "-", with: ""); let key: String; switch normalized { case "fajr", "imsak": key = "Fajr"; case "sunrise", "shuruq", "shurooq": key = "Sunrise"; case "dhuhr", "zuhr", "noon": key = "Dhuhr"; case "asr": key = "Asr"; case "maghrib", "sunset": key = "Maghrib"; case "isha", "ishaa": key = "Isha"; default: return String(localized: "Prayer", table: "Localizable") }; return String(localized: String.LocalizationValue(key), table: "Localizable") }
  private func accessibilityLabel(id: String, at: Double) -> String { [String(localized: "Prayer Times", table: "Localizable"), localizedPrayerName(id), time(at)].joined(separator: ", ") }
  private var isAccessoryFamily: Bool { if #available(iOSApplicationExtension 16.0, *) { return family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular }; return false }
  @ViewBuilder private func widgetBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View { if isAccessoryFamily { content() } else if #available(iOS 17.0, *) { content().containerBackground(for: .widget) { Color(uiColor: .secondarySystemBackground) }.padding() } else { content().padding().background(Color(uiColor: .secondarySystemBackground)) } }
}

struct PrayerTimesWidget: Widget {
  private var supportedFamilies: [WidgetFamily] { var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]; if #available(iOSApplicationExtension 16.0, *) { families.append(contentsOf: [.accessoryInline, .accessoryCircular, .accessoryRectangular]) }; return families }
  var body: some WidgetConfiguration { StaticConfiguration(kind: "PrayerTimesWidget", provider: PrayerProvider()) { entry in PrayerWidgetView(entry: entry) }.configurationDisplayName(String(localized: "Prayer Times", table: "Localizable")).description(String(localized: "Shows the next prayer from your on-device schedule.", table: "Localizable")).supportedFamilies(supportedFamilies) }
}


@available(iOS 16.1, *)
private struct PrayerLiveActivityView: View {
  let state: PrayerActivityAttributes.ContentState
  let isStale: Bool

  var body: some View {
    Group {
      if isStale {
        Label(String(localized: "Open app to refresh", table: "Localizable"), systemImage: "arrow.clockwise")
      } else if state.isRedacted {
        Label(String(localized: "Prayer times hidden", table: "Localizable"), systemImage: "lock.fill")
      } else {
        VStack(alignment: .leading, spacing: 4) {
          Text(state.displayName).font(.headline)
          Text(Date(timeIntervalSince1970: state.prayerAtMilliseconds / 1000), style: .timer)
            .monospacedDigit()
        }
      }
    }
    .accessibilityElement(children: .combine)
    .privacySensitive()
    .widgetURL(URL(string: "quranikerim://prayer"))
  }
}

@available(iOS 16.1, *)
private func prayerActivityIsStale(_ context: ActivityViewContext<PrayerActivityAttributes>) -> Bool {
  if #available(iOS 16.2, *) { return context.isStale }
  return false
}

@available(iOS 16.1, *)
struct PrayerLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
      let stale = prayerActivityIsStale(context)
      PrayerLiveActivityView(state: context.state, isStale: stale)
        .padding()
        .activityBackgroundTint(Color(uiColor: .secondarySystemBackground))
    } dynamicIsland: { context in
      let stale = prayerActivityIsStale(context)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: stale ? "arrow.clockwise" : (context.state.isRedacted ? "lock.fill" : "moon.stars.fill"))
            .accessibilityLabel(stale ? String(localized: "Open app to refresh", table: "Localizable") : (context.state.isRedacted ? String(localized: "Prayer times hidden", table: "Localizable") : context.state.displayName))
        }
        DynamicIslandExpandedRegion(.trailing) {
          if !stale && !context.state.isRedacted {
            Text(Date(timeIntervalSince1970: context.state.prayerAtMilliseconds / 1000), style: .timer).monospacedDigit()
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(stale ? String(localized: "Open app to refresh", table: "Localizable") : (context.state.isRedacted ? String(localized: "Prayer times hidden", table: "Localizable") : context.state.displayName))
        }
      } compactLeading: {
        Image(systemName: stale ? "arrow.clockwise" : (context.state.isRedacted ? "lock.fill" : "moon.stars.fill"))
          .accessibilityLabel(stale ? String(localized: "Open app to refresh", table: "Localizable") : (context.state.isRedacted ? String(localized: "Prayer times hidden", table: "Localizable") : context.state.displayName))
      } compactTrailing: {
        if stale {
          Image(systemName: "arrow.clockwise").accessibilityLabel(String(localized: "Open app to refresh", table: "Localizable"))
        } else if context.state.isRedacted {
          Image(systemName: "lock.fill")
        } else {
          Text(Date(timeIntervalSince1970: context.state.prayerAtMilliseconds / 1000), style: .timer).monospacedDigit()
        }
      } minimal: {
        Image(systemName: stale ? "arrow.clockwise" : (context.state.isRedacted ? "lock.fill" : "moon.stars.fill"))
          .accessibilityLabel(stale ? String(localized: "Open app to refresh", table: "Localizable") : (context.state.isRedacted ? String(localized: "Prayer times hidden", table: "Localizable") : context.state.displayName))
      }
      .widgetURL(URL(string: "quranikerim://prayer"))
    }
  }
}

@main
struct QuranWidgetBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    PrayerTimesWidget()
    if #available(iOS 16.1, *) {
      PrayerLiveActivityWidget()
    }
  }
}
