import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/navigation/app_navigation.dart';

void main() {
  final navigation = AppNavigation.instance;

  setUp(() {
    navigation.reportQuranSection(AppNavigation.quranReadSectionIndex);
    navigation.reportActiveTab(AppNavigation.homeTabIndex);
    navigation.setReaderFullScreenActive(false);
  });

  tearDown(() {
    navigation.reportQuranSection(AppNavigation.quranReadSectionIndex);
    navigation.reportActiveTab(AppNavigation.homeTabIndex);
    navigation.setReaderFullScreenActive(false);
  });

  test('Reader visibility requires both Quran tab and Read section', () {
    expect(navigation.readerVisible.value, isFalse);

    navigation.reportActiveTab(AppNavigation.quranTabIndex);
    expect(navigation.readerVisible.value, isTrue);

    navigation.reportQuranSection(1);
    expect(navigation.readerVisible.value, isFalse);

    navigation.reportQuranSection(AppNavigation.quranReadSectionIndex);
    expect(navigation.readerVisible.value, isTrue);

    navigation.reportActiveTab(AppNavigation.plansTabIndex);
    expect(navigation.readerVisible.value, isFalse);
  });

  test('Reader fullscreen visibility can drive shell chrome independently', () {
    expect(navigation.readerFullScreenActive.value, isFalse);

    navigation.setReaderFullScreenActive(true);
    expect(navigation.readerFullScreenActive.value, isTrue);

    navigation.setReaderFullScreenActive(false);
    expect(navigation.readerFullScreenActive.value, isFalse);
  });

  test('reported navigation state is clamped to known surfaces', () {
    navigation.reportActiveTab(99);
    navigation.reportQuranSection(99);

    expect(
      navigation.activeTabIndex.value,
      AppNavigation.profileTabIndex,
    );
    expect(navigation.quranSectionIndex.value, 2);
    expect(navigation.readerVisible.value, isFalse);
  });
}
