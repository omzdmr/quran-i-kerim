# Kuran Okuyucu Etkileşimleri

Bu belge, Kuran okuyucunun ayet seçme ve işlem davranışını tanımlar. Görsel dil özgün kalır; davranış kalitesi YouVersion benzeri akıcı ve sade olmalıdır.

## 1. Ayet seçimi
- Kullanıcı bir ayete dokunduğunda seçim modu açılır.
- Seçili ayete tekrar dokunmak seçimi kaldırır.
- Aynı sure içinde birden fazla ayet seçilebilir.
- Hem ardışık aralıklar (2:1-3) hem de ayrı ayetler desteklenebilir.
- Seçim sırasında üst bölümde `Seçili: Bakara 2:1-3` benzeri bir referans görünür.
- Seçim modu kapatıldığında normal okuyucu geri gelir.

Not: İlk sürümde seçim ayet bazlıdır. Kelime/karakter bazlı serbest metin boyama gereksiz karmaşıklık yaratacağı için ayrıca değerlendirilir.

## 2. Vurgulama / renklendirme
- Seçili ayet(ler) sarı, yeşil, mavi, turuncu, pembe gibi bir renkle vurgulanabilir.
- Vurgular local-first olarak cihazda saklanır.
- Renk kaldırma desteği bulunur.
- Aynı vurgu hem Arapça hem meal görünümünde aynı ayet referansına bağlı kalır.

## 3. Alt işlem tepsisi
Seçim açıkken yatay kaydırılabilir sade bir işlem tepsisi gösterilir:

- Renk
- Kaydet
- Not
- Kopyala
- Paylaş
- Görüntü (daha sonra)
- Karşılaştır (birden fazla meal olduğunda)
- Dua olarak kaydet (dua modülü hazır olduğunda)

Henüz çalışmayan özellik üretim arayüzünde sahte/etkisiz düğme olarak gösterilmez.

## 4. Kopyalama biçimi
Seçilen ayet veya ayetler tek parça olarak panoya kopyalanır. Meal aktifse örnek biçim:

```
“...seçilen meal metni...”
Bakara 2:1-2 · RWD
```

Arapça + meal modunda paylaşım/kopyalama ayarından Arapça, meal veya ikisi seçilebilir. Uygulamanın gerçek deep-link alan adı hazır olduğunda en alta bağlantı eklenir; sahte URL üretilmez.

## 5. Kaydet
- Tek veya birden fazla seçili ayet kaydedilebilir.
- Kaydetme internet veya hesap gerektirmez.
- `Siz > Kaydedilen Ayetler` bölümünden erişilir.

## 6. Notlar
- Tek ayete veya seçili ayet aralığına not eklenebilir.
- Not ekranında seçilen ayet/meal alıntısı ve referansı görünür.
- Not varsayılan olarak özeldir ve cihazda saklanır.
- İleride hesap/senkronizasyon geldiğinde kullanıcı açıkça istemedikçe paylaşılmaz.

## 7. Dua olarak kaydet
Bu özellik Kuran çekirdeği tamamlandıktan sonra eklenir.
- Seçili ayet/meal bir dua/tefekkür girdisine bağlanabilir.
- Kullanıcı kendi kısa notunu ekleyebilir.
- İsteğe bağlı günlük hatırlatıcı kurulabilir.
- Bildirim izni yalnızca kullanıcı hatırlatıcıyı açtığında istenir.

## 8. Sonraki özellikler
- Ayet görseli oluşturma
- Meal karşılaştırma
- Sesli tekrar
- Tefsir
- Hafızlık/ezber entegrasyonu

Bu özellikler çekirdek okuyucu ve offline meal deneyimini geciktirmemelidir.
