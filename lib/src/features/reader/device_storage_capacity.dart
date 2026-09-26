import 'package:flutter/services.dart';

class DeviceStorageCapacity {
  DeviceStorageCapacity._();

  static const MethodChannel _channel =
      MethodChannel('app.quranikerim/native_storage_capacity');

  /// Returns the OS capacity that may safely be used for important app data.
  /// Null means this platform/build does not expose the native contract yet.
  static Future<int?> availableForImportantUsageBytes() async {
    try {
      final payload = await _channel.invokeMapMethod<String, Object?>('status');
      final value = payload?['availableForImportantUsageBytes'];
      if (value is int && value >= 0) return value;
      if (value is num && value >= 0) return value.toInt();
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
