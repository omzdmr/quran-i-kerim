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
    guard let caches = fileManager.urls(
      for: .cachesDirectory,
      in: .userDomainMask
    ).first else {
      fatalError("Caches directory is unavailable.")
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
    precondition(
      initial.storageArea == .applicationSupport,
      "Status must preserve the validated storage area."
    )

    let excluded = try coordinator.exclude(
      storageArea: "applicationSupport",
      relativePath: relativePayloadPath
    )
    precondition(excluded.exists, "Excluded payload must still exist.")
    precondition(
      excluded.isExcludedFromBackup,
      "Reproducible payload must be excluded from backup."
    )

    // Cache payloads are reproducible by definition and are safe to mark as
    // excluded. Validate the second allow-listed storage root end to end.
    let cacheRootName = "quran-ios-cache-validation-\(UUID().uuidString)"
    let cacheRoot = caches.appendingPathComponent(cacheRootName, isDirectory: true)
    let cachePayload = cacheRoot.appendingPathComponent("pack.bin")
    try fileManager.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
    try Data("cache-payload".utf8).write(to: cachePayload)
    defer { try? fileManager.removeItem(at: cacheRoot) }

    let excludedCache = try coordinator.exclude(
      storageArea: "caches",
      relativePath: "\(cacheRootName)/pack.bin"
    )
    precondition(excludedCache.exists, "Cache fixture must exist.")
    precondition(
      excludedCache.isExcludedFromBackup,
      "Reproducible cache payload must be excluded from backup."
    )
    precondition(
      excludedCache.storageArea == .caches,
      "Cache status must report the validated storage area."
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

    // Documents can contain notes, recordings, exports and other user-created
    // data. Even a valid-looking relative path must fail closed here so a shared
    // layer bug cannot silently remove user data from device/iCloud backups.
    assertRejected(
      coordinator: coordinator,
      storageArea: "documents",
      relativePath: "notes/user-note.json"
    )

    let externalRoot = fileManager.temporaryDirectory
      .appendingPathComponent(
        "quran-ios-backup-external-\(UUID().uuidString)",
        isDirectory: true
      )
    try fileManager.createDirectory(
      at: externalRoot,
      withIntermediateDirectories: true
    )
    defer { try? fileManager.removeItem(at: externalRoot) }
    let symlink = validationRoot.appendingPathComponent("escape")
    try fileManager.createSymbolicLink(
      at: symlink,
      withDestinationURL: externalRoot
    )
    assertRejected(
      coordinator: coordinator,
      storageArea: "applicationSupport",
      relativePath: "\(validationRootName)/escape"
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
