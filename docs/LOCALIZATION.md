# Çoklu dil mimarisi

Uygulama ilk sürümde Türkçe odaklıdır ancak dil sistemi baştan çoklu dil destekleyecek şekilde kurulmuştur.

## Kurallar

- Uygulama dili ile meal dili birbirinden bağımsızdır.
- `AppSettings.locale == null` cihaz dilini takip eder.
- Kullanıcı isterse uygulama dilini elle seçebilir.
- Yeni bir arayüz dili eklemek uygulama mimarisini değiştirmemelidir.
- Yeni kullanıcıya görünen metinler doğrudan widget içine yazılmamalı; `AppLocalizations` üzerinden gelmelidir.
- Türkçe, eksik çeviri anahtarlarında güvenli geri dönüş dilidir.
- Arapça Kuran metni uygulama dilinden bağımsız ve her zaman çevrimdışı kalır.
- Meal kataloğu `languageCode` ile ayrı yönetilir. Bir arayüz dilinin eklenmesi o dilde meal bulunmasını zorunlu kılmaz.

## Şu an

Desteklenen arayüz dili: `tr`

Tema ve dil için iki ayrı “cihazı takip et” tercihi vardır. İleride örneğin `ru`, `az` veya `en` eklendiğinde yeni dil haritası ve `supportedLocales` girdisi eklemek yeterli olacak; navigasyon veya ayarlar mimarisi yeniden yazılmayacaktır.
