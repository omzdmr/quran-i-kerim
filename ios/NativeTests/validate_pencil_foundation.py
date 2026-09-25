from pathlib import Path
source = Path("ios/Runner/NativeFlutterViewController.swift").read_text()
required = [
    "UIPencilInteractionDelegate",
    'app.quranikerim/native_pencil',
    "let interaction = UIPencilInteraction()",
    "interaction.delegate = self",
    "view.addInteraction(interaction)",
    "pencilInteractionDidTap",
    "guard pencilBridgeEnabled else { return }",
    '"action": "doubleTap"',
    '"anchoredNotesOwnedByShared": true',
    '"squeeze": false',
]
missing = [item for item in required if item not in source]
if missing: raise SystemExit("Apple Pencil foundation contract failed: " + ", ".join(missing))
print("Apple Pencil opt-in foundation contract OK")
