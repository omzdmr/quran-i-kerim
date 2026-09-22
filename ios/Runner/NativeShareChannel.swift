import Flutter
import UIKit

/// Native share sheet bridge with iPad-safe presentation and lifecycle-owned file staging.
/// Files are copied into a protected, backup-excluded temporary directory before they are
/// handed to extensions so the caller can safely rotate/delete its original export.
final class NativeShareChannel: NSObject, UIAdaptivePresentationControllerDelegate {
  static let channelName = "app.quranikerim/native_share"
  static let maxShareFileBytes: Int64 = 64 * 1024 * 1024
  private static let stagingDirectoryName = "quran-native-share"
  private static let orphanLifetime: TimeInterval = 24 * 60 * 60

  private let channel: FlutterMethodChannel
  private weak var presenter: UIViewController?
  private var pendingResult: FlutterResult?
  private var stagedShareURL: URL?

  init(binaryMessenger: FlutterBinaryMessenger, presenter: UIViewController) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    self.presenter = presenter
    super.init()
    cleanupOrphanedStaging()
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }

  func detach() { finish(["status": "dismissed"]); channel.setMethodCallHandler(nil) }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities":
      result(["text": true, "file": true, "ipadPopoverSafe": true, "completionStatus": true, "presentedHierarchyAware": true, "copyOnShare": true, "fileProtection": true, "backupExcludedStaging": true, "maxShareFileBytes": Self.maxShareFileBytes, "automaticCleanup": true, "orphanCleanup": true])
    case "shareText":
      guard let args = call.arguments as? [String: Any], let text = args["text"] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { result(FlutterError(code: "invalid_share_text", message: "shareText requires non-empty text.", details: nil)); return }
      present(items: [text], result: result)
    case "shareFile": shareFile(call.arguments, result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func shareFile(_ arguments: Any?, result: @escaping FlutterResult) {
    guard pendingResult == nil else { result(FlutterError(code: "share_busy", message: "A share sheet is already being presented.", details: nil)); return }
    guard let args = arguments as? [String: Any], let path = args["path"] as? String, !path.isEmpty else { result(FlutterError(code: "invalid_share_file", message: "shareFile requires a file path.", details: nil)); return }
    let source = URL(fileURLWithPath: path).standardizedFileURL
    do {
      let values = try source.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
      guard values.isRegularFile == true else { result(FlutterError(code: "share_file_not_found", message: "The share source is not a regular file.", details: nil)); return }
      let size = Int64(values.fileSize ?? 0)
      guard size >= 0 && size <= Self.maxShareFileBytes else { result(FlutterError(code: "share_file_too_large", message: "The share file exceeds the 64 MB handoff limit.", details: ["maxBytes": Self.maxShareFileBytes, "size": size])); return }
      let staged = try stageForShare(source: source, preferredFilename: args["filename"] as? String)
      stagedShareURL = staged
      present(items: [staged], result: result)
    } catch {
      cleanupStagedShare()
      result(FlutterError(code: "share_file_prepare_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func stagingDirectory() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(Self.stagingDirectoryName, isDirectory: true) }

  private func stageForShare(source: URL, preferredFilename: String?) throws -> URL {
    let directory = stagingDirectory()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: directory.path)
    var directoryValues = URLResourceValues(); directoryValues.isExcludedFromBackup = true; var mutableDirectory = directory; try mutableDirectory.setResourceValues(directoryValues)
    let filename = sanitizedFilename(preferredFilename) ?? sanitizedFilename(source.lastPathComponent) ?? "quran-share.dat"
    let destination = directory.appendingPathComponent(UUID().uuidString + "-" + filename, isDirectory: false)
    try FileManager.default.copyItem(at: source, to: destination)
    do {
      try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: destination.path)
      var values = URLResourceValues(); values.isExcludedFromBackup = true; var mutable = destination; try mutable.setResourceValues(values)
      let attributes = try FileManager.default.attributesOfItem(atPath: destination.path)
      let copiedSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
      guard copiedSize >= 0 && copiedSize <= Self.maxShareFileBytes else { throw CocoaError(.fileWriteOutOfSpace) }
      return destination
    } catch {
      try? FileManager.default.removeItem(at: destination)
      throw error
    }
  }

  private func cleanupOrphanedStaging(now: Date = Date()) {
    let directory = stagingDirectory()
    guard let urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey], options: [.skipsHiddenFiles]) else { return }
    for url in urls {
      guard url != stagedShareURL, let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]), values.isRegularFile == true, let modified = values.contentModificationDate, now.timeIntervalSince(modified) >= Self.orphanLifetime else { continue }
      try? FileManager.default.removeItem(at: url)
    }
  }

  private func present(items: [Any], result: @escaping FlutterResult) {
    guard pendingResult == nil else { cleanupStagedShare(); result(FlutterError(code: "share_busy", message: "A share sheet is already being presented.", details: nil)); return }
    guard let root = presenter, let presenter = topPresenter(from: root), presenter.viewIfLoaded?.window != nil, !presenter.isBeingDismissed else { cleanupStagedShare(); result(FlutterError(code: "share_presenter_unavailable", message: "The active iOS scene is not ready to present a share sheet.", details: nil)); return }
    pendingResult = result
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.completionWithItemsHandler = { [weak self] activity, completed, _, error in
      guard let self else { return }
      if let error { self.finish(error: FlutterError(code: "share_failed", message: error.localizedDescription, details: nil)); return }
      var payload: [String: Any] = ["status": completed ? "completed" : "cancelled"]
      if let activity { payload["activityType"] = activity.rawValue }
      self.finish(payload)
    }
    if let popover = controller.popoverPresentationController { popover.sourceView = presenter.view; popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1); popover.permittedArrowDirections = [] }
    presenter.present(controller, animated: true) { [weak self, weak controller] in controller?.presentationController?.delegate = self }
  }

  private func topPresenter(from root: UIViewController) -> UIViewController? {
    if let presented = root.presentedViewController, !presented.isBeingDismissed { return topPresenter(from: presented) }
    if let navigation = root as? UINavigationController, let visible = navigation.visibleViewController { return topPresenter(from: visible) }
    if let tab = root as? UITabBarController, let selected = tab.selectedViewController { return topPresenter(from: selected) }
    if let split = root as? UISplitViewController, let last = split.viewControllers.last { return topPresenter(from: last) }
    return root
  }

  private func sanitizedFilename(_ value: String?) -> String? { guard let value else { return nil }; let leaf = URL(fileURLWithPath: value).lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines); return (!leaf.isEmpty && leaf != "." && leaf != "..") ? leaf : nil }
  private func finish(_ payload: Any?) { guard let result = pendingResult else { cleanupStagedShare(); return }; pendingResult = nil; cleanupStagedShare(); result(payload) }
  private func finish(error: FlutterError) { guard let result = pendingResult else { cleanupStagedShare(); return }; pendingResult = nil; cleanupStagedShare(); result(error) }
  private func cleanupStagedShare() { if let stagedShareURL { try? FileManager.default.removeItem(at: stagedShareURL) }; stagedShareURL = nil }
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { finish(["status": "cancelled"]) }
}
