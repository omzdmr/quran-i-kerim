import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/content_rights.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';

void main() {
  test('QuranEnc stays yellow until ad-supported commercial rights are explicit', () {
    final info = translationCatalog.firstWhere(
      (item) => item.provider == TranslationProvider.quranEnc,
    );
    final rights = translationRightsFor(info);

    expect(rights.status, ContentRightsStatus.yellow);
    expect(rights.productionAllowed, isFalse);
    expect(rights.adsAllowed, isFalse);
    expect(rights.redistributionAllowed, isTrue);
    expect(rights.offlineAllowed, isTrue);
    expect(rights.attributionRequired, isTrue);
    expect(rights.updateRequired, isTrue);
  });

  test('unverified Islamic Network editions stay out of production', () {
    final info = translationCatalog.firstWhere(
      (item) => item.provider == TranslationProvider.islamicNetwork,
    );
    final rights = translationRightsFor(info);

    expect(rights.status, ContentRightsStatus.yellow);
    expect(rights.productionAllowed, isFalse);
    expect(rights.adsAllowed, isFalse);
    expect(rights.redistributionAllowed, isFalse);
    expect(rights.offlineAllowed, isFalse);
  });
}
