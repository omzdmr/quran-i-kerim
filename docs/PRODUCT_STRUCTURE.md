# Ürün Yapısı ve Ekran Haritası

Bu dosya, ürün navigasyonu ve ana ekran yerleşimi için kaynak of truth'tur. Yeni ekran, sekme veya büyük ürün alanı eklemeden önce bu yapı korunmalıdır. Referans alınan ekran görüntülerindeki UX fikirleri uyarlanır; başka bir uygulamanın görsel varlıkları, metinleri veya marka dili kopyalanmaz.

## Referans görseller hakkında

Saatlik otomasyon sohbet içinde geçmişte yüklenen referans ekran görüntülerini güvenilir biçimde tekrar göremez. Bu nedenle kullanıcı tarafından onaylanmış görsel kararlar bu dosyada yazılı ürün kurallarına dönüştürülmüştür. UI üzerinde çalışan her otomatik tur, görselleri hatırladığını varsaymak yerine bu dosyayı okumalıdır.

Yeni bir referans görsel kullanıcı tarafından manuel sohbette onaylandığında, önemli yerleşim veya görsel kararlar önce bu dosyaya aktarılmalı; ancak ondan sonra saatlik otomasyonun o tasarım yönünü sürdürmesine güvenilmelidir.

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

Referans ekranlardan alınan davranış: Ana Sayfa'daki en önemli kartlar kullanıcının bir sonraki eylemini açıkça göstermelidir. Dekoratif kart sayısını artırmak yerine `devam et`, `sıradaki namaz`, `bugünkü hedef` gibi eylemler öne çıkarılmalıdır.

## 3. Kur’an alanı

Kur’an ekosistemi üç ana deneyimden oluşur:

- **Oku**
- **Öğren**
- **İlerlemem**

Bu üçlü yeni bir alt uygulama navigasyonu değil, Kur’an alanının kendi iç organizasyonudur. Ana beşli alt navigasyon değişmez.

### Kur’an sekmesine basıldığında varsayılan davranış

**Alt navigasyondaki Kur’an sekmesine dokunulduğunda doğrudan Oku/Reader açılır.** Araya ayrı bir karşılama, hub, seçim sayfası veya `ne yapmak istersiniz?` ekranı konmaz. `Oku` başlangıçta seçili olmalıdır.

