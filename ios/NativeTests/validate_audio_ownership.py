#!/usr/bin/env python3
from pathlib import Path
source = Path("ios/Runner/AudioSessionCoordinator.swift").read_text()
required = {
    "service ownership marker": "MPNowPlayingInfoPropertyServiceIdentifier",
    "service identity guard": "Self.serviceIdentifier && dictionariesEqual",
    "ownership snapshot": "previousInfo = infoCenter.nowPlayingInfo",
    "published identity": "lastPublishedInfo = info",
    "external replacement guard": "dictionariesEqual(infoCenter.nowPlayingInfo, lastPublishedInfo)",
    "prior metadata restore": "infoCenter.nowPlayingInfo = previousInfo",
    "prior command state": "previousCommandStates",
    "prior playback state": "previousPlaybackState",
    "target cleanup": "removeCommandTargets()",
}
missing = [f"{name}: {needle}" for name, needle in required.items() if needle not in source]
if missing:
    raise SystemExit("Now Playing ownership validation failed:\n- " + "\n- ".join(missing))
if "infoCenter.nowPlayingInfo = nil; disablePlaybackCommands()" in source:
    raise SystemExit("Now Playing clear still destructively resets process-global MediaPlayer state")
print("Now Playing ownership validation passed")
