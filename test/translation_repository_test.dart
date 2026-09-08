import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_catalog.dart';
import 'package:quran_i_kerim/src/data/translation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled Turkish translation still loads through pack decoder',
    () async {
      final pack = await TranslationRepository.instance
          .loadBundledTurkishPack();

      expect(pack.translationId, 'turkish_rwwad');
      expect(pack.languageCode, 'tr');
      expect(pack.source, 'QuranEnc.com');
      expect(pack.verses.length, greaterThan(6000));
      expect(pack.verse(1, 1), isNotEmpty);
      expect(pack.verse(2, 255), isNotEmpty);
      expect(pack.verse(114, 6), isNotEmpty);
    },
  );

  test('Islamic Network translation uses one complete-edition request', () {
    final info = translationById(turkishVakfiTranslationId)!;
    final uri = islamicNetworkTranslationPackageUri(info);
    expect(uri.host, 'api.alquran.cloud');
    expect(uri.path, '/v1/quran/tr.vakfi');
  });
}
