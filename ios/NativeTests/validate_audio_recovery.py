from pathlib import Path
coordinator = Path("ios/Runner/AudioSessionCoordinator.swift").read_text()
channel = Path("ios/Runner/BackupExclusionChannel.swift").read_text()
required = [
    (coordinator, "reason == .oldDeviceUnavailable"),
    (coordinator, "mediaServicesResetNotification"),
    (coordinator, '["configured": configured]'),
    (channel, '"shouldPause"'),
    (channel, '"mediaServicesReset"'),
    (channel, '"republishNowPlaying": true'),
]
missing = [needle for text, needle in required if needle not in text]
if missing:
    raise SystemExit("audio recovery contract missing: " + ", ".join(missing))
print("audio recovery contract: PASS")
