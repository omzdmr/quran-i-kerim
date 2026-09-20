# Referans Görsellerden Kodlanan Görsel İskeletler

Bu dosya, kullanıcının gönderdiği referans ekranlardan insan gözüyle çıkarılan ve doğrudan Flutter bileşenine dönüştürülen görsel davranışları listeler. Amaç saatlik otomasyonun ekran görüntülerini görmesine ihtiyaç bırakmadan, teknik veri/kaynak katmanını sonradan bu hazır sunum bileşenlerine bağlamaktır.

## Hazır görsel bileşenler

### Onboarding
`lib/src/features/onboarding/presentation/quran_onboarding_visual_flow.dart`

- Üstte ince ilerleme çizgisi.
- Tek karar isteyen büyük başlık ve isteğe bağlı canlı önizleme alanı.
- Büyük, dokunması kolay seçenek kartları.
- Seçili kartta belirgin fakat sakin çerçeve ve onay işareti.
- Altta sabit birincil CTA ve isteğe bağlı “daha sonra” eylemi.
- Referanstaki font/meal/hedef/okuyucu adımlarının aynı bileşenle kurulabilmesi için veri bağımsız tasarım.
- Zorunlu hesap veya izin duvarı yok.

Saatlik teknik görev: bu yüzeyi ilk-kurulum state’i, gerçek Arabic font seçenekleri, TranslationCatalog, okuma hedefi persistence ve doğrulanmış insan sesli audio katalogu ile bağlamalıdır. Görsel bileşeni yeniden tasarlamamalıdır.

### Öğren / Ezber ilk giriş karşılama
`lib/src/features/learn/presentation/feature_welcome_screen.dart`

- Öğren ve Ezber için ortak, tekrar kullanılabilir tam ekran ilk-giriş yüzeyi.
- Koyu zümrüt → morumsu geçiş, ortada özgün rozet/ikon alanı, geniş nefes boşluğu.
- Tek birincil CTA + isteğe bağlı ikincil “daha sonra” davranışı.
- Zorunlu hesap, sosyal giriş veya backend bağımlılığı UI’ın içine gömülmez.
- Başlık, açıklama, ikon ve CTA metinleri tamamen çağıran katmandan gelir; dini metin hardcode edilmez.

Saatlik teknik görev: ilk-açılış state’ini local persistence ile tutup Öğren/Ezber girişlerinde bu yüzeyi bir kez gösterebilir. Görsel kompozisyonu yeniden tasarlamamalıdır.

### Okuma hedefi
`lib/src/features/quran/presentation/reading_goal_selector.dart`

- 5/10/15 dakika gibi hedeflerin büyük kartlarla seçilebildiği üretim-hazır selector.
- Progress ekranındaki “hedefi düzenle” ve onboarding hedef adımı aynı bileşeni kullanabilir.
- Görsel bileşen süre/ayet tahminini kendi uydurmaz; başlık ve açıklamayı çağıran katman verir.

### İlerlemem yardımcı panelleri
`lib/src/features/quran/presentation/progress_reference_panels.dart`

- Kaydedilen / not / vurgu öğelerini tek sakin bilgi şeridinde anlatan `QuranProgressArchiveBanner`.
- Günlük okuma hedefini özetleyip mevcut selector’a taşıyacak `QuranReadingGoalCard`.
- İki panel de text/state üretmez; bütün label, count ve callback’ler çağıran katmandan gelir.

Saatlik teknik görev: hedefi local settings’e kaydetmeli; tahmini ayet/gün hesabını tek test edilebilir fonksiyonda üretmeli, hedef kartını İlerlemem ekranına ve gerekirse Planlar’a bağlamalıdır. Archive banner gerçek bookmark/not/vurgu sayaçlarını kullanmalıdır.

### Öğren ders akışı
`lib/src/features/learn/presentation/lesson_visual_flow.dart`

- Üstte ders adı + ince adım ilerleme çizgisi + kapatma.
- Tanıtım, ayet, meal, açıklama, hadis, bilgi incelemesi, quiz, özet ve tamamlanma için tek veri-güdümlü akış.
- Arapça / transliterasyon / gövde / kaynak referansı için ayrı görsel alanlar.
- Mini quiz’de cevap seçimi, doğru/yanlış renk geri bildirimi.
- Önceki/sonraki gezinme.
- Ders sonunda “Derslere dön” ve “Kur’an’da devam et” iki eylemi.
- Referans uygulamanın çöl/orman illüstrasyonları kopyalanmadı; kendi gradient/kart dili kullanıldı.

