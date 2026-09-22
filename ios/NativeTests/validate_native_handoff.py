#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
app = (root / "Runner" / "AppDelegate.swift").read_text(encoding="utf-8")
share = (root / "Runner" / "NativeShareChannel.swift").read_text(encoding="utf-8")
errors = []

app_contracts = {
    'maxExportBytes: Int64 = 64': 'portable export size ceiling',
    'activeSceneAware": true': 'scene-aware Files/iCloud presentation',
    'originatingScenePreferred": true': 'originating iPad scene preference',
    'isolatedExportSession": true': 'isolated export staging',
    'orphanExportCleanup": true': 'crash-safe export cleanup',
    'presenter.viewIfLoaded?.window?.windowScene': 'originating document window resolution',
    'connectedScenes.compactMap': 'foreground scene fallback',
    'startAccessingSecurityScopedResource()': 'security-scoped import',
    'protectAndExcludeFromBackup(destination)': 'import backup exclusion',
    'removeItem(at: temporaryExportURL.deletingLastPathComponent())': 'whole export-session cleanup',
}
share_contracts = {
    'activeSceneAware": true': 'scene-aware share presentation',
    'originatingScenePreferred": true': 'originating iPad share scene preference',
    'lifecycleCleanup": true': 'share staging lifecycle cleanup',
    'presenter.viewIfLoaded?.window?.windowScene': 'originating share window resolution',
    'connectedScenes.compactMap': 'foreground scene fallback',
    'didReceiveMemoryWarningNotification': 'orphan cleanup on memory pressure',
    'willEnterForegroundNotification': 'orphan cleanup after returning',
    'presentedShareController?.dismiss': 'detach presentation cleanup',
    'removeItem(at: stagedShareURL.deletingLastPathComponent())': 'whole share-session cleanup',
}
for needle, label in app_contracts.items():
    if needle not in app: errors.append('document handoff missing ' + label)
for needle, label in share_contracts.items():
    if needle not in share: errors.append('native share missing ' + label)

if errors:
    print('\n'.join('ERROR: ' + item for item in errors), file=sys.stderr)
    raise SystemExit(1)
print('Native iPad/Files handoff contract OK')
