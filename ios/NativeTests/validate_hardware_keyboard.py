from pathlib import Path
source = Path("ios/Runner/NativeFlutterViewController.swift").read_text()
storyboard = Path("ios/Runner/Base.lproj/Main.storyboard").read_text()
project = Path("ios/Runner.xcodeproj/project.pbxproj").read_text()
required = ['app.quranikerim/native_keyboard','guard keyboardBridgeEnabled else { return [] }','case "setEnabled"','UIKeyCommand(input: "f", modifierFlags: .command','for index in 1...5','"action": "search"','"action": "selectTab"','"index": number - 1']
missing = [item for item in required if item not in source]
if 'customClass="NativeFlutterViewController"' not in storyboard: missing.append("storyboard controller")
if 'NativeFlutterViewController.swift in Sources' not in project: missing.append("Xcode source membership")
if missing: raise SystemExit("Hardware keyboard contract failed: " + ", ".join(missing))
print("Hardware keyboard opt-in contract OK")
