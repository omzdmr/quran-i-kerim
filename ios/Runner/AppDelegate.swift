import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let audioSessionCoordinator = AudioSessionCoordinator.shared
  private var backupExclusionChannel: BackupExclusionChannel?
  private var nowPlayingChannel: NowPlayingChannel?
  private var audioLifecycleChannel: AudioLifecycleChannel?
  private var notificationPermissionChannel: NotificationPermissionChannel?
  private var locationHeadingChannel: LocationHeadingChannel?
  private var documentHandoffChannel: DocumentHandoffChannel?
  private var widgetSnapshotChannel: WidgetSnapshotChannel?
  private var nativeLifecycleStateChannel: NativeLifecycleStateChannel?
  private var microphoneRecordingChannel: MicrophoneRecordingChannel?
  private var nativeShareChannel: NativeShareChannel?
  private var deepLinkChannel: DeepLinkChannel?

  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    audioSessionCoordinator.start()
    GeneratedPluginRegistrant.register(with: self)
    configureNativeChannels()
    if let url = launchOptions?[.url] as? URL { deepLinkChannel?.receive(url) }
    if let activities = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any] {
      for value in activities.values {
        if let activity = value as? NSUserActivity, activity.activityType == NSUserActivityTypeBrowsingWeb, let url = activity.webpageURL { deepLinkChannel?.receive(url) }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    let nativeHandled = deepLinkChannel?.receive(url) ?? false
    return super.application(app, open: url, options: options) || nativeHandled
  }

  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    let nativeHandled = userActivity.activityType == NSUserActivityTypeBrowsingWeb && userActivity.webpageURL.map { deepLinkChannel?.receive($0) ?? false } == true
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler) || nativeHandled
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    deepLinkChannel?.detach()
    nativeShareChannel?.detach()
    microphoneRecordingChannel?.detach()
    nativeLifecycleStateChannel?.markCleanTermination()
    nativeLifecycleStateChannel?.detach()
    widgetSnapshotChannel?.detach()
    documentHandoffChannel?.detach()
    locationHeadingChannel?.detach()
    notificationPermissionChannel?.detach()
    audioLifecycleChannel?.detach()
    nowPlayingChannel?.detach()
    backupExclusionChannel?.detach()
    audioSessionCoordinator.stop()
    super.applicationWillTerminate(application)
  }

  private func configureNativeChannels() {
    guard let controller = window?.rootViewController as? FlutterViewController else { NSLog("Unable to install native channels: Flutter view controller unavailable."); return }
    let messenger = controller.binaryMessenger
    backupExclusionChannel = BackupExclusionChannel(binaryMessenger: messenger)
    nowPlayingChannel = NowPlayingChannel(binaryMessenger: messenger)
    audioLifecycleChannel = AudioLifecycleChannel(binaryMessenger: messenger)
    notificationPermissionChannel = NotificationPermissionChannel(binaryMessenger: messenger)
    locationHeadingChannel = LocationHeadingChannel(binaryMessenger: messenger)
    documentHandoffChannel = DocumentHandoffChannel(binaryMessenger: messenger, presenter: controller)
    widgetSnapshotChannel = WidgetSnapshotChannel(binaryMessenger: messenger)
    nativeLifecycleStateChannel = NativeLifecycleStateChannel(binaryMessenger: messenger)
    microphoneRecordingChannel = MicrophoneRecordingChannel(binaryMessenger: messenger)
    nativeShareChannel = NativeShareChannel(binaryMessenger: messenger, presenter: controller)
    deepLinkChannel = DeepLinkChannel(binaryMessenger: messenger)
  }
}

final class DocumentHandoffChannel: NSObject, UIDocumentPickerDelegate {
  private static let channelName = "app.quranikerim/native_document_handoff"
  private let channel: FlutterMethodChannel
  private weak var presenter: UIViewController?
  private var pendingResult: FlutterResult?
  private var temporaryExportURL: URL?

