import CoreLocation
import Flutter
import Foundation

/// Native iOS boundary for foreground location and compass heading.
///
/// Permission is never requested at app launch. The shared layer must call
/// `requestWhenInUsePermission` after an explicit user action. Location and
/// heading streams are similarly opt-in and can be stopped independently.
final class LocationHeadingChannel: NSObject, CLLocationManagerDelegate {
  static let name = "com.omzdmr.quran_i_kerim/location_heading"

  private let manager: CLLocationManager
  private let channel: FlutterMethodChannel
  private var locationStreaming = false
  private var headingStreaming = false

  init(binaryMessenger: FlutterBinaryMessenger, manager: CLLocationManager = CLLocationManager()) {
    self.manager = manager
    channel = FlutterMethodChannel(name: Self.name, binaryMessenger: binaryMessenger)
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.distanceFilter = 25
    manager.headingFilter = 2
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  func detach() {
    stopAll()
    channel.setMethodCallHandler(nil)
    manager.delegate = nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAuthorizationStatus":
      result(Self.authorizationName(manager.authorizationStatus))

    case "requestWhenInUsePermission":
      manager.requestWhenInUseAuthorization()
      result(nil)

    case "getCapabilityStatus":
      result([
        "locationServicesEnabled": CLLocationManager.locationServicesEnabled(),
        "headingAvailable": CLLocationManager.headingAvailable(),
        "authorizationStatus": Self.authorizationName(manager.authorizationStatus),
      ])

    case "startLocationUpdates":
      guard CLLocationManager.locationServicesEnabled() else {
        result(FlutterError(code: "location_services_disabled", message: "Location Services are disabled.", details: nil))
        return
      }
      guard Self.canReadLocation(manager.authorizationStatus) else {
        result(FlutterError(code: "location_permission_required", message: "Foreground location permission is required.", details: nil))
        return
      }
      locationStreaming = true
      manager.startUpdatingLocation()
      result(nil)

    case "stopLocationUpdates":
      locationStreaming = false
      manager.stopUpdatingLocation()
      result(nil)

    case "startHeadingUpdates":
      guard CLLocationManager.headingAvailable() else {
        result(FlutterError(code: "heading_unavailable", message: "Compass heading is unavailable on this device.", details: nil))
        return
      }
      headingStreaming = true
      manager.startUpdatingHeading()
      result(nil)

    case "stopHeadingUpdates":
      headingStreaming = false
      manager.stopUpdatingHeading()
      result(nil)

    case "stopAll":
      stopAll()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func stopAll() {
    locationStreaming = false
    headingStreaming = false
    manager.stopUpdatingLocation()
    manager.stopUpdatingHeading()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    channel.invokeMethod("authorizationChanged", arguments: [
      "status": Self.authorizationName(manager.authorizationStatus),
    ])
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard locationStreaming, let location = locations.last else { return }
    guard location.horizontalAccuracy >= 0 else { return }
    channel.invokeMethod("locationChanged", arguments: [
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "horizontalAccuracyMeters": location.horizontalAccuracy,
      "timestampMilliseconds": location.timestamp.timeIntervalSince1970 * 1000,
    ])
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    guard headingStreaming, newHeading.headingAccuracy >= 0 else { return }
    let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    channel.invokeMethod("headingChanged", arguments: [
      "degrees": heading,
      "magneticDegrees": newHeading.magneticHeading,
      "accuracyDegrees": newHeading.headingAccuracy,
      "usesTrueNorth": newHeading.trueHeading >= 0,
      "timestampMilliseconds": newHeading.timestamp.timeIntervalSince1970 * 1000,
    ])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    let nsError = error as NSError
    channel.invokeMethod("locationError", arguments: [
      "code": nsError.code,
      "message": nsError.localizedDescription,
    ])
  }

  private static func canReadLocation(_ status: CLAuthorizationStatus) -> Bool {
    status == .authorizedWhenInUse || status == .authorizedAlways
  }

  private static func authorizationName(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .restricted: return "restricted"
    case .denied: return "denied"
    case .authorizedAlways: return "authorizedAlways"
    case .authorizedWhenInUse: return "authorizedWhenInUse"
    @unknown default: return "unknown"
    }
  }
}
