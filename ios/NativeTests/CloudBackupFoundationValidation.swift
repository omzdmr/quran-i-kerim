import Foundation

private final class FakeCloudEnvironment: CloudBackupEnvironment {
  var token: Any?
  var container: URL?
  func identityToken() -> Any? { token }
  func containerURL(identifier: String) -> URL? {
    precondition(identifier == CloudBackupFoundation.containerIdentifier)
    return container
  }
}

@main
enum CloudBackupFoundationValidation {
  static func main() throws {
    let env = FakeCloudEnvironment()
    let foundation = CloudBackupFoundation(environment: env)
    precondition(foundation.status().availability == .noAccount)
    env.token = "account-a"
    precondition(foundation.status().availability == .containerUnavailable)

    let root = FileManager.default.temporaryDirectory.appendingPathComponent("icloud-foundation-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    env.container = root
    precondition(foundation.status().availability == .available)
    env.token = "account-b"
    precondition(foundation.status().accountChanged)

    let source = root.appendingPathComponent("source.quranbackup")
    try Data("first".utf8).write(to: source)
    let files = CloudBackupFileOperator(stagingRoot: root.appendingPathComponent("staging"))
    let staged = try files.stage(source: source, filename: "backup.quranbackup")
    let stagedValues = try staged.resourceValues(forKeys: [.isExcludedFromBackupKey])
    precondition(stagedValues.isExcludedFromBackup == true)
    let destination = root.appendingPathComponent("cloud/archive.quranbackup")
    try files.atomicReplace(destination: destination, staged: staged)
    let first = try String(contentsOf: destination, encoding: .utf8)
    precondition(first == "first")
    try Data("second".utf8).write(to: source)
    let staged2 = try files.stage(source: source, filename: "backup.quranbackup")
    try files.atomicReplace(destination: destination, staged: staged2)
    let second = try String(contentsOf: destination, encoding: .utf8)
    precondition(second == "second")
    files.cleanup(staged: staged); files.cleanup(staged: staged2)
    print("CloudBackupFoundationValidation: PASS")
  }
}