  init(binaryMessenger: FlutterBinaryMessenger, presenter: UIViewController) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger)
    self.presenter = presenter
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
  }

  func detach() { finish(nil); channel.setMethodCallHandler(nil) }
  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingResult == nil else { result(FlutterError(code: "busy", message: "A document handoff is already active.", details: nil)); return }
    switch call.method { case "exportFile": exportFile(call.arguments, result: result); case "importFile": importFile(result: result); case "capabilities": result(["files": true, "icloudDrive": true, "securityScopedImport": true, "copyOnImport": true]); default: result(FlutterMethodNotImplemented) }
  }
  private func exportFile(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let sourcePath = args["path"] as? String, !sourcePath.isEmpty else { result(FlutterError(code: "invalid_arguments", message: "exportFile requires a non-empty path.", details: nil)); return }
    let source = URL(fileURLWithPath: sourcePath).standardizedFileURL
    guard FileManager.default.fileExists(atPath: source.path), !source.hasDirectoryPath else { result(FlutterError(code: "missing_file", message: "The export source is not a file.", details: nil)); return }
    guard let presenter else { result(FlutterError(code: "no_presenter", message: "No view controller is available.", details: nil)); return }
    let preferredName = sanitizedFilename(args["filename"] as? String) ?? source.lastPathComponent
    let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("quran-user-exports", isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
      let staged = tempDirectory.appendingPathComponent(preferredName, isDirectory: false)
      try? FileManager.default.removeItem(at: staged); try FileManager.default.copyItem(at: source, to: staged)
      var values = URLResourceValues(); values.isExcludedFromBackup = true
      var mutable = staged; try mutable.setResourceValues(values)
      temporaryExportURL = staged; pendingResult = result
      let picker = UIDocumentPickerViewController(forExporting: [staged], asCopy: true)
      picker.delegate = self; picker.modalPresentationStyle = .formSheet; presenter.present(picker, animated: true)
    } catch { cleanupExport(); result(FlutterError(code: "export_failed", message: error.localizedDescription, details: nil)) }
  }
  private func importFile(result: @escaping FlutterResult) {
    guard let presenter else { result(FlutterError(code: "no_presenter", message: "No view controller is available.", details: nil)); return }
    pendingResult = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
    picker.allowsMultipleSelection = false; picker.delegate = self; picker.modalPresentationStyle = .formSheet; presenter.present(picker, animated: true)
  }
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { finish(["status": "cancelled"]) }
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let picked = urls.first else { finish(["status": "cancelled"]); return }
    let scoped = picked.startAccessingSecurityScopedResource(); defer { if scoped { picked.stopAccessingSecurityScopedResource() } }
    do {
      let inbox = try importDirectory(); let destination = uniqueDestination(in: inbox, filename: sanitizedFilename(picked.lastPathComponent) ?? "import.quranbackup")
      try FileManager.default.copyItem(at: picked, to: destination)
      var values = URLResourceValues(); values.isExcludedFromBackup = true
      var mutable = destination; try mutable.setResourceValues(values)
      let attributes = try FileManager.default.attributesOfItem(atPath: destination.path); let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
      finish(["status": "selected", "path": destination.path, "filename": destination.lastPathComponent, "size": size])
    } catch { finish(error: FlutterError(code: "import_failed", message: error.localizedDescription, details: nil)) }
  }
  private func importDirectory() throws -> URL {
    let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true); let directory = base.appendingPathComponent("ImportedUserBackups", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true); var values = URLResourceValues(); values.isExcludedFromBackup = true; var mutable = directory; try mutable.setResourceValues(values); return directory
  }
  private func uniqueDestination(in directory: URL, filename: String) -> URL {
    let base = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent; let ext = URL(fileURLWithPath: filename).pathExtension; var candidate = directory.appendingPathComponent(filename); var index = 2
    while FileManager.default.fileExists(atPath: candidate.path) { candidate = directory.appendingPathComponent(ext.isEmpty ? "\(base)-\(index)" : "\(base)-\(index).\(ext)"); index += 1 }; return candidate
  }
  private func sanitizedFilename(_ value: String?) -> String? { guard let value else { return nil }; let leaf = URL(fileURLWithPath: value).lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines); return (!leaf.isEmpty && leaf != "." && leaf != "..") ? leaf : nil }
  private func finish(_ payload: Any?) { guard let result = pendingResult else { cleanupExport(); return }; pendingResult = nil; cleanupExport(); result(payload) }
  private func finish(error: FlutterError) { guard let result = pendingResult else { cleanupExport(); return }; pendingResult = nil; cleanupExport(); result(error) }
  private func cleanupExport() { if let temporaryExportURL { try? FileManager.default.removeItem(at: temporaryExportURL) }; temporaryExportURL = nil }
}
