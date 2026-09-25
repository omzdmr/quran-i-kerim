import Foundation

enum CloudBackupAvailability: String { case available, noAccount, containerUnavailable }

struct CloudBackupStatus {
  let availability: CloudBackupAvailability
  let accountChanged: Bool
  let containerIdentifier: String
  let containerURL: URL?
  var dictionary: [String: Any] {
    var value: [String: Any] = ["availability": availability.rawValue, "accountChanged": accountChanged, "containerIdentifier": containerIdentifier]
    if let containerURL { value["containerPath"] = containerURL.path }
    return value
  }
}

protocol CloudBackupEnvironment {
  func identityToken() -> Any?
  func containerURL(identifier: String) -> URL?
}

struct SystemCloudBackupEnvironment: CloudBackupEnvironment {
  func identityToken() -> Any? { FileManager.default.ubiquityIdentityToken }
  func containerURL(identifier: String) -> URL? { FileManager.default.url(forUbiquityContainerIdentifier: identifier) }
}

final class CloudBackupFoundation {
  static let containerIdentifier = "iCloud.com.omzdmr.quranIKerim"
  private let environment: CloudBackupEnvironment
  private var lastIdentity: String?

  init(environment: CloudBackupEnvironment = SystemCloudBackupEnvironment()) { self.environment = environment }

  func status() -> CloudBackupStatus {
    guard let token = environment.identityToken() else {
      lastIdentity = nil
      return .init(availability: .noAccount, accountChanged: false, containerIdentifier: Self.containerIdentifier, containerURL: nil)
    }
    let identity = String(describing: token)
    let changed = lastIdentity != nil && lastIdentity != identity
    lastIdentity = identity
    guard let url = environment.containerURL(identifier: Self.containerIdentifier) else {
      return .init(availability: .containerUnavailable, accountChanged: changed, containerIdentifier: Self.containerIdentifier, containerURL: nil)
    }
    return .init(availability: .available, accountChanged: changed, containerIdentifier: Self.containerIdentifier, containerURL: url)
  }
}

final class CloudBackupFileOperator {
  enum FileError: Error { case sourceMissing, sourceNotRegular, invalidFilename }
  private let fm: FileManager
  private let stagingRoot: URL

  init(fileManager: FileManager = .default, stagingRoot: URL? = nil) {
    fm = fileManager
    self.stagingRoot = stagingRoot ?? fileManager.temporaryDirectory.appendingPathComponent("quran-icloud-staging", isDirectory: true)
  }

  func stage(source: URL, filename: String) throws -> URL {
    let source = source.standardizedFileURL
    guard fm.fileExists(atPath: source.path) else { throw FileError.sourceMissing }
    guard try source.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { throw FileError.sourceNotRegular }
    let leaf = URL(fileURLWithPath: filename).lastPathComponent
    guard !filename.isEmpty, leaf == filename, leaf != ".", leaf != ".." else { throw FileError.invalidFilename }
    try fm.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
    try protect(stagingRoot)
    let session = stagingRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try fm.createDirectory(at: session, withIntermediateDirectories: true)
    try protect(session)
    let destination = session.appendingPathComponent(leaf)
    do {
      try fm.copyItem(at: source, to: destination)
      try protect(destination)
      return destination
    } catch {
      try? fm.removeItem(at: session)
      throw error
    }
  }

  func atomicReplace(destination: URL, staged: URL) throws {
    let parent = destination.deletingLastPathComponent()
    try fm.createDirectory(at: parent, withIntermediateDirectories: true)
    let replacement = parent.appendingPathComponent(".replace-\(UUID().uuidString)")
    try fm.copyItem(at: staged, to: replacement)

    var coordinationError: NSError?
    var operationError: Error?
    let coordinator = NSFileCoordinator(filePresenter: nil)
    coordinator.coordinate(writingItemAt: destination, options: .forReplacing, error: &coordinationError) { coordinatedURL in
      do {
        if fm.fileExists(atPath: coordinatedURL.path) { _ = try fm.replaceItemAt(coordinatedURL, withItemAt: replacement) }
        else { try fm.moveItem(at: replacement, to: coordinatedURL) }
      } catch {
        operationError = error
      }
    }
    if let operationError {
      try? fm.removeItem(at: replacement)
      throw operationError
    }
    if let coordinationError {
      try? fm.removeItem(at: replacement)
      throw coordinationError
    }
  }

  func cleanup(staged: URL) {
    let root = stagingRoot.standardizedFileURL.path + "/"
    guard staged.standardizedFileURL.path.hasPrefix(root) else { return }
    try? fm.removeItem(at: staged.deletingLastPathComponent())
  }

  private func protect(_ url: URL) throws {
    try fm.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: url.path)
    var values = URLResourceValues(); values.isExcludedFromBackup = true
    var mutable = url; try mutable.setResourceValues(values)
  }
}
