# Çoklu Dil ve Meal Mimarisi

Bu belge uygulama arayüz dili ile Kuran/meal içerik dilini bilinçli olarak birbirinden ayırır.

## 1. Arayüz dili

İlk dalga:

- Türkçe (`tr`)
- English (`en`)
- العربية (`ar`)
- Azərbaycanca (`az`)
- Русский (`ru`)

Kullanıcı **Cihaz dilini kullan** seçeneğini kullanabilir veya dili elle sabitleyebilir. Desteklenmeyen cihaz dilinde güvenli genel geri dönüş İngilizcedir. Arapça seçildiğinde Flutter yön sistemi RTL yerleşimi otomatik uygular; ekranlarda elle LTR varsayımı yapılmamalıdır.

Arayüz dili kullanıcının okuyacağı meal dilini değiştirmez.

## 2. Kuran / meal dili

Her zaman cihazda:

- Arapça Kuran orijinal metni
- İlk Türkçe paket: `turkish_rwwad` / `RWD`

Ek mealler uygulamanın içine topluca gömülmeyecek. Lisans ve kaynak doğrulamasından geçen paketler katalogdan indirilebilir olacak.

Bir meal paketi en az şu metadata alanlarına sahip olmalı:

- `translation_id`
- `language_code`
- `native_language_name`
- `name`
- `translator/publisher`
- `short_code`
- `source`
- `content_version`
- `license`
- `commercial_allowed`
- `offline_allowed`
- `attribution`
- `checksum`
- `verse_scheme` (gerektiğinde)

## 3. Katalog UX hedefi

Çok sayıda içerik dili geldiğinde seçim ekranı:

- arama
- **Önerilen / Tümü**
- dil adına göre alfabetik liste
- uzun listede harf indeksi
- her dil altında mevcut mealler
- yüklü / indirilebilir / güncelleme var durumları
- paket boyutu
- kaynak/yayıncı bilgisi

mantığıyla çalışır.

Amaç belirli bir dil sayısını pazarlama rakamı olarak kovalamak değildir. Mimari yüzlerce dili kaldırabilmeli; kataloğa yalnız güvenilir ve yeniden dağıtım hakkı doğrulanmış içerik eklenmelidir.

## 4. Offline-first

- Arapça her zaman bundled.
- Kullanıcının ilk varsayılan meali bundled olabilir.
- Diğer mealler isteğe bağlı indirilir.
- Çoklu meal büyüdüğünde sure bazlı parçalar + küçük sıcak cache değerlendirilecek.
- İndirmeler ileride ortak Download Manager üzerinden yapılacak.

## 5. Uygulanan ilk adım

`feature/localization-v01` dalında:

- beş arayüz dili etkinleştirildi,
- cihaz dili otomatik seçimi açıldı,
- uygulama dili ve okuma metni ayarlarda ayrı bölümlere ayrıldı,
- Türkçe RWD ile Arapça orijinal arasında okuma tercihi ayarlardan değiştirilebilir hale getirildi,
- lokalizasyon testleri eklendi,
- alt navigasyon sürükleme davranışı, sekmeyi sürüklerken yalnız önizleyip parmak bırakıldığında açacak şekilde düzeltildi.
