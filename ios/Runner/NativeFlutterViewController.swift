import Flutter
import UIKit

/// Opt-in hardware-keyboard bridge for iPad. Commands stay disabled until shared UI explicitly
/// adopts the contract, so native parity never steals shortcuts from text fields prematurely.
final class NativeFlutterViewController: FlutterViewController, UIPencilInteractionDelegate {
  static let keyboardChannelName = "app.quranikerim/native_keyboard"
  private var keyboardChannel: FlutterMethodChannel?
  private var pencilChannel: FlutterMethodChannel?
  private var pencilInteraction: UIPencilInteraction?
  private var keyboardBridgeEnabled = false
  private var pencilBridgeEnabled = false

  override func viewDidLoad() {
    super.viewDidLoad()
    let channel = FlutterMethodChannel(name: Self.keyboardChannelName, binaryMessenger: binaryMessenger)
    keyboardChannel = channel
    configurePencilBridge()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "capabilities":
        result([
          "hardwareKeyboard": true,
          "optIn": true,
          "searchShortcut": "command+f",
          "tabShortcuts": "command+1...5",
          "commandCount": 6
        ])
      case "setEnabled":
        guard let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool else {
          result(FlutterError(code: "invalid_keyboard_state", message: "setEnabled requires an enabled boolean.", details: nil))
          return
        }
        keyboardBridgeEnabled = enabled
        setNeedsUpdateOfKeyCommands()
        result(["enabled": enabled])
      case "status":
        result(["enabled": keyboardBridgeEnabled])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func configurePencilBridge() {
    let channel = FlutterMethodChannel(name: "app.quranikerim/native_pencil", binaryMessenger: binaryMessenger)
    pencilChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "capabilities":
        result(["applePencil": true, "doubleTap": true, "squeeze": false, "optIn": true, "anchoredNotesOwnedByShared": true])
      case "setEnabled":
        guard let args = call.arguments as? [String: Any], let enabled = args["enabled"] as? Bool else {
          result(FlutterError(code: "invalid_pencil_state", message: "setEnabled requires an enabled boolean.", details: nil))
          return
        }
        pencilBridgeEnabled = enabled
        result(["enabled": enabled])
      case "status":
        result(["enabled": pencilBridgeEnabled])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    let interaction = UIPencilInteraction()
    interaction.delegate = self
    view.addInteraction(interaction)
    pencilInteraction = interaction
  }

  func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
    guard pencilBridgeEnabled else { return }
    pencilChannel?.invokeMethod("gesture", arguments: ["action": "doubleTap"])
  }

  deinit {
    keyboardChannel?.setMethodCallHandler(nil)
    pencilChannel?.setMethodCallHandler(nil)
  }

  override var keyCommands: [UIKeyCommand]? {
    guard keyboardBridgeEnabled else { return [] }
    var commands: [UIKeyCommand] = [
      UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(handleSearchShortcut))
    ]
    for index in 1...5 {
      commands.append(UIKeyCommand(input: String(index), modifierFlags: .command, action: #selector(handleTabShortcut(_:))))
    }
    return commands
  }

  @objc private func handleSearchShortcut() {
    keyboardChannel?.invokeMethod("command", arguments: ["action": "search"])
  }

  @objc private func handleTabShortcut(_ command: UIKeyCommand) {
    guard let input = command.input, let number = Int(input), (1...5).contains(number) else { return }
    keyboardChannel?.invokeMethod("command", arguments: ["action": "selectTab", "index": number - 1])
  }
}
