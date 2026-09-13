# Hıfz / Ezber Sistemi

Bu doküman, Ezberle alanının günlük plan motorunu ve öğretim akışını tanımlar. Amaç tek bir hocanın markalı metodunu kopyalamak değil; geleneksel hıfz programlarında ortak görülen `yeni ezber + yakın tekrar + eski tekrar` omurgasını, modern hafıza araştırmasındaki retrieval practice ve spaced practice ilkeleriyle birleştirmektir.

## Araştırma sonucu

### Geleneksel ortak omurga
Birçok hıfz programı günlük çalışmayı üç parçaya ayırır:

- **Sabaq / Sabak:** Bugünün yeni ezberi.
- **Sabqi / Sabqee:** Yakın zamanda ezberlenen ve hâlâ kırılgan olan bölümün tekrarı.
- **Manzil / Daur:** Daha eski ezberlerin döngüsel tekrarı.

Kaynak örnekleri:
- Hifz Academy: https://www.hifzacademy.org/academics/quran.cfm
- Hidayah Quran: https://hidayahquran.com/courses/hifz
- Hufaaz: https://hufaaz.com/blog/quran-hifz-revision-schedule/
- The Hifz Project: https://thehifzproject.com/articles/sabaq-sabqi-manzil

Hidayah Quran örneğinde hafta içindeki yeni dersler yakın ve eski tekrarlarla birlikte yürütülüyor; haftanın bir gününde yeni ezber durdurulup haftalık bölüm topluca test ediliyor. Ürünümüzde bu fikir **haftalık sağlamlaştırma günü** olarak genellenir; belirli bir dini veya kültürel güne sabitlenmez.

### Hafıza bilimiyle uyumlu taraf
Hafızadan geri çağırma (retrieval practice), aynı içeriği yalnız tekrar tekrar okumaya göre uzun dönem hatırlamayı güçlendirebilir. Aralıklı tekrar da sıkıştırılmış tek oturuma göre kalıcılığı artırma eğilimindedir.

Kaynaklar:
- Roediger & Butler, retrieval practice review: https://doi.org/10.1016/j.tics.2010.09.003
- Smith & Scarf, spacing review: https://pmc.ncbi.nlm.nih.gov/articles/PMC5476736/
- Trumble et al., distributed/retrieval practice systematic review: https://pubmed.ncbi.nlm.nih.gov/37615780/

Bu nedenle uygulama yalnız `dinle/oku` sayacı tutmaz; kullanıcıyı metin kapalıyken aktif hatırlamaya geçirir ve tekrarı günlere yayar.

### 604 sayfalık planlama temeli
King Fahd Qur'an Printing Complex dijital Medine Mushafı 604 sayfadır. Quran Foundation da QCF/Medine düzenlerinde 604 sayfa kullanır.

- King Fahd Complex: https://qurancomplex.gov.sa/en/kfgqpc/kfq-structure/
- Quran Foundation page layouts: https://api-docs.quran.com/docs/tutorials/fonts/page-layout/

Bu sayı yalnız 604 sayfalık Medine Mushaf eşlemesi seçiliyken planlama temeli olur. Başka Mushaf düzeninde page catalog gerçek toplamı sağlamalıdır.

## Ürün kararı: üç tempo

Tam Kur'an hedefi için üç hazır tempo bulunur. Hepsi 6 yeni-ezber günü + 1 haftalık sağlamlaştırma günü kullanır.

| Plan | Yeni sayfa deseni / 7 gün | Haftalık kapasite | Yaklaşık kapasite |
| --- | --- | ---: | ---: |
| 12 ay yoğun | 2,2,2,2,2,2,0 | 12 | 52 haftada 624 |
| 18 ay dengeli | 2,1,1,2,1,1,0 | 8 | 78 haftada 624 |
| 24 ay sakin | 1,1,1,1,1,1,0 | 6 | 104 haftada 624 |

Son hafta 604'te kesilir. Bu süreler **garanti değildir**. Kullanıcının kıraat doğruluğu, öğretmen kontrolü, kaçırılan günler ve zor pasajlar tempoyu değiştirebilir. Başlangıç seviyesinde tam sayfa yerine satır/ayet bazlı hedef gerekebilir.

## Günlük iş sırası

Normal yeni-ezber gününde sıra:

1. **Eski tekrar / Manzil**: Önceden sağlamlaştırılmış bölümden döngüsel parça.
2. **Yakın tekrar / Sabqi**: Son 7 günün yeni ezberleri.
3. **Bugünün yeni ezberi / Sabaq**.
4. **Bağlantı provası**: Yeni kısmı hemen öncesindeki ayet/sayfayla birleştirerek okumak.
5. **Kısa öz değerlendirme**: `Zorlandım / Yardım aldım / Yardımsız okudum`.