Saatlik teknik görev: yalnız doğrulanmış kaynaklı lesson package/model üretip bu bileşene veri vermeli; dini metni UI dosyasına hardcode etmemelidir. LearnProgressStore ile step completion bağlanmalıdır.

### Makale grid’i ve önizleme bölümü
`lib/src/features/learn/presentation/article_grid.dart`

- Telefon genişliğinde iki sütun, geniş ekranda üç sütun.
- Kapak varsa görsel; yoksa uygulamanın kendi gradient/ikon yüzeyi.
- Kategori, başlık ve kısa özet hiyerarşisi.
- `LearnArticleSection`, referanstaki “birkaç içerik + Hepsini gör” düzenini hazırlar; preview count ve see-all callback dışarıdan gelir.
- Veri ve lisans kararları sunum bileşeninden tamamen ayrıdır.

Saatlik teknik görev: yalnız kaynak/lisansı doğrulanmış makale kataloğunu bağlamalıdır. Sonsuz haber akışı veya rastgele web içeriği eklememelidir.

### Ezber ana paneli
`lib/src/features/learn/presentation/memorization_dashboard_panel.dart`
`lib/src/features/learn/presentation/memorization_overview.dart`

- Bugünün programı ve halka ilerleme.
- Kaldığın yer kartı.
- Ezberlenen/total sayfa ilerlemesi.
- Seri ve bugünkü tekrar kartları.
- Ezber Haritasına belirgin geçiş.
- Referanstaki “buradan başla” mantığını taşıyan, bugün / sıradaki sayfa / tekrar sırasını gösteren numaralı başlangıç rehberi artık overview içinde görünür.
- Toplam sayfa sayısı veri olarak gelir; referans uygulamadaki 603 değeri UI kararı olarak kopyalanmaz.

Panel gerçek local memorization state ile kullanılmaktadır. Tekrar kuyruğu henüz teknik katman tarafından doldurulmadığı için görsel kabuk bunu uydurmaz.

### Ezber çalışma ekranı
`lib/src/features/learn/presentation/memorization_study_scaffold.dart`
`lib/src/features/learn/presentation/memorization_study_screen.dart`

- Referanstaki Mushaf çalışma yüzeyinden türetilen `Oku / Ezberle` geçişi.
- Krem Mushaf yüzeyi, üstte sure adı ve cüz/sayfa/ayet aralığı meta şeridi.
- Oku modunda sayfadaki ayetler açık şekilde gösterilir.
- Ezberle modunda ayetler gizlenir ve kullanıcı ayet kartına dokunarak tek tek açabilir.
- Alt bölümden sayfa ezberlendi olarak işaretlenebilir; local ezber haritası anında güncellenir.
- Ezber Haritasında sayfaya normal dokunma çalışma ekranını açar, uzun basma hızlı durum değiştirir.
- Ayrı bir audio bar görsel bileşeni hazırdır; oynatma motoru bağlanmadan sahte oynatma durumu gösterilmez.

Saatlik teknik görev: mevcut ses controller’ını, gerçek tekrar kuyruğunu ve ileride gerekli çalışma davranışlarını bu yüzeye bağlayabilir. `Oku / Ezberle` hiyerarşisini, Mushaf ağırlıklı görünümü veya harita etkileşim modelini yeniden tasarlamamalıdır.

## Mevcut ekranda zaten uygulanmış referans fikirleri

- Kur’an alanı: Oku / Öğren / İlerlemem ve Kur’an’a dokununca varsayılan Oku.
- Öğren: Dersler / Ezberle / Makaleler iç organizasyonu.
- İlerlemem: Okuma/Hatim, son okunan, 7 günlük halkalar, kaydedilen/not/vurgu özeti.
- Ezber: referans-türetilmiş dashboard, numaralı başlangıç rehberi, sayfa bazlı local progress, Ezber Haritası ve canlı Oku/Ezberle çalışma ekranı.

## Teknik katmanın değiştirmemesi gereken görsel kararlar

- Ana alt navigasyon beşli kalır: Ana Sayfa / Kur’an / Planlar / Keşfedin / Siz.
- Namaz ayrı alt sekme değildir.
- Referans uygulama illüstrasyonları veya marka öğeleri kopyalanmaz.
- Öğren içerikleri tek uzun makale değil, adım adım deneyimdir.
- Quiz hafif geri bildirim verir; puan/leaderboard gamification eklenmez.
- Onboarding her ekranda bir ana karar ister.
- Reader’da metin kontrollerden daha baskın kalır.
