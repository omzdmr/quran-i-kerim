from pathlib import Path

source = Path("ios/Runner/BackupExclusionChannel.swift").read_text()
assert 'case "getNotificationDiagnostics"' in source
assert 'getPendingNotificationRequests' in source
assert 'getDeliveredNotifications' in source
assert 'pendingRequestCount' in source
assert 'deliveredNotificationCount' in source
assert 'pendingNonSelfTestRequestCount' in source
assert 'selfTestPending' in source
assert 'request.identifier != Self.selfTestIdentifier' in source
assert 'case "openNotificationSettings"' in source
assert 'UIApplication.openNotificationSettingsURLString' in source
assert 'UIApplication.openSettingsURLString' in source
assert 'payload["canDeliver"]' in source
print("notification diagnostics contract OK")
