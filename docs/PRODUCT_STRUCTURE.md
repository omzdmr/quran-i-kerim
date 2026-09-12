# Ürün Yapısı ve Ekran Haritası

Bu dosya, ürün navigasyonu ve ana ekran yerleşimi için kaynak of truth'tur. Yeni ekran, sekme veya büyük ürün alanı eklemeden önce bu yapı korunmalıdır. Referans alınan ekran görüntülerindeki UX fikirleri uyarlanır; başka bir uygulamanın görsel varlıkları, metinleri veya marka dili kopyalanmaz.

## 1. Ana alt navigasyon

Alt navigasyon sabit olarak beş ana alandan oluşur:

1. **Ana Sayfa**
2. **Kur’an**
3. **Planlar**
4. **Keşfedin**
5. **Siz**

**Namaz ayrı bir alt sekme değildir.** Namaz vakitleri Ana Sayfa'da güçlü bir kart/özet olarak yer alır; karta dokununca tam Namaz ekranı açılır. Kıble, bildirim ve vakit ayarları bu akışın içinden erişilir.

## 2. Ana Sayfa

Ana Sayfa bir vitrin değil, kullanıcının kaldığı işe döndüğü devam merkezi olmalıdır. Öncelik sırası bağlama göre dinamik olabilir ancak ana bloklar şunlardır:

- Sıradaki namaz ve kalan süre
- Kur’an'da son okunan yer / devam et
- Aktif okuma planı veya günlük hedef
- Öğren'de devam et
- Ezber özeti / bugünkü tekrar
- Zikirler veya kısa yardımcı araçlar
- Gerektiğinde kaynaklı günlük içerik / makale

Kartlar büyük, sade ve nefes alan bir hiyerarşide olmalıdır. Aynı anda çok sayıda eşit ağırlıklı kart gösterilmemelidir.

## 3. Kur’an alanı

Kur’an ekosistemi üç ana deneyimden oluşur:

- **Oku**
- **Öğren**
- **İlerlemem**

Bu üçlü yeni bir alt uygulama navigasyonu değil, Kur’an alanının kendi iç organizasyonudur. Ana beşli alt navigasyon değişmez.

### 3.1 Oku

Mevcut Reader ana okuma deneyimidir. İçerik sırası:

1. Arapça
2. Transliterasyon
3. Seçili meal

Ayet işlemleri:

- Dinle
- Not
- Kaydet
- Vurgula
- Karşılaştır
- Paylaş

Reader'ın mevcut mini-player, kaynak seçimi, dipnot, not/bookmark/vurgu, son okunan yer ve sayfa/cüz/sure navigasyonu davranışları korunur.

## 4. Öğren

Öğren alanı üç ana içerik katmanına ayrılır:

- **Dersler**
- **Ezberle**
- **Makaleler**

Ayrı bir “Kaynaklar” sekmesi zorunlu değildir. Kaynak şeffaflığı her içerikte, açıklamanın veya hadisin yanında gösterilir.

### 4.1 Dersler

Bir ders mümkün olduğunda şu akışı izler:

1. Sure / konu tanıtımı
2. İlgili ayet
3. Arapça metin
4. Transliterasyon
5. Seçili meal
6. Kaynaklı açıklama / dipnot
7. Varsa doğrulanmış ilgili hadis veya kaynak
8. Kısa bilgi incelemesi
9. Mini quiz
10. Ders özeti / tamamlandı durumu
11. `Kur’an’da devam et` veya derslere dönüş

Dini açıklama, hadis veya sure bilgisi uydurulmaz. Yalnız doğrulanabilir kaynaklar kullanılır.

### 4.2 Ezberle

Ezber akışı Öğren alanı içinde görünür ancak davranış olarak bağımsızdır. Konuşma tanıma veya AI ile ezber doğrulaması yoktur.

Önerilen yapı:

- Aktif ezber planı
- Kaldığın yer
- Bugünkü tekrar
- Tekrar kuyruğu
- Ezber ilerlemesi
- Seri
- Ezber haritası / görsel ilerleme
- Ayet veya sayfa çalışma ekranı

### 4.3 Makaleler

Makaleler kaynaklı, editoryal ve sınırlı kapsamda tutulur. Öğren alanını destekler; uygulamayı içerik çöplüğüne çevirmemelidir. Keşfedin alanından da erişim verilebilir ancak içerik kaynağı tek olmalıdır.

## 5. İlerlemem

