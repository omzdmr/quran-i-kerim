from pathlib import Path
runner = Path("ios/Runner/CloudBackupFoundation.swift").read_text()
channel = Path("ios/Runner/CloudBackupFoundationChannel.swift").read_text()
entitlements = Path("ios/Runner/Runner.entitlements").read_text()
handoff = Path("ios/NATIVE_PARITY_HANDOFF.md").read_text()
required_runner = ["ubiquityIdentityToken", "url(forUbiquityContainerIdentifier:", "completeUntilFirstUserAuthentication", "isExcludedFromBackup = true", "replaceItemAt", "containerUnavailable"]
required_channel = ['foundationOnly": true', '"finalProvider": false', "NSUbiquityIdentityDidChange", '"statusChanged"', '"accountChangeEvents": true']
required_entitlements = ["com.apple.developer.icloud-container-identifiers", "com.apple.developer.ubiquity-container-identifiers", "CloudDocuments", "iCloud.com.omzdmr.quranIKerim"]
missing = [f"runner:{x}" for x in required_runner if x not in runner]
missing += [f"channel:{x}" for x in required_channel if x not in channel]
missing += [f"entitlement:{x}" for x in required_entitlements if x not in entitlements]
if "not the final iCloud provider" not in handoff:
    missing.append("handoff:final-provider guard")
if missing:
    raise SystemExit("iCloud foundation contract missing: " + ", ".join(missing))
print("iCloud foundation contract: PASS")
