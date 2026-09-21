import Flutter
import Foundation

/// Buffers native URL/universal-link ingress until Flutter is ready, avoiding cold-start loss.
/// Routing semantics remain owned by the shared layer.
final class DeepLinkChannel {
  static let channelName = "app.quranikerim/native_deep_link"

  private let channel: FlutterMethodChannel
  private var pending: [String] = []
  private let maxPending = 8

  init(binaryMessenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }

  func receive(_ url: URL) {
    guard let normalized = normalizedURLString(url) else { return }
    if pending.last != normalized {
      pending.append(normalized)
      if pending.count > maxPending { pending.removeFirst(pending.count - maxPending) }
    }
    channel.invokeMethod("linkReceived", arguments: ["url": normalized])
  }

  func detach() {
    channel.setMethodCallHandler(nil)
    pending.removeAll()
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities": result(["customScheme": true, "universalLink": true, "coldStartBuffer": true, "maxPending": maxPending])
    case "pendingLinks": result(pending)
    case "consumePendingLinks":
      let links = pending; pending.removeAll(); result(links)
    case "clearPendingLinks": pending.removeAll(); result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func normalizedURLString(_ url: URL) -> String? {
    guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" || scheme == "quranikerim" else { return nil }
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    components.scheme = scheme
    components.host = components.host?.lowercased()
    return components.url?.absoluteString
  }
}
