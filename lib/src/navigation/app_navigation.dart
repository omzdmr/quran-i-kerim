import 'package:flutter/foundation.dart';

class ReaderTarget {
  const ReaderTarget({required this.surah, required this.ayah});

  final int surah;
  final int ayah;
}

/// Lightweight in-app navigation coordinator.
///
/// The bottom-tab shell stays the owner of tab selection while screens such as
/// Home and Profile can request that the Quran tab opens at a specific ayah.
/// No router package or network state is required.
class AppNavigation {
  AppNavigation._();

  static final AppNavigation instance = AppNavigation._();

  final ValueNotifier<int?> tabRequest = ValueNotifier<int?>(null);
  final ValueNotifier<ReaderTarget?> readerRequest =
      ValueNotifier<ReaderTarget?>(null);

  void openReader({required int surah, required int ayah}) {
    readerRequest.value = ReaderTarget(
      surah: surah.clamp(1, 114).toInt(),
      ayah: ayah < 1 ? 1 : ayah,
    );
    tabRequest.value = 1;
  }

  void consumeTabRequest() => tabRequest.value = null;

  void consumeReaderRequest() => readerRequest.value = null;
}
