#!/usr/bin/env python3
from pathlib import Path
source = Path("ios/Runner/NativeLifecycleStateChannel.swift").read_text()
required = {
    "scene snapshot": "sceneActivitySnapshot()",
    "foreground scene count": '"foregroundSceneCount"',
    "connected scene count": '"connectedSceneCount"',
    "background guard": "guard scenes.foregroundCount == 0",
    "non-global background event": 'self.emit("sceneBackgrounded"',
    "capability": '"multiSceneAwareBackground": true',
}
missing = [f"{name}: {needle}" for name, needle in required.items() if needle not in source]
if missing:
    raise SystemExit("Multi-scene lifecycle validation failed:\n- " + "\n- ".join(missing))
print("Multi-scene lifecycle validation passed")
