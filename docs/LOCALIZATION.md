# Çoklu dil mimarisi

Uygulama arayüzü baştan çoklu dil destekleyecek şekilde tasarlanmıştır. Arayüz dili ile Kur’an/meal kaynağı birbirinden bağımsız tutulur.

## Desteklenen arayüz dilleri

Şu anda hedeflenen çekirdek arayüz dili seti altı dildir:

- `tr` — Türkçe
- `en` — English
- `ar` — العربية
- `az` — Azərbaycanca
- `ru` — Русский
- `fr` — Français

`AppLocalizations.supportedLocales` bu listenin uygulamadaki kaynak doğruluğudur.

## Dil seçimi ve fallback

- Kullanıcı uygulama dilini elle seçtiyse desteklenen bu seçim cihaz dilinden üstündür.
- `AppSettings.locale == null` veya kayıtlı değer `system` ise cihazın tercih edilen dilleri sırayla kontrol edilir.
- Cihaz dillerinden hiçbiri desteklenmiyorsa arayüz dili `en` olarak çözülür.
- Kullanıcıya görünen yeni metinler doğrudan widget/servis içine yazılmamalı; `AppLocalizations` veya merkezi feature string katmanı üzerinden gelmelidir.
- Feature string katmanında eksik bir anahtar için İngilizce, ardından Türkçe güvenli anahtar fallback’i kullanılabilir; yeni özelliklerde TR/EN/AR/AZ/RU/FR key parity’si korunmalıdır.

## Kur’an ve meal dili

- Uygulama dili ile seçili Kur’an/meal kaynağı birbirinden bağımsızdır.
- Arapça Kur’an temel metni uygulama dilinden bağımsız ve çevrimdışı kullanılabilir kalır.
- Meal kataloğu `languageCode` ile ayrı yönetilir. Bir arayüz dilinin desteklenmesi o dildeki meal paketinin APK içine gömülmesini zorunlu kılmaz.
- İndirilebilir mealler katalogda görülebilir ve aranabilir; ayet metni içinde arama yalnız cihazda kurulu/seçili paket üzerinde yerel yapılır.
- Otomatik dil başlangıç seçimi, kullanıcının daha önce elle seçtiği meal kaynağını ezmemelidir.

## Uygulama kuralı

Yeni ekran veya servis eklenirken dört nokta ayrıca kontrol edilir: hardcoded kullanıcı metni, yerel/tekrarlı çeviri haritası, cihaz dilinin doğrudan okunması ve seçili uygulama/meal dili yerine varsayım yapılması. Dil davranışı mümkün olduğunca merkezi resolver ve localization katmanından türetilir.


## Fransızca kapsamı

Fransızca yalnız meal/content seçeneği değildir; **tam uygulama locale’idir**. `fr` için onboarding, Home, Kur’an/Reader, Öğren/Hıfz, Planlar, Keşfedin, Ayarlar, Namaz/Kıble, bildirimler, indirmeler, yedekleme/gizlilik, hata/izin/help ve accessibility metinlerinde tam parity hedeflenir.

Fransızca UI desteği ile Fransızca meal/audio lisansı birbirinden bağımsızdır. UI tamamen Fransızca çalışabilir; Fransızca meal veya insan sesli meal ancak GREEN lisans/source doğrulamasından sonra content kataloğunda production’a açılır.