Kur’an alanındaki İlerlemem ekranı kullanıcının okuma ve plan ilerlemesini özetler.

Ana kartlar:

- Son okunan yer
- Günlük / haftalık okuma hedefi
- Okuma serisi
- Hatim ilerlemesi
- Aktif planlar
- Yer imleri ve notlar özeti
- Ezber özeti

Ezberin ayrıntılı yönetimi Öğren > Ezberle içinde kalır; İlerlemem yalnız özet ve geçiş noktası olabilir.

## 6. Planlar

Planlar ana alt navigasyonda ayrı kalır. Okuma planları, hatim hedefleri ve gelecekteki yapılandırılmış rutinler burada yönetilir. Planlar ekranı Öğren ve Ezber ekranlarının yerine geçmez.

## 7. Keşfedin

Keşfedin yardımcı ve keşif odaklı içerikleri düzenli kategoriler halinde toplar. Örnekler:

- Zikirler
- Kıble
- Makaleler / rehber içerikler
- Öne çıkan dersler
- Faydalı dini araçlar

Dağınık bir “her şey” ekranına dönüşmemelidir. Yeni özellik eklenirken önce mevcut kategorilerden birine uyup uymadığı kontrol edilir.

## 8. Siz

Kişisel ve uygulama ayarları burada toplanır:

- Uygulama dili
- Meal / çeviri kaynakları
- İndirmeler
- Reader tercihleri
- Bildirim tercihleri
- Gizlilik / yedekleme seçenekleri
- Gerekli diğer kişisel ayarlar

UI dili ve Kur’an meal dili birbirinden bağımsız kalır.

## 9. Onboarding

Onboarding modern, kısa ve zorlamayan bir akış olmalıdır. Uygulama dili cihaz dilinden bağımsız seçilebilir.

Önerilen adımlar:

- Uygulama dili
- Arapça yazı / görünüm tercihi
- Varsayılan meal
- Okuma hedefi
- İsteğe bağlı ses / okuyucu tercihi

Konum izni ilk açılışta gereksiz yere istenmez. Kullanıcı şehir aramasında sonuç bulamazsa veya otomatik konum isterse açıklamalı şekilde izin istenir.

## 10. Görsel dil

Referans ekranlardan alınan prensipler:

- Koyu yeşil ana kimlik
- Krem ve yumuşak açık tonlarla denge
- Büyük ve okunaklı kartlar
- Geniş boşluk ve güçlü bilgi hiyerarşisi
- Premium ama sakin tipografi
- Koyu tema birinci sınıf deneyim
- Hafif press/ripple ve uygun haptic feedback
- Gereksiz giriş animasyonu yok
- Reader'da metin önceliği
- Düşük güçlü cihazlarda akıcılık

Başka uygulamaların illüstrasyonları, özgün görselleri, metinleri veya marka öğeleri kopyalanmaz.

## 11. Ürün kuralları

- Yeni ana alt sekme eklemek varsayılan çözüm değildir.
- **Namaz alt sekmesi eklenmez.**
- Öğren, Ezberle ve Makaleler ana alt navigasyona taşınmaz.
- Yeni ekran önce bu ekran haritasında doğal bir yere yerleştirilir.
- Saatlik otomasyon ürün/navigation değişikliği yapmadan önce bu dosyayı kontrol etmelidir.
- Local-first/offline-first yaklaşım korunur.
- TTS kullanılmaz.
- Kaynaksız dini açıklama eklenmez.
- UI dili ile meal dili ayrı tutulur.
- Android şu an ana CI/test platformudur; ortak Flutter kodu iOS uyumunu bozmayacak şekilde yazılır.

## 12. Geliştirme sırası

Ürün iskeleti bir defada büyük refactor ile uygulanmaz. Güvenli sıra:

1. Mevcut CI ve kritik buglar yeşil tutulur.
2. Bu ekran haritası kaynak of truth olarak korunur.
3. Kur’an alanına Oku / Öğren / İlerlemem iskeleti küçük dilimlerle eklenir.
4. Öğren içinde Dersler / Ezberle / Makaleler iskeleti kurulur.
5. Onboarding tercihleri iyileştirilir.
6. Ezber haritası ve ilerleme ekranları gerçek local veriye bağlanır.
7. Görsel polish ve design-system tokenları ayrı stabilizasyon dilimlerinde yapılır.

Her dilimde lokalizasyon, testler ve mevcut Android CI korunmalıdır.
