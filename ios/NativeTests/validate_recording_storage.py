#!/usr/bin/env python3
from pathlib import Path

source = Path("ios/Runner/MicrophoneRecordingChannel.swift").read_text()
required = {
    "protected directory": "FileProtectionType.completeUntilFirstUserAuthentication",
    "protection is not best-effort": "try FileManager.default.setAttributes",
    "failed-start candidate": "var pendingURL: URL?",
    "failed-start cleanup": "FileManager.default.removeItem(at: pendingURL)",
    "audio policy restore": "AudioSessionCoordinator.shared.configurePolicy()",
    "input identity": "activeInputUID",
    "input change stop": 'payload["reason"] = "inputChanged"',
    "user delete boundary": "recording_is_active",
}
missing = [f"{name}: {needle}" for name, needle in required.items() if needle not in source]
if missing:
    raise SystemExit("Recitation recording storage validation failed:\n- " + "\n- ".join(missing))
print("Recitation recording storage validation passed")
