import Foundation

@main
struct BackupExclusionCoordinatorValidation {
  static func main() throws {
    let fileManager = FileManager.default
    guard let applicationSupport = fileManager.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first else {
      fatalError("Application Support directory is unavailable.")
    }

    let validationRootName =
      "quran-ios-backup-validation-\(UUID().uuidString)"
    let validationRoot = applicationSupport
      .appendingPathComponent(validationRootName, isDirectory: true)
    let payload = validationRoot
      .appendingPathComponent("audio/001.mp3", isDirectory: false)

    try fileManager.createDirectory(
      at: payload.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try Data("reproducible-test-payload".utf8).write(to: payload)
    defer { try? fileManager.removeItem(at: validationRoot) }

    let coordinator = BackupExclusionCoordinator(fileManager: fileManager)
    let relativePayloadPath = "\(validationRootName)/audio/001.mp3"

    let initial = try coordinator.status(
      storageArea: "applicationSupport",
      relativePath: relativePayloadPath
    )
    precondition(initial.exists, "Fixture must exist before exclusion.")

    let excluded = try coordinator.exclude(
      storageArea: "applicationSupport",
      relativePath: relativePayloadPath
    )
    precondition(excluded.exists, "Excluded payload must still exist.")
    precondition(
      excluded.isExcludedFromBackup,
      "Reproducible payload must be excluded from backup."
    )

    let missing = try coordinator.status(
      storageArea: "applicationSupport",
      relativePath: "\(validationRootName)/missing.pack"
    )
    precondition(!missing.exists, "Missing content must remain distinguishable.")
    precondition(
      !missing.isExcludedFromBackup,
      "Missing content must not report a synthetic exclusion state."
    )

    assertRejected(
      coordinator: coordinator,
      storageArea: "applicationSupport",
      relativePath: "../Documents/private.sqlite"
    )
    assertRejected(
      coordinator: coordinator,
      storageArea: "applicationSupport",
      relativePath: payload.path
    )
    assertRejected(
      coordinator: coordinator,
      storageArea: "unknown",
      relativePath: relativePayloadPath
    )

    print("Backup exclusion validation passed.")
  }

  private static func assertRejected(
    coordinator: BackupExclusionCoordinator,
    storageArea: String,
    relativePath: String
  ) {
    do {
      _ = try coordinator.status(
        storageArea: storageArea,
        relativePath: relativePath
      )
      preconditionFailure(
        "Unsafe backup path unexpectedly passed validation: \(relativePath)"
      )
    } catch {
      // Expected: invalid paths and storage areas fail closed.
    }
  }
}
