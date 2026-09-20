# Referans Ekran Kapsamı

Bu dosya, kullanıcının 2026-09-13 tarihinde yeniden yüklediği referans ekran görüntülerinde görülen ürün/UX fikirlerini tek tek kayıt altına alır. `docs/PRODUCT_STRUCTURE.md` ana ürün ve navigasyon source-of-truth dosyasıdır; bu dosya ise görsellerdeki ayrıntıların unutulmaması için kapsama kontrol listesidir.

Referans uygulamanın özgün illüstrasyonları, metinleri, marka öğeleri ve birebir ekran kompozisyonu kopyalanmaz. Buradaki maddeler yalnız UX/ürün fikri olarak uyarlanır. Dini içerik yalnız doğrulanmış, kullanımı uygun kaynaklardan gelir.

## 1. Onboarding / ilk kurulum

### Arapça yazı görünümü
- Kullanıcı Arapça yazı/görünüm tercihini ilk kurulumda seçebilmeli.
- Seçenekler gerçek ayet/metin önizlemesiyle gösterilmeli; salt isim listesi olmamalı.
- Uygulamanın önerdiği seçenek belirgin olabilir.
- Referanstaki Osmanî / IndoPak benzeri ayrım birebir isim kopyası olarak değil, uygulamada gerçekten desteklenen font/yazı seçeneklerine göre sunulmalı.
- Aynı ayar daha sonra Siz/Ayarlar içinden değiştirilebilmeli.

### Meal seçimi
- Varsayılan meal/çeviri ilk kurulumda seçilebilmeli.
- Seçili meal, kısa bir ayet örneğiyle önizlenebilmeli.
- Uygulama dili ile meal dili birbirinden bağımsız kalmalı.
- Kullanıcı aynı dilde başka çevirmen/kaynaklara geçebilmeli ve ek dilleri katalogdan indirebilmeli.

### Okuma hedefi
- Zaman bazlı günlük okuma hedefleri desteklenmeli (örneğin kısa/orta/uzun günlük süreler).
- Hedef kartı mümkünse yaklaşık ayet aralığı veya benzeri anlaşılır hacim göstergesi verebilmeli.
- Kullanıcıya hedef temposuna göre yaklaşık tamamlama süresi gösterilebilir; bu değer kesin vaat gibi sunulmamalı.
- Hedef onboarding sonrası İlerlemem/Planlar/Ayarlar üzerinden düzenlenebilmeli.

### Okuyucu / ses paketi
- İlk kurulumda önerilen insan okuyucu seçimi/indirmesi isteğe bağlı olabilir.
- Büyük ses indirmesi zorunlu değildir; `Daha sonra` benzeri açık kaçış bulunmalı.
- İndirme boyutu, kaynak ve çevrimdışı davranış açık olmalı.
- TTS kullanılmaz.

### Hesap duvarı yok
- Referans ekranlardaki zorunlu hesap oluşturma / Apple-Google-e-posta ile devam et akışı ürünümüze aynen alınmaz.
- Öğren veya Ezberle özelliklerine giriş için hesap zorunluluğu yoktur.
- Local-first kullanım tam olmalıdır.
- Gelecekte yedekleme/senkronizasyon eklenirse kullanıcıya ait bulut hesabı modeli tercih edilir; özelliklerin ana kullanımı backend hesabına bağlanmaz.

## 2. Kur’an alanı

- Ana alt navigasyondaki Kur’an sekmesi doğrudan `Oku/Reader` ile açılır.
- Kur’an alanında `Oku / Öğren / İlerlemem` iç organizasyonu bulunabilir.
- Reader’da metin önceliklidir; üst segment ve kontroller okuma yüzeyini ezmemelidir.
- Son okunanlar/devam et, kaynak seçimi, bookmark/not/vurgu ve arama davranışları mevcut ortak Reader mimarisiyle birleşir.

### Günlük ayet widget fikri
- Referanstaki ana ekran/OS `Günlük Ayet` widget fikri faydalı fakat ilk çekirdek sürüm için zorunlu değildir.
- Native iOS/Android widget extension gerektirdiği için ayrı, kontrollü cross-platform iş dilimi olarak değerlendirilmelidir.
- Kullanıcının açık ürün kararı olmadan saatlik otomasyon bunu kendiliğinden önceliklendirmez.

## 3. Öğren / Dersler

Referans ekranlarda görülen ders akışı aşağıdaki UX sırasına dönüştürülür:

1. Ders/sure/konu tanıtımı.
2. İlgili ayetin Arapçası.
3. Transliterasyon.
4. Seçili meal.
5. Kaynaklı açıklama / bilgi kartı.
6. Uygunsa doğrulanmış ilgili hadis/kaynak kartı.
7. `Bilgi incelemesi` veya kısa tekrar/özet geçişi.
8. Birden fazla ayet/bilginin birlikte gözden geçirildiği recap ekranı gerektiğinde kullanılabilir.
9. Mini quiz.
10. Yanlış cevapta kısa ve teşvik edici geri bildirim; yeniden deneme imkanı.
11. Doğru cevapta kısa olumlu geri bildirim.
12. Quiz sonrası kısa sonuç/açıklama kartı.
13. Ders tamamlandı ekranı.
14. `Derslere dön` ve `Kur’an’da devam et` gibi net çıkışlar.

