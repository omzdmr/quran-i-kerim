import Flutter
import UIKit

/// Shared scene-aware presenter resolution for iPad, Stage Manager and multi-window handoffs.
enum NativePresentationResolver {
  static func activePresenter(originatingFrom origin: UIViewController?) -> UIViewController? {
    if let origin,
       let window = origin.viewIfLoaded?.window,
       let scene = window.windowScene,
       scene.activationState == .foregroundActive,
       !origin.isBeingDismissed {
      return topPresenter(from: origin)
    }
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }
    for scene in scenes {
      let window = scene.windows.first(where: { $0.isKeyWindow && !$0.isHidden })
        ?? scene.windows.first(where: { !$0.isHidden && $0.windowLevel == .normal })
      if let root = window?.rootViewController, !root.isBeingDismissed {
        return topPresenter(from: root)
      }
    }
    return nil
  }

  static func topPresenter(from root: UIViewController) -> UIViewController {
    if let presented = root.presentedViewController,
       !presented.isBeingDismissed,
       presented.viewIfLoaded?.window != nil {
      return topPresenter(from: presented)
    }
    if let navigation = root as? UINavigationController, let visible = navigation.visibleViewController {
      return topPresenter(from: visible)
    }
    if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
      return topPresenter(from: selected)
    }
    if let split = root as? UISplitViewController {
      for controller in split.viewControllers.reversed() where controller.viewIfLoaded?.window != nil {
        return topPresenter(from: controller)
      }
    }
    return root
  }

  static func isPresentationReady(_ controller: UIViewController?) -> Bool {
    guard let controller,
          let scene = controller.viewIfLoaded?.window?.windowScene,
          !controller.isBeingDismissed else { return false }
    return scene.activationState == .foregroundActive
  }
}


/// Native share sheet bridge with iPad-safe presentation and lifecycle-owned file staging.
/// Each share uses a private session directory so the user-visible filename stays clean while
/// concurrent/repeated exports cannot collide. Staging is protected, backup-excluded and pruned.
final class NativeShareChannel: NSObject, UIAdaptivePresentationControllerDelegate {
  static let channelName = "app.quranikerim/native_share"
  static let maxShareFileBytes: Int64 = 64 * 1024 * 1024
  private static let stagingDirectoryName = "quran-native-share"
  private static let orphanLifetime: TimeInterval = 24 * 60 * 60

  private let channel: FlutterMethodChannel
  private weak var presenter: UIViewController?
  private var pendingResult: FlutterResult?
  private var stagedShareURL: URL?
  private weak var presentedShareController: UIActivityViewController?
  private var observers: [NSObjectProtocol] = []