`Oku / Öğren / İlerlemem` geçişi Reader çevresinde bulunabilir, fakat Kur’an sekmesinin temel görevi hızlıca okumaya dönmektir. Ana Sayfa'daki `Kur’an'da devam et` gibi yönlendirmeler de her zaman Oku/Reader bölümünü hedeflemelidir.

Bu kural açık kullanıcı kararıdır; saatlik otomasyon bunu kendiliğinden değiştirmemelidir.

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

Reader ekranında referans görsellerden alınan temel ilke `metin önce` yaklaşımıdır. Kontroller Kur’an metninden daha baskın görünmemeli; okuma yüzeyi sakin kalmalıdır.

## 4. Öğren

Öğren alanı üç ana içerik katmanına ayrılır:

- **Dersler**
- **Ezberle**
- **Makaleler**

Ayrı bir “Kaynaklar” sekmesi zorunlu değildir. Kaynak şeffaflığı her içerikte, açıklamanın veya hadisin yanında gösterilir.

Öğren ana ekranında referans görsellerdeki gibi güçlü bir üst tanıtım/ilerleme alanı ve altında birkaç büyük, belirgin giriş kartı kullanılabilir. Kartlar birbirleriyle yarışan küçük kutulara dönüşmemelidir. Kullanıcı bir bakışta `Dersler`, `Ezberle`, `Makaleler` arasındaki farkı anlamalıdır.

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

Referans ekranlardan alınan UX prensibi: ders, tek uzun makale gibi davranmamalıdır. İçerik küçük ve anlaşılır adımlara bölünmeli; kullanıcı ilerlediğini hissetmeli; ders sonunda kısa bir tamamlanma/özet durumu bulunmalıdır.

Mini quiz hafif ve öğretici olmalı, sınav hissi yaratmamalıdır. Yanlış cevap üzerinden dini hüküm veya içerik uydurulmaz.

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

Referans görsellerdeki `harita/yol` hissi birebir kopyalanmadan kullanılabilir: ilerleme yalnız yüzde veya sayı ile değil, bölümlerin tamamlanmasını gösteren görsel bir yol/harita ile de anlatılabilir. Bu görsel ilerleme dekoratif olmaktan çok durum göstermelidir.

Ezber çalışma ekranı sakin ve odaklı olmalıdır. Sesli okuma yararlı olabilir fakat konuşma tanıma ile `doğru okudun/yanlış okudun` değerlendirmesi yapılmaz.

### 4.3 Makaleler

Makaleler kaynaklı, editoryal ve sınırlı kapsamda tutulur. Öğren alanını destekler; uygulamayı içerik çöplüğüne çevirmemelidir. Keşfedin alanından da erişim verilebilir ancak içerik kaynağı tek olmalıdır.

Referans ekranlardan alınan kart düzeni kullanılabilir: kapak/ikon, kısa başlık, kısa açıklama ve net bir devam eylemi. Sonsuz haber akışı görünümü hedeflenmez.

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

Referans görsellerden alınan prensipler:

- Günlük/haftalık durum halka veya benzeri basit görsel göstergelerle okunabilir hale getirilebilir.
- Kullanıcı `bugün ne yaptım`, `nerede kaldım`, `sırada ne var` sorularının cevabını aynı ekranda görebilmelidir.
- İstatistik gösterisi yerine davranışı destekleyen özet tercih edilir.

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

Referans ekranlardan alınan UX prensipleri:

- Her adım tek bir karar istemeli; aynı ekrana çok fazla ayar yığılmamalıdır.
- Seçenekler dokunması kolay, büyük kartlar veya belirgin seçenek satırlarıyla sunulmalıdır.
- Kullanıcı ilk açılışta zorunlu hesap, zorunlu indirme veya gereksiz izin duvarına çarpmamalıdır.
- Ses/okuyucu paketi gibi büyük veri indirmeleri opsiyonel ve açık boyut/bekleme bilgili olmalıdır.
- Onboarding tamamlandıktan sonra aynı tercihler Siz/Ayarlar içinden değiştirilebilir olmalıdır.

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

### 10.1 Referans görsellerden çıkarılan somut UI kuralları

- Bir ekranda birincil eylem görsel olarak açık olmalıdır; çok sayıda aynı ağırlıkta CTA kullanılmaz.
- Büyük hero alanları yalnız anlamlı bağlam için kullanılır: Öğren başlangıcı, ilerleme veya önemli devam eylemi. Her ekrana hero eklenmez.
- Kart köşe yuvarlaklıkları, padding ve dikey ritim tutarlı görünmelidir; ancak her bileşene körlemesine tek bir radius uygulanmaz.
- İlerleme görselleri sade, yüksek kontrastlı ve hızlı okunur olmalıdır.
- Ders ve onboarding ekranlarında adım adım ilerleme tercih edilir; uzun form benzeri tek ekranlardan kaçınılır.
- Alt ana navigasyon zaten güçlü bir bileşendir; ekran içi navigasyon onunla görsel olarak rekabet etmemelidir.
- Kur’an/Reader ekranında segment, toolbar ve player gibi yardımcı UI metin alanından daha yüksek görsel ağırlık kazanmamalıdır.
- Mikro etkileşimler kısa ve işlevsel olmalıdır. Büyük giriş animasyonları, sürekli hareket eden dekorasyon veya performans maliyetli efektler eklenmez.
- İllüstrasyon kullanılırsa uygulamanın kendi özgün dili oluşturulur; referans uygulamadaki özgün illüstrasyonlar yeniden çizilmez veya taklit edilmez.

Başka uygulamaların illüstrasyonları, özgün görselleri, metinleri veya marka öğeleri kopyalanmaz.

## 11. Ürün kuralları

- Yeni ana alt sekme eklemek varsayılan çözüm değildir.
- **Namaz alt sekmesi eklenmez.**
- **Kur’an alt sekmesi doğrudan Oku/Reader ile açılır.**
- Öğren, Ezberle ve Makaleler ana alt navigasyona taşınmaz.
- Yeni ekran önce bu ekran haritasında doğal bir yere yerleştirilir.
- Saatlik otomasyon ürün/navigation veya görünür UI değişikliği yapmadan önce bu dosyayı kontrol etmelidir.
- Saatlik otomasyon geçmiş sohbet görsellerini gördüğünü varsaymamalıdır; görsel yön için bu dosyadaki yazılı kuralları kaynak kabul etmelidir.
- Kullanıcıyla manuel sohbette yeni bir görsel karar alınırsa, büyük UI çalışmasına başlamadan önce karar bu dosyaya eklenmelidir.
- Local-first/offline-first yaklaşım korunur.
- TTS kullanılmaz.
- Kaynaksız dini açıklama eklenmez.
- UI dili ile meal dili ayrı tutulur.
- Android şu an ana CI/test platformudur; ortak Flutter kodu iOS uyumunu bozmayacak şekilde yazılır.

## 12. Geliştirme sırası

Ürün iskeleti bir defada büyük refactor ile uygulanmaz. Güvenli sıra:

1. Mevcut CI ve kritik buglar yeşil tutulur.
2. Bu ekran haritası kaynak of truth olarak korunur.
3. Kur’an alanındaki Oku / Öğren / İlerlemem iskeleti küçük dilimlerle geliştirilir; Kur’an'a giriş varsayılanı Oku olarak kalır.
4. Öğren içinde Dersler / Ezberle / Makaleler akışları gerçek yerel veriye ve doğrulanmış içeriğe küçük dilimlerle bağlanır.
5. Onboarding tercihleri iyileştirilir.
6. Ezber haritası ve ilerleme ekranları gerçek local veriye bağlanır.
7. Görsel polish ve design-system tokenları ayrı stabilizasyon dilimlerinde yapılır.

Her dilimde lokalizasyon, testler ve mevcut Android CI korunmalıdır.
