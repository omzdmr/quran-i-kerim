import 'package:flutter_test/flutter_test.dart';
import 'package:quran_i_kerim/src/data/translation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled Turkish translation still loads through pack decoder', () async {
    final pack = await TranslationRepository.instance.loadBundledTurkishPack();

    expect(pack.translationId, 'turkish_rwwad');
    expect(pack.languageCode, 'tr');
    expect(pack.source, 'QuranEnc.com');
    expect(pack.verses.length, greaterThan(6000));
    expect(pack.verse(1, 1), isNotEmpty);
    expect(pack.verse(2, 255), isNotEmpty);
    expect(pack.verse(114, 6), isNotEmpty);
  });
}
