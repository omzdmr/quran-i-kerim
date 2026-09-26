import 'package:flutter/foundation.dart';

@immutable
class DownloadStorageBudget {
  const DownloadStorageBudget({
    required this.availableBytes,
    required this.requiredBytes,
    required this.reserveBytes,
  });

  static const int minimumReserveBytes = 256 * 1024 * 1024;
  static const double reserveFraction = 0.10;

  final int availableBytes;
  final int requiredBytes;
  final int reserveBytes;

  int get usableBytes => (availableBytes - reserveBytes).clamp(0, availableBytes);
  int get shortfallBytes => (requiredBytes - usableBytes).clamp(0, requiredBytes);
  bool get canStart => requiredBytes <= usableBytes;

  factory DownloadStorageBudget.evaluate({
    required int availableBytes,
    required int requiredBytes,
  }) {
    final safeAvailable = availableBytes < 0 ? 0 : availableBytes;
    final safeRequired = requiredBytes < 0 ? 0 : requiredBytes;
    final percentageReserve = (safeAvailable * reserveFraction).round();
    final reserve = percentageReserve > minimumReserveBytes
        ? percentageReserve
        : minimumReserveBytes;
    return DownloadStorageBudget(
      availableBytes: safeAvailable,
      requiredBytes: safeRequired,
      reserveBytes: reserve.clamp(0, safeAvailable),
    );
  }
}

typedef AvailableStorageProbe = Future<int?> Function();
