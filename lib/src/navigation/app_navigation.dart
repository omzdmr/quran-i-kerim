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
/// Reader selection state is also exposed so the shell can yield the bottom
/// area to the verse action tray instead of stacking two navigation surfaces.
class AppNavigation {
  AppNavigation._();

  static final AppNavigation instance = AppNavigation._();

  final ValueNotifier<int?> tabRequest = ValueNotifier<int?>(null);
  final ValueNotifier<ReaderTarget?> readerRequest =
      ValueNotifier<ReaderTarget?>(null);
  final ValueNotifier<bool> readerSelectionActive = ValueNotifier<bool>(false);

  void openReader({required int surah, required int ayah}) {
    readerSelectionActive.value = false;
    readerRequest.value = ReaderTarget(
      surah: surah.clamp(1, 114).toInt(),
      ayah: ayah < 1 ? 1 : ayah,
    );
    tabRequest.value = 1;
  }

  void setReaderSelectionActive(bool active) {
    if (readerSelectionActive.value == active) return;
    readerSelectionActive.value = active;
  }

  void consumeTabRequest() => tabRequest.value = null;

  void consumeReaderRequest() => readerRequest.value = null;
}
