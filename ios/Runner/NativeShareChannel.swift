import Flutter
import UIKit

/// Native share sheet boundary with iPad-safe popover presentation.
/// The shared layer provides already-rendered text or a sandbox file URL; iOS owns only presentation.
final class NativeShareChannel: NSObject, UIAdaptivePresentationControllerDelegate {
  static let channelName = "app.quranikerim/native_share"

  private let channel: FlutterMethodChannel
  private weak var presenter: UIViewController?
  private var pendingResult: FlutterResult?

  init(binaryMessenger: FlutterBinaryMessenger, presenter: UIViewController) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    self.presenter = presenter
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }

  func detach() {
    if let pendingResult { pendingResult(["status": "dismissed"]) }
    pendingResult = nil
    channel.setMethodCallHandler(nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities": result(["text": true, "file": true, "ipadPopoverSafe": true, "completionStatus": true])
    case "shareText":
      guard let args = call.arguments as? [String: Any], let text = args["text"] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        result(FlutterError(code: "invalid_share_text", message: "shareText requires non-empty text.", details: nil)); return
      }
      present(items: [text], result: result)
    case "shareFile":
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String, !path.isEmpty else {
        result(FlutterError(code: "invalid_share_file", message: "shareFile requires a file path.", details: nil)); return
      }
      let url = URL(fileURLWithPath: path).standardizedFileURL
      guard FileManager.default.fileExists(atPath: url.path), !url.hasDirectoryPath else {
        result(FlutterError(code: "share_file_not_found", message: "The share file does not exist.", details: nil)); return
      }
      present(items: [url], result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func present(items: [Any], result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "share_busy", message: "A share sheet is already being presented.", details: nil)); return
    }
    guard let presenter, presenter.presentedViewController == nil else {
      result(FlutterError(code: "share_presenter_unavailable", message: "The app is not ready to present a share sheet.", details: nil)); return
    }
    pendingResult = result
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.presentationController?.delegate = self
    controller.completionWithItemsHandler = { [weak self] activity, completed, _, error in
      guard let self else { return }
      let callback = self.pendingResult
      self.pendingResult = nil
      if let error {
        callback?(FlutterError(code: "share_failed", message: error.localizedDescription, details: nil))
      } else {
        callback?(["status": completed ? "completed" : "cancelled", "activityType": activity?.rawValue as Any])
      }
    }
    if let popover = controller.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
      popover.permittedArrowDirections = []
    }
    presenter.present(controller, animated: true)
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    result(["status": "cancelled"])
  }
}