Haftalık sağlamlaştırma gününde yeni sayfa yoktur. O haftanın yeni ezberleri baştan sona tekrar edilir; yakın ve eski tekrar devam eder. Kullanıcı belirgin biçimde zorlanıyorsa yeni ezber yükü otomatik olarak azaltılabilir veya geçici durdurulabilir.

## Yeni bir ayet/sayfa nasıl öğretilir?

Referans akış:

1. Metne bakarak doğru okuma. Başlangıç için 5–10 dikkatli okuma aralığı önerilebilir; sabit kutsal sayı değildir.
2. Seçili insan okuyucudan aynı bölümü 3–5 kez dinleme.
3. Uzun ayeti doğal durak/ifade parçalarına bölme.
4. Parçaları zincirleme: A, B, sonra A+B; ardından C ve A+B+C.
5. Mushaf kapalıyken en az 3 temiz geri çağırma denemesi hedefleme.
6. Önceki ayet/satır ile geçiş provası.
7. Mümkünse öğretmen/hoca kontrolü; yoksa kullanıcı kendi kaydını dinleyip Mushaf ve seçili kâri ile karşılaştırabilir.

Tek bir tekrar sayısı herkese zorunlu tutulmaz. Uygulama tekrar sayısını kullanıcının zorlanmasına göre artırabilir.

## Tekrar zamanlaması

Yeni ezber için başlangıç politikası:

- İlk **7 gün**: yakın tekrar havuzunda her gün görülür.
- **14. gün**: ek sağlamlaştırma kontrolü.
- **30. gün**: ek sağlamlaştırma kontrolü.
- Sonrasında eski tekrar / Manzil döngüsünde kalır.

Bu 7/14/30 ayrımı geleneksel günlük yakın tekrar yaklaşımı ile aralıklı tekrar ilkesini birleştiren ürün varsayılanıdır; dini bir kural veya tek doğru hıfz metodu olarak sunulmaz.

Eski tekrar döngüsü plan temposuna göre yaklaşık 2–4 aylık pencereyi hedefler. Günlük eski tekrar yükü kullanıcının gerçekten ezberlediği sayfa miktarına göre hesaplanır ve ağırlaştığında yeni ezberden önce korunur.

## Ezber durumları

Her sayfa/ayet için sunum katmanı şu durumları kullanabilir:

- `Yeni`
- `Öğreniliyor`
- `Yakın tekrarda`
- `Eski tekrarda`
- `Sağlam`

Durum yalnız kullanıcının `ezberledim` işaretine bağlı kalmamalı; son başarılı geri çağırma tarihi ve öz değerlendirme de hesaba katılmalıdır.

## Ezber kontrolü ve mikrofon

İlk sürümde otomatik `doğru/yanlış kıraat` hakemliği yapılmaz. Genel konuşma tanıma Kur'an Arapçasında kıraat ve tecvid doğruluğunu güvenilir biçimde değerlendirmek için yeterli kabul edilmez.

Güvenli ilk sürüm:
- Kullanıcı metin kapalıyken okur.
- İsterse cihazda kendi sesini kaydeder.
- Kendi kaydını seçili insan kârinin kaydıyla ve Mushaf ile karşılaştırır.
- Sonunda kendi durumunu `Zorlandım / Yardım aldım / Yardımsız okudum` olarak seçer.

Gelecekte bir ses eşleme sistemi eklenirse yalnız beklenen ayet içinde kelime atlama/sıra gibi yardımcı sinyaller verebilir. Bu özellik **tecvid değerlendirmesi** veya dini otorite gibi sunulmaz.

## Dr. Mac etiketi

Gönderilen referans ekranında `Dr. Mac` etiketi görülüyor; yapılan web araştırmasında bu adla doğrulanabilir, açıkça yayımlanmış bir Kur'an ezber metodolojisi bulunamadı. Bu nedenle ürün `Dr. Mac yöntemi` markasını kullanmaz. Referanstan alınan yararlı fikir yalnız günlük planın `yeni ezber + tekrar + ilerleme` şeklinde görünür olmasıdır.

## Saatlik otomasyon için teknik işler

- `memorization_plan_engine.dart` içindeki planları local persistence ile bağla.
- Kullanıcının plan başlangıç tarihi, tercih ettiği tempo ve kaçırdığı günleri sakla.
- Sayfa bazında `memorizedAt`, `lastReviewedAt`, öz değerlendirme/strength ve gerekiyorsa `deletedAt` metadata ekle.
- Günlük `yeni / yakın / eski / sağlamlaştırma` kuyruğunu local-first üret.
- Yeni ezber, yakın tekrar veya eski tekrar geri kalmışsa yükü otomatik dengele; eski tekrarı feda ederek yeni sayfa vermeye devam etme.
- Tasarımı yeniden icat etme; plan seçici ve çalışma yüzeylerini mevcut yeşil/krem görsel sistemle bağla.
