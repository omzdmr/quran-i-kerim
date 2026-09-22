#!/usr/bin/env python3
from pathlib import Path

source = Path("ios/Runner/AppDelegate.swift").read_text()
required = {
    "64 MiB import cap": "maxImportBytes: Int64 = 64 * 1024 * 1024",
    "64 MiB export cap": "maxExportBytes: Int64 = 64 * 1024 * 1024",
    "copy-on-import picker": "UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)",
    "copy-on-export picker": "UIDocumentPickerViewController(forExporting: [staged], asCopy: true)",
    "security scoped import": "startAccessingSecurityScopedResource()",
    "protected staging": "FileProtectionType.completeUntilFirstUserAuthentication",
    "backup exclusion": "values.isExcludedFromBackup = true",
    "post-copy export size": "exportTooLargeAfterCopy",
    "post-copy capability": '"postCopySizeValidation": true',
    "explicit imported-file cleanup": 'case "deleteImportedFile"',
    "active scene": "foregroundActive",
}
missing = [f"{name}: {needle}" for name, needle in required.items() if needle not in source]
if missing:
    raise SystemExit("Document handoff validation failed:\n- " + "\n- ".join(missing))
print("Document handoff validation passed")
