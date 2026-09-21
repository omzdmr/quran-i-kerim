import Foundation

/// Applies Apple's "do not back up" resource flag to reproducible content.
///
/// Only Application Support and Caches are accepted. Documents is deliberately
/// excluded from this native boundary because it is the natural home for
/// user-created/exported data; a shared-layer mistake must not silently remove
/// that data from iCloud/device backups.
final class BackupExclusionCoordinator {
  enum StorageArea: String {
    case applicationSupport
    case caches
  }

  enum ExclusionError: LocalizedError {
    case unsupportedStorageArea(String)
    case invalidRelativePath
    case baseDirectoryUnavailable(StorageArea)
    case itemDoesNotExist

    var errorDescription: String? {
      switch self {
      case .unsupportedStorageArea(let area):
        return "Unsupported storage area: \(area)"
      case .invalidRelativePath:
        return "A non-empty relative path inside the selected storage area is required."
      case .baseDirectoryUnavailable(let area):
        return "The \(area.rawValue) directory is unavailable."
      case .itemDoesNotExist:
        return "The requested item does not exist."
      }
    }
  }

  struct Status {
    let exists: Bool
    let isExcludedFromBackup: Bool
    let storageArea: StorageArea

    var dictionary: [String: Any] {
      [
        "exists": exists,
        "isExcludedFromBackup": isExcludedFromBackup,
        "storageArea": storageArea.rawValue,
      ]
    }
  }

  private let fileManager: FileManager

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
  }

  @discardableResult
  func exclude(
    storageArea rawStorageArea: String,
    relativePath: String
  ) throws -> Status {
    let resolved = try resolvedURL(
      storageArea: rawStorageArea,
      relativePath: relativePath
    )
    guard fileManager.fileExists(atPath: resolved.url.path) else {
      throw ExclusionError.itemDoesNotExist
    }

    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    var mutableURL = resolved.url
    try mutableURL.setResourceValues(values)

    return try status(
      storageArea: rawStorageArea,
      relativePath: relativePath
    )
  }

  func status(
    storageArea rawStorageArea: String,
    relativePath: String
  ) throws -> Status {
    let resolved = try resolvedURL(
      storageArea: rawStorageArea,
      relativePath: relativePath
    )
    let exists = fileManager.fileExists(atPath: resolved.url.path)
    guard exists else {
      return Status(
        exists: false,
        isExcludedFromBackup: false,
        storageArea: resolved.storageArea
      )
    }

    let values = try resolved.url.resourceValues(
      forKeys: [.isExcludedFromBackupKey]
    )
    return Status(
      exists: true,
      isExcludedFromBackup: values.isExcludedFromBackup ?? false,
      storageArea: resolved.storageArea
    )
  }

  private func resolvedURL(
    storageArea rawStorageArea: String,
    relativePath: String
  ) throws -> (url: URL, storageArea: StorageArea) {
    guard let storageArea = StorageArea(rawValue: rawStorageArea) else {
      throw ExclusionError.unsupportedStorageArea(rawStorageArea)
    }

    let trimmedPath = relativePath.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    let pathComponents = NSString(string: trimmedPath).pathComponents
    guard
      !trimmedPath.isEmpty,
      !NSString(string: trimmedPath).isAbsolutePath,
      !pathComponents.contains(".."),
      !pathComponents.contains(".")
    else {
      throw ExclusionError.invalidRelativePath
    }

    guard let baseURL = baseURL(for: storageArea) else {
      throw ExclusionError.baseDirectoryUnavailable(storageArea)
    }

    let resolvedBase = baseURL.standardizedFileURL.resolvingSymlinksInPath()
    let candidate = resolvedBase
      .appendingPathComponent(trimmedPath)
      .standardizedFileURL
      .resolvingSymlinksInPath()
    let basePrefix = resolvedBase.path.hasSuffix("/")
      ? resolvedBase.path
      : resolvedBase.path + "/"

    // Resolve symlinks before the containment check. A symlink stored inside the
    // app container must not turn a seemingly safe relative path into access to
    // another location.
    guard candidate.path.hasPrefix(basePrefix) else {
      throw ExclusionError.invalidRelativePath
    }
    return (candidate, storageArea)
  }

  private func baseURL(for storageArea: StorageArea) -> URL? {
    let directory: FileManager.SearchPathDirectory
    switch storageArea {
    case .applicationSupport:
      directory = .applicationSupportDirectory
    case .caches:
      directory = .cachesDirectory
    }

    return fileManager.urls(
      for: directory,
      in: .userDomainMask
    ).first
  }
}