### Ders ekranı davranışı
- Üstte hafif bir ilerleme göstergesi bulunabilir.
- İleri/geri geçişler nettir; uzun tek makale yerine adım adım akış kullanılır.
- Tam ekran tematik arka plan veya illüstrasyon kullanılacaksa özgün tasarımımız olmalıdır; referans uygulamanın çöl/orman çizimleri kopyalanmaz.
- Aynı ders içinde farklı renk temaları yalnız anlamlıysa kullanılır; süs olsun diye her sureye ağır tema üretilmez.
- Dini açıklama veya hadis metni model tarafından uydurulmaz.

## 4. Öğren ana ekranı

- Öğren alanında temel bölümler: `Dersler / Ezberle / Makaleler`.
- Referansta görülen ayrı `Kaynaklar` sekmesi ürünümüzde zorunlu değildir; kaynak şeffaflığı ilgili içeriğin yanında gösterilir.
- Makaleler kart/grit düzeninde gösterilebilir; `Hepsini gör` benzeri genişleme eylemi olabilir.
- Makale görselleri ve metinleri bizim kaynak/lisans modelimize uygun olmalıdır.

## 5. İlerlemem

Referans ilerleme ekranından alınacak ayrıntılar:

- `Okuma / Hatim` gibi doğal alt ayrım gerekiyorsa kullanılabilir.
- Bugünkü okuma süresi veya benzeri gerçek davranış metriği.
- Son okunan sure/ayet ve `devam et` eylemi.
- Haftalık gün halkaları veya eşdeğer sade görsel gösterge.
- Okuma hedefini düzenleme eylemi.
- Bookmark, vurgu ve notların kaydedildiğini anlatan kısa keşif/onboarding ipucu gerektiğinde gösterilebilir.
- İlerleme ekranı istatistik vitrini değil, `bugün ne yaptım / nerede kaldım / sırada ne var` sorularını cevaplayan işlevsel özet olmalıdır.

## 6. Ezberle

### Ezberle karşılama
- İlk girişte kısa, sade bir tanıtım ekranı kullanılabilir.
- `Başla` ve `Daha sonra` benzeri net seçenekler olabilir.
- Hesap oluşturma zorunluluğu yoktur.

### Ezber ana paneli
Referanstaki ayrı ezber uygulaması ekranından yalnız ezberle ilgili parçalar uyarlanır:

- Bugünkü program.
- Kaldığın yer / sıradaki sayfa veya ayet.
- Genel ezber ilerlemesi.
- Günlük seri.
- Bugünkü tekrar yükü.
- Tekrar kuyruğu.
- Aktif plan veya yöntem adı gerekiyorsa kullanıcıya anlaşılır biçimde gösterilir.

Referanstaki `puan` gibi oyunlaştırma öğeleri şu an ürün kararı değildir; açık kullanıcı onayı olmadan puan/leaderboard/gamification eklenmez. Aynı şekilde ezber paneline namaz kartı doldurmak yerine namaz ana olarak Ana Sayfa akışında kalır.

### Ezber haritası
- Ezber ilerlemesi cüz/sayfa veya uygulamanın gerçek Mushaf eşlemesine göre görsel haritada gösterilebilir.
- Kullanıcı tamamladığı sayfalara dokunarak işaretleyebilir veya durumunu görebilir.
- `X / toplam sayfa`, yüzde ve seri gibi özetler gösterilebilir.
- Toplam sayfa sayısı referans uygulamadaki `603` değerinden kopyalanmaz; bizim kullandığımız gerçek Mushaf/page mapping ne ise o kullanılır.
- Harita cüzlere bölünebilir ve sıradaki çalışma noktası görünür olabilir.

### Ezber çalışma ekranı
- Aynı Mushaf/Reader altyapısı `Oku / Ezber` gibi çalışma modu ayrımını destekleyebilir.
- Sayfa görünümü, liste/odak görünümü ve ses oynatma mevcut Reader/audio altyapısına bağlanır.
- Konuşma tanıma, AI ile doğru/yanlış okuma puanlama veya mikrofonla ezber kontrolü eklenmez.

## 7. Bilinçli olarak kopyalanmayacak / ertelenecek öğeler

Aşağıdaki referans detayları `fotoğrafta var` diye otomatik olarak ürüne alınmaz:

- Zorunlu hesap açma ve sosyal giriş duvarı.
- Başka uygulamanın topluluk/170 milyon kullanıcı gibi pazarlama özellikleri.
- Duaları cihazlar arasında takip etme gibi backend hesabı gerektiren özellikler; mevcut local-first/user-owned-cloud kararına göre ayrıca tasarlanmalıdır.
- Referans uygulamanın özgün illüstrasyonları, tema resimleri, kart kapakları ve metinleri.
- Ayrı Kaynaklar sekmesi; şimdilik kaynaklar içerik yanında gösterilir.
- Puan/leaderboard/gamification.
- OS Günlük Ayet widget’ı; ayrı gelecek platform dilimi olarak değerlendirilir.

## 8. Saatlik otomasyon için kullanım

Saatlik otomasyon UI/ürün işi seçtiğinde:

1. Önce `docs/PRODUCT_STRUCTURE.md` okunur.
2. Sonra bu dosya okunur ve ilgili referans ayrıntısının durumu kontrol edilir.
3. Tek turda yalnız tek küçük ekran/akış dilimi uygulanır.
4. Görselde bulunan ama bu dosyada `bilinçli olarak kopyalanmayacak/ertelenecek` diye işaretlenen bir öğe otomatik eklenmez.
5. Büyük navigasyon veya ürün kararı kullanıcı onayı olmadan değiştirilmez.
6. Yeni referans görsel geldiğinde önemli ayrıntılar önce bu dosyaya işlenir.
