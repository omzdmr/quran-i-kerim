import Flutter
import UIKit

final class NativeShareChannel: NSObject, UIAdaptivePresentationControllerDelegate {
  static let channelName = "app.quranikerim/native_share"
  private let channel: FlutterMethodChannel
  private weak var presenter: UIViewController?
  private var pendingResult: FlutterResult?

  init(binaryMessenger: FlutterBinaryMessenger, presenter: UIViewController) { channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger); self.presenter = presenter; super.init(); channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) } }
  func detach() { if let pendingResult { pendingResult(["status": "dismissed"]) }; pendingResult = nil; channel.setMethodCallHandler(nil) }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities": result(["text": true, "file": true, "ipadPopoverSafe": true, "completionStatus": true, "presentedHierarchyAware": true])
    case "shareText":
      guard let args = call.arguments as? [String: Any], let text = args["text"] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { result(FlutterError(code: "invalid_share_text", message: "shareText requires non-empty text.", details: nil)); return }
      present(items: [text], result: result)
    case "shareFile":
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String, !path.isEmpty else { result(FlutterError(code: "invalid_share_file", message: "shareFile requires a file path.", details: nil)); return }
      let url = URL(fileURLWithPath: path).standardizedFileURL
      guard FileManager.default.fileExists(atPath: url.path), !url.hasDirectoryPath else { result(FlutterError(code: "share_file_not_found", message: "The share file does not exist.", details: nil)); return }
      present(items: [url], result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func present(items: [Any], result: @escaping FlutterResult) {
    guard pendingResult == nil else { result(FlutterError(code: "share_busy", message: "A share sheet is already being presented.", details: nil)); return }
    guard let root = presenter, let presenter = topPresenter(from: root), presenter.viewIfLoaded?.window != nil, !presenter.isBeingDismissed else { result(FlutterError(code: "share_presenter_unavailable", message: "The active iOS scene is not ready to present a share sheet.", details: nil)); return }
    pendingResult = result
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.completionWithItemsHandler = { [weak self] activity, completed, _, error in
      guard let self else { return }; let callback = self.pendingResult; self.pendingResult = nil
      if let error { callback?(FlutterError(code: "share_failed", message: error.localizedDescription, details: nil)) }
      else { var payload: [String: Any] = ["status": completed ? "completed" : "cancelled"]; if let activity { payload["activityType"] = activity.rawValue }; callback?(payload) }
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

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { guard let result = pendingResult else { return }; pendingResult = nil; result(["status": "cancelled"]) }
}
