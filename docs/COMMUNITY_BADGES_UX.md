# Topluluk, pasaj önizleme ve rozet UX kararları

Bu belge, YouVersion benzeri davranışlardan yalnızca ürün/UX ilhamı alınarak bizim uygulamaya özgü biçimde uygulanacak kararları kaydeder. Özel kod, görsel veya varlık kopyalanmaz.

## Uzun ayet / pasaj kartları

- Ana Sayfa, Siz arşivi ve ileride Topluluk akışındaki uzun ayet/pasaj kartları tam metni zorla göstermeyecek.
- Kart, birkaç satırlık sakin bir önizleme gösterir; uzun metin gerektiğinde üç nokta ile kısalır.
- Karta dokunmak doğrudan okuyucuyu açmaz. Önce ayrı bir **pasaj ayrıntısı** yüzeyi açılır.
- Pasaj ayrıntısında seçilmiş ayet veya ayet aralığı tam ve okunabilir biçimde gösterilir.
- Alt bölümde kaynak/meal bilgisi, varsa telif/attribution ve **Tüm sureyi oku** eylemi bulunur.
- **Tüm sureyi oku** seçilirse Kuran okuyucu ilgili sure ve ayete gider.
- Bu ara yüzey, kullanıcının akıştan çıkmadan metni okuyabilmesini sağlar.

## Topluluk sekmesi: önce yerel aktivite

- Arkadaş sistemi gelmeden önce Topluluk sekmesi boş placeholder olmak zorunda değildir.
- Kullanıcının kendi yerel aktiviteleri burada gösterilebilir:
  - ayet/pasaj kaydetme,
  - vurgu,
  - not ekleme,
  - okuma planı günü tamamlama,
  - seri/streak kilometre taşı,
  - rozet kazanma.
- Bu ilk sürüm tamamen cihaz içi olabilir; backend gerektirmez.
- Aktivite kartları kronolojik olarak en yeni üstte gösterilir.
- Aynı anda seçilen çoklu ayet tek aktivite olmalıdır, ör. `Bakara 2:255-257 kaydedildi`.
- Özel not metninin kendisi varsayılan olarak Topluluk akışına konmaz. Gerekirse yalnızca `not eklendi` aktivitesi gösterilir.

## Topluluk bildirim noktası

- Topluluk başlığının yanında küçük bir durum noktası kullanılabilir.
- Kullanıcı son Topluluk ziyaretinden sonra yeni yerel aktivite veya ileride arkadaş aktivitesi oluştuysa nokta görünür.
- Kullanıcı Topluluk sekmesini açınca yeni içerikler görülmüş kabul edilir ve nokta söner.
- Bu davranış kırmızı aciliyet/bağımlılık tasarımı gibi kullanılmaz; sakin accent tonu yeterlidir.
- İleride arkadaş sistemi geldiğinde nokta; yeni arkadaş aktivitesi, yorum veya arkadaşlık isteği için de kullanılabilir.

## Arkadaş sistemi geldiğinde

- Halka açık sosyal ağ olmayacak.
- Yalnız kabul edilmiş arkadaşların aktiviteleri görülebilir.
- Arkadaş aktiviteleri kronolojik feed olarak gösterilir; algoritmik keşfet/viral sıralama yoktur.
- Arkadaş ekleme, kabul/ret, kaldırma, engelleme ve gizlilik backend tarafında yetkilendirilir.
- Yorum ve reaksiyonlar yalnız yetkili arkadaşlar arasında çalışır.
- Kullanıcı hangi aktivite türlerinin paylaşılacağını kontrol edebilmelidir.
- Notların içeriği varsayılan olarak özel kalır.

## Rozetler

Rozet sistemi eklenebilir fakat ibadeti puanlayan veya dindarlık skoru üreten bir sistem olmayacak.

İlk uygun rozet örnekleri:

- İlk ayet vurgusu
- İlk kayıt
- İlk not
- İlk tamamlanan okuma planı
- 3 / 7 / 30 günlük okuma serisi
- 7 farklı günde Kuran okuma
- Bir sureyi tamamlayarak okuma
- Bir cüzü tamamlayarak okuma
- Belirli sayıda plan günü tamamlama
- Zikirmatikte kişisel hedefe ulaşma

Kurallar:

- Rozetler davranış kilometre taşıdır; **iman seviyesi**, `Allah'a yakınlık`, sevap puanı veya benzeri dinî hüküm ima etmez.
- Kullanıcı uygulamayı açtığında rozet yağmuru/konfetiyle rahatsız edilmez. Küçük haptic + sakin kısa animasyon yeterlidir.
- `Siz` ekranında **Rozetler** kartı ve kazanılan/toplam sayı gösterilebilir.
- Rozete dokununca adı, ne için kazanıldığı ve kazanılma tarihi gösterilir.
- Henüz kazanılmamış rozetler isteğe bağlı olarak silik biçimde gösterilebilir; utandırıcı `eksik` dili kullanılmaz.
- Arkadaş sistemi geldiğinde rozet paylaşımı varsayılan olarak kontrollü olmalı; kullanıcı isterse paylaşır.

## Öncelik

1. Çoklu dil ve meal indirme hatalarını düzelt.
2. Sabit test signing ile gerçekten güncellenebilir APK üret.
3. Cihaz diline göre varsayılan meal seçimini ekle.
4. Ana Sayfa/Namaz/Zikir kalan sabit Türkçe metinleri temizle.
5. Uzun pasaj için detay yüzeyi ekle.
6. Yerel Topluluk aktivite akışı + yeni içerik noktası.
7. Hafif rozet sistemi.
8. Hesap/senkron geldikten sonra arkadaşlar, yorumlar ve kontrollü paylaşım.