  init(binaryMessenger: FlutterBinaryMessenger, presenter: UIViewController) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger); self.presenter = presenter; super.init(); cleanupOrphanedStaging()
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { [weak self] _ in self?.cleanupOrphanedStaging() })
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in self?.cleanupOrphanedStaging() })
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }
  deinit { observers.forEach(NotificationCenter.default.removeObserver) }
  func detach() { observers.forEach(NotificationCenter.default.removeObserver); observers.removeAll(); presentedShareController?.dismiss(animated: false); finish(["status": "dismissed"]); channel.setMethodCallHandler(nil) }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities": result(["text": true, "file": true, "ipadPopoverSafe": true, "completionStatus": true, "presentedHierarchyAware": true, "activeSceneAware": true, "originatingScenePreferred": true, "copyOnShare": true, "preservesFilename": true, "isolatedShareSession": true, "fileProtection": true, "backupExcludedStaging": true, "maxShareFileBytes": Self.maxShareFileBytes, "automaticCleanup": true, "orphanCleanup": true, "lifecycleCleanup": true])
    case "shareText": guard let args = call.arguments as? [String: Any], let text = args["text"] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { result(FlutterError(code: "invalid_share_text", message: "shareText requires non-empty text.", details: nil)); return }; present(items: [text], result: result)
    case "shareFile": shareFile(call.arguments, result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func shareFile(_ arguments: Any?, result: @escaping FlutterResult) {
    guard pendingResult == nil else { result(FlutterError(code: "share_busy", message: "A share sheet is already being presented.", details: nil)); return }
    guard let args = arguments as? [String: Any], let path = args["path"] as? String, !path.isEmpty else { result(FlutterError(code: "invalid_share_file", message: "shareFile requires a file path.", details: nil)); return }
    cleanupOrphanedStaging(); let source = URL(fileURLWithPath: path).standardizedFileURL
    do {
      let values = try source.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]); guard values.isRegularFile == true else { result(FlutterError(code: "share_file_not_found", message: "The share source is not a regular file.", details: nil)); return }
      let size = Int64(values.fileSize ?? 0); guard size >= 0 && size <= Self.maxShareFileBytes else { result(FlutterError(code: "share_file_too_large", message: "The share file exceeds the 64 MB handoff limit.", details: ["maxBytes": Self.maxShareFileBytes, "size": size])); return }
      let staged = try stageForShare(source: source, preferredFilename: args["filename"] as? String); stagedShareURL = staged; present(items: [staged], result: result)
    } catch { cleanupStagedShare(); result(FlutterError(code: "share_file_prepare_failed", message: error.localizedDescription, details: nil)) }
  }

  private func stagingDirectory() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(Self.stagingDirectoryName, isDirectory: true) }
  private func stageForShare(source: URL, preferredFilename: String?) throws -> URL {
    let root = stagingDirectory(); try createProtectedBackupExcludedDirectory(root); let session = root.appendingPathComponent(UUID().uuidString.lowercased(), isDirectory: true); try createProtectedBackupExcludedDirectory(session)
    let filename = sanitizedFilename(preferredFilename) ?? sanitizedFilename(source.lastPathComponent) ?? "quran-share.dat", destination = session.appendingPathComponent(filename, isDirectory: false)
    do { try FileManager.default.copyItem(at: source, to: destination); try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: destination.path); var values = URLResourceValues(); values.isExcludedFromBackup = true; var mutable = destination; try mutable.setResourceValues(values); let attributes = try FileManager.default.attributesOfItem(atPath: destination.path), copiedSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0; guard copiedSize >= 0 && copiedSize <= Self.maxShareFileBytes else { throw CocoaError(.fileWriteOutOfSpace) }; return destination } catch { try? FileManager.default.removeItem(at: session); throw error }
  }
  private func createProtectedBackupExcludedDirectory(_ directory: URL) throws { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true); try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: directory.path); var values = URLResourceValues(); values.isExcludedFromBackup = true; var mutable = directory; try mutable.setResourceValues(values) }
  private func cleanupOrphanedStaging(now: Date = Date()) { let root = stagingDirectory(); guard let sessions = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else { return }; let activeSession = stagedShareURL?.deletingLastPathComponent().standardizedFileURL; for session in sessions { guard session.standardizedFileURL != activeSession, let values = try? session.resourceValues(forKeys: [.contentModificationDateKey, .isDirectoryKey]), values.isDirectory == true, let modified = values.contentModificationDate, now.timeIntervalSince(modified) >= Self.orphanLifetime else { continue }; try? FileManager.default.removeItem(at: session) } }

  private func present(items: [Any], result: @escaping FlutterResult) {
    guard pendingResult == nil else { cleanupStagedShare(); result(FlutterError(code: "share_busy", message: "A share sheet is already being presented.", details: nil)); return }
    guard let presenter = activePresenter(), NativePresentationResolver.isPresentationReady(presenter) else { cleanupStagedShare(); result(FlutterError(code: "share_presenter_unavailable", message: "The active iOS scene is not ready to present a share sheet.", details: nil)); return }
    pendingResult = result; let controller = UIActivityViewController(activityItems: items, applicationActivities: nil); presentedShareController = controller
    controller.completionWithItemsHandler = { [weak self] activity, completed, _, error in guard let self else { return }; if let error { self.finish(error: FlutterError(code: "share_failed", message: error.localizedDescription, details: nil)); return }; var payload: [String: Any] = ["status": completed ? "completed" : "cancelled"]; if let activity { payload["activityType"] = activity.rawValue }; self.finish(payload) }
    if let popover = controller.popoverPresentationController { popover.sourceView = presenter.view; popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1); popover.permittedArrowDirections = [] }
    presenter.present(controller, animated: true) { [weak self, weak controller] in controller?.presentationController?.delegate = self; self?.presentedShareController = controller }
  }

  private func activePresenter() -> UIViewController? { NativePresentationResolver.activePresenter(originatingFrom: presenter) }
  private func sanitizedFilename(_ value: String?) -> String? { guard let value else { return nil }; let leaf = URL(fileURLWithPath: value).lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines); return (!leaf.isEmpty && leaf != "." && leaf != "..") ? leaf : nil }
  private func finish(_ payload: Any?) { presentedShareController = nil; guard let result = pendingResult else { cleanupStagedShare(); return }; pendingResult = nil; cleanupStagedShare(); result(payload) }
  private func finish(error: FlutterError) { presentedShareController = nil; guard let result = pendingResult else { cleanupStagedShare(); return }; pendingResult = nil; cleanupStagedShare(); result(error) }
  private func cleanupStagedShare() { if let stagedShareURL { try? FileManager.default.removeItem(at: stagedShareURL.deletingLastPathComponent()) }; stagedShareURL = nil }
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { finish(["status": "cancelled"]) }
}
