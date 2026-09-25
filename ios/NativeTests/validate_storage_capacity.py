#!/usr/bin/env python3
from pathlib import Path
source = Path("ios/Runner/AppDelegate.swift").read_text()
required = {
    "channel": 'app.quranikerim/native_storage_capacity',
    "important capacity": 'volumeAvailableCapacityForImportantUsageKey',
    "opportunistic capacity": 'volumeAvailableCapacityForOpportunisticUsageKey',
    "total capacity": 'volumeTotalCapacityKey',
    "shared policy ownership": '"policyOwnedByShared": true',
    "registration": 'StorageCapacityChannel(binaryMessenger: messenger)',
    "cleanup": 'storageCapacityChannel?.detach()',
}
missing = [f"{name}: {needle}" for name, needle in required.items() if needle not in source]
if missing:
    raise SystemExit("Storage capacity contract failed:\n- " + "\n- ".join(missing))
print("Storage capacity contract passed")
