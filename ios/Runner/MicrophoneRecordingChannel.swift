import AVFAudio
import Flutter
import Foundation

final class MicrophoneRecordingChannel: NSObject, AVAudioRecorderDelegate {
  static let channelName = "app.quranikerim/native_recording"
  private let channel: FlutterMethodChannel
  private let session: AVAudioSession
  private let center: NotificationCenter
  private var observers: [NSObjectProtocol] = []
  private var recorder: AVAudioRecorder?
  private var activeURL: URL?
  private var startedAt: Date?
  private var interruptedAt: Date?

  init(binaryMessenger: FlutterBinaryMessenger, session: AVAudioSession = .sharedInstance(), notificationCenter: NotificationCenter = .default) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: binaryMessenger); self.session = session; center = notificationCenter; super.init()
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }; observeAudioSession()
  }

  func detach() {
    observers.forEach(center.removeObserver); observers.removeAll(); if recorder?.isRecording == true { recorder?.stop() }
    recorder = nil; activeURL = nil; startedAt = nil; interruptedAt = nil; channel.setMethodCallHandler(nil); AudioSessionCoordinator.shared.configurePolicy()
  }

  private func observeAudioSession() {
    observers = [center.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] note in self?.handleInterruption(note) }, center.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: .main) { [weak self] note in self?.handleRouteChange(note) }]
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capabilities": result(["format": "m4a/aac", "metering": true, "persistentUserData": true, "listAndDelete": true, "interruptionRecovery": true, "routeChangeEvents": true, "bluetoothMicrophone": true])
    case "permissionStatus": result(Self.permissionName(session.recordPermission))
    case "requestPermission": session.requestRecordPermission { granted in DispatchQueue.main.async { result(["granted": granted]) } }
    case "startRecording": startRecording(call.arguments, result: result)
    case "recordingStatus": result(statusPayload())
    case "stopRecording": stopRecording(discard: false, result: result)
    case "cancelRecording": stopRecording(discard: true, result: result)
    case "listRecordings": listRecordings(result: result)
    case "deleteRecording": deleteRecording(call.arguments, result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func startRecording(_ arguments: Any?, result: @escaping FlutterResult) {
    guard session.recordPermission == .granted else { result(FlutterError(code: "microphone_permission_required", message: "Microphone permission is required before recording.", details: nil)); return }
    guard recorder?.isRecording != true else { result(FlutterError(code: "recording_already_active", message: "A recitation recording is already active.", details: nil)); return }
    do {
      let directory = try recordingsDirectory(), requestedID = (arguments as? [String: Any])?["recordingId"] as? String, id = sanitizedIdentifier(requestedID) ?? UUID().uuidString.lowercased(), url = uniqueURL(in: directory, base: id)
      // A2DP is output-only. allowBluetooth keeps HFP headset microphones (including AirPods)
      // eligible as inputs on older deployment targets while A2DP remains available for playback.
      try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
      try session.setActive(true)
      let settings: [String: Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44_100.0, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue, AVEncoderBitRateKey: 96_000]
      let recorder = try AVAudioRecorder(url: url, settings: settings); recorder.delegate = self; recorder.isMeteringEnabled = true
      guard recorder.prepareToRecord(), recorder.record() else { throw RecordingError.couldNotStart }
      self.recorder = recorder; activeURL = url; startedAt = Date(); interruptedAt = nil
      var payload: [String: Any] = ["recording": true, "recordingId": url.deletingPathExtension().lastPathComponent, "path": url.path]
      if let input = session.currentRoute.inputs.first { payload["inputName"] = input.portName; payload["inputPortType"] = input.portType.rawValue }
      result(payload)
    } catch { AudioSessionCoordinator.shared.configurePolicy(); result(FlutterError(code: "recording_start_failed", message: error.localizedDescription, details: nil)) }
  }

  private func stopRecording(discard: Bool, result: @escaping FlutterResult) {
    guard let recorder, let url = activeURL else { result(FlutterError(code: "no_active_recording", message: "There is no active recording.", details: nil)); return }
    recorder.stop(); let duration = recorder.currentTime; resetActiveRecording()
    if discard { try? FileManager.default.removeItem(at: url); result(["discarded": true]) }
    else { result(["recording": false, "recordingId": url.deletingPathExtension().lastPathComponent, "path": url.path, "durationSeconds": max(0, duration), "sizeBytes": fileSize(url)]) }
  }

  private func statusPayload() -> [String: Any] {
    guard let recorder, let url = activeURL else { return ["recording": false] }
    recorder.updateMeters()
    var payload: [String: Any] = ["recording": recorder.isRecording, "interrupted": interruptedAt != nil, "path": url.path, "durationSeconds": max(0, recorder.currentTime), "averagePowerDb": recorder.averagePower(forChannel: 0), "peakPowerDb": recorder.peakPower(forChannel: 0)]
    if let startedAt { payload["startedAtMs"] = Int64(startedAt.timeIntervalSince1970 * 1000) }; if let interruptedAt { payload["interruptedAtMs"] = Int64(interruptedAt.timeIntervalSince1970 * 1000) }
    if let input = session.currentRoute.inputs.first { payload["inputName"] = input.portName; payload["inputPortType"] = input.portType.rawValue }
    return payload
  }

  private func handleInterruption(_ notification: Notification) {
    guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
    switch type {
    case .began: guard recorder != nil else { return }; interruptedAt = Date(); channel.invokeMethod("recordingInterruptionChanged", arguments: ["interrupted": true, "atMs": Int64(Date().timeIntervalSince1970 * 1000)])
    case .ended:
      guard let recorder, let url = activeURL, interruptedAt != nil else { return }
      let optionsRaw = (notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0, options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
      recorder.stop(); let duration = max(0, recorder.currentTime); resetActiveRecording()
      channel.invokeMethod("recordingInterrupted", arguments: ["recordingId": url.deletingPathExtension().lastPathComponent, "path": url.path, "durationSeconds": duration, "sizeBytes": fileSize(url), "canRestart": options.contains(.shouldResume)])
    @unknown default: break
    }
  }

  private func handleRouteChange(_ notification: Notification) {
    guard recorder != nil, let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt, let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
    channel.invokeMethod("recordingRouteChanged", arguments: ["reason": Self.routeChangeName(reason), "recording": recorder?.isRecording == true, "input": session.currentRoute.inputs.first?.portName ?? "", "inputPortType": session.currentRoute.inputs.first?.portType.rawValue ?? ""])
  }

  private func listRecordings(result: @escaping FlutterResult) {
    do {
      let directory = try recordingsDirectory(), keys: Set<URLResourceKey> = [.fileSizeKey, .creationDateKey, .contentModificationDateKey, .isRegularFileKey], urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles])
      let items: [[String: Any]] = urls.compactMap { url in guard url.pathExtension.lowercased() == "m4a", let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true else { return nil }; var item: [String: Any] = ["recordingId": url.deletingPathExtension().lastPathComponent, "path": url.path, "sizeBytes": values.fileSize ?? 0]; if let created = values.creationDate { item["createdAtMs"] = Int64(created.timeIntervalSince1970 * 1000) }; if let modified = values.contentModificationDate { item["modifiedAtMs"] = Int64(modified.timeIntervalSince1970 * 1000) }; return item }.sorted { ($0["modifiedAtMs"] as? Int64 ?? 0) > ($1["modifiedAtMs"] as? Int64 ?? 0) }
      result(items)
    } catch { result(FlutterError(code: "recording_list_failed", message: error.localizedDescription, details: nil)) }
  }

  private func deleteRecording(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let rawID = args["recordingId"] as? String, let id = sanitizedIdentifier(rawID), id == rawID else { result(FlutterError(code: "invalid_recording_id", message: "A valid recordingId is required.", details: nil)); return }
    do { let directory = try recordingsDirectory(), url = directory.appendingPathComponent("\(id).m4a").standardizedFileURL; guard url.deletingLastPathComponent() == directory.standardizedFileURL else { throw RecordingError.invalidPath }; guard FileManager.default.fileExists(atPath: url.path) else { result(FlutterError(code: "recording_not_found", message: "The recording does not exist.", details: nil)); return }; if activeURL?.standardizedFileURL == url { result(FlutterError(code: "recording_is_active", message: "Stop or cancel the active recording before deleting it.", details: nil)); return }; try FileManager.default.removeItem(at: url); result(["deleted": true, "recordingId": id]) } catch { result(FlutterError(code: "recording_delete_failed", message: error.localizedDescription, details: nil)) }
  }

  private func resetActiveRecording() { recorder = nil; activeURL = nil; startedAt = nil; interruptedAt = nil; AudioSessionCoordinator.shared.configurePolicy() }
  private func recordingsDirectory() throws -> URL { let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true), directory = base.appendingPathComponent("UserRecitations", isDirectory: true); try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true); try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: directory.path); return directory }
  private func uniqueURL(in directory: URL, base: String) -> URL { var candidate = directory.appendingPathComponent("\(base).m4a"), index = 2; while FileManager.default.fileExists(atPath: candidate.path) { candidate = directory.appendingPathComponent("\(base)-\(index).m4a"); index += 1 }; return candidate }
  private func sanitizedIdentifier(_ value: String?) -> String? { guard let value else { return nil }; let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_")), clean = value.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined(); return clean.isEmpty ? nil : String(clean.prefix(80)) }
  private func fileSize(_ url: URL) -> Int64 { let attributes = try? FileManager.default.attributesOfItem(atPath: url.path); return (attributes?[.size] as? NSNumber)?.int64Value ?? 0 }
  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) { guard let error else { return }; channel.invokeMethod("recordingError", arguments: ["message": error.localizedDescription]) }
  func audioRecorderDidFinishRecording(_ finishedRecorder: AVAudioRecorder, successfully flag: Bool) { guard !flag, finishedRecorder === recorder else { return }; let url = activeURL, duration = max(0, finishedRecorder.currentTime); resetActiveRecording(); var payload: [String: Any] = ["message": "Recording stopped before the file was finalized.", "durationSeconds": duration]; if let url { payload["path"] = url.path; payload["recordingId"] = url.deletingPathExtension().lastPathComponent; payload["sizeBytes"] = fileSize(url) }; channel.invokeMethod("recordingInterrupted", arguments: payload) }
  private static func permissionName(_ permission: AVAudioSession.RecordPermission) -> String { switch permission { case .undetermined: return "notDetermined"; case .denied: return "denied"; case .granted: return "granted"; @unknown default: return "unknown" } }
  private static func routeChangeName(_ reason: AVAudioSession.RouteChangeReason) -> String { switch reason { case .newDeviceAvailable: return "newDeviceAvailable"; case .oldDeviceUnavailable: return "oldDeviceUnavailable"; case .categoryChange: return "categoryChange"; case .override: return "override"; case .wakeFromSleep: return "wakeFromSleep"; case .noSuitableRouteForCategory: return "noSuitableRouteForCategory"; case .routeConfigurationChange: return "routeConfigurationChange"; case .unknown: return "unknown"; @unknown default: return "unknown" } }
  private enum RecordingError: LocalizedError { case couldNotStart, invalidPath; var errorDescription: String? { switch self { case .couldNotStart: return "The audio recorder could not start."; case .invalidPath: return "The recording path is invalid." } } }
}
