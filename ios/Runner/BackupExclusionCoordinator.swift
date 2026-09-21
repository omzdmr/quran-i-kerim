import Foundation

/// Applies Apple's "do not back up" resource flag to reproducible content.
///
/// The shared download layer chooses which payload is reproducible. This native
/// boundary only accepts a relative path inside a known application container
/// directory, preventing accidental access outside the app sandbox.
final class BackupExclusionCoordinator {
  enum StorageArea: String {
    case applicationSupport
    case documents
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

    var dictionary: [String: Any] {
      [
        "exists": exists,
        "isExcludedFromBackup": isExcludedFromBackup,
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
    let url = try resolvedURL(
      storageArea: rawStorageArea,
      relativePath: relativePath
    )
    guard fileManager.fileExists(atPath: url.path) else {
      throw ExclusionError.itemDoesNotExist
    }

    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    var mutableURL = url
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
    let url = try resolvedURL(
      storageArea: rawStorageArea,
      relativePath: relativePath
    )
    let exists = fileManager.fileExists(atPath: url.path)
    guard exists else {
      return Status(exists: false, isExcludedFromBackup: false)
    }

    let values = try url.resourceValues(
      forKeys: [.isExcludedFromBackupKey]
    )
    return Status(
      exists: true,
      isExcludedFromBackup: values.isExcludedFromBackup ?? false
    )
  }

  private func resolvedURL(
    storageArea rawStorageArea: String,
    relativePath: String
  ) throws -> URL {
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
    return candidate
  }

  private func baseURL(for storageArea: StorageArea) -> URL? {
    let directory: FileManager.SearchPathDirectory
    switch storageArea {
    case .applicationSupport:
      directory = .applicationSupportDirectory
    case .documents:
      directory = .documentDirectory
    case .caches:
      directory = .cachesDirectory
    }

    return fileManager.urls(
      for: directory,
      in: .userDomainMask
    ).first
  }
}
