#!/usr/bin/env python3
from pathlib import Path

source = Path("ios/Runner/NativeLifecycleStateChannel.swift").read_text()
required = {
    "ack state": "private var restoreAcknowledged = false",
    "ack method": 'case "acknowledgeRestore"',
    "ack mutation": "restoreAcknowledged = true",
    "stale marker cleanup": "defaults.removeObject(forKey: Key.lastBackgroundAt)",
    "eviction one-shot gate": "!restoreAcknowledged && hadPreviousSession",
    "snapshot diagnostic": '"restoreAcknowledged": restoreAcknowledged',
    "capability": '"restoreAcknowledgement": true',
}
missing = [f"{name}: {needle}" for name, needle in required.items() if needle not in source]
if missing:
    raise SystemExit("Lifecycle restore acknowledgement validation failed:\n- " + "\n- ".join(missing))
print("Lifecycle restore acknowledgement validation passed")
