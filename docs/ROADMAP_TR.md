# Kur’an-ı Kerim — Ürün Yol Haritası

Bu dosya konuşmalarda alınan ürün kararlarını kalıcı tutar. Amaç, çekirdek geliştirme sırasında iyi fikirleri kaybetmeden kapsamın dağılmasını önlemektir.

## Değişmeyen ürün ilkeleri

- 5 ana sekme: **Ana Sayfa · Kuran · Planlar · Keşfedin · Siz**.
- Kuran okuyucu temiz kalır; namaz, kıble, zikirmatik vb. araçlar okuyucuya yığılmaz.
- **Local-first / offline-first**: Arapça Kuran her zaman cihazda; temel Türkçe meal uygulamayla gelir; kullanıcı verileri önce cihazda tutulur.
- Ağ istekleri, depolama ve sunucu maliyeti en baştan minimum tutulur.
- Premium his; tipografi, boşluk, mikro animasyon, haptic ve akıcılıktan gelir. Ağır video/animasyon/SDK kullanılmaz.
- Tasarım dili YouVersion benzeri temiz ve sakin olabilir; başka uygulamaların özel görsel varlıkları/kodu kopyalanmaz.
- Kullanıcıya dinî içerik sunarken kaynak şeffaflığı korunur. Kaynaksız veya Allah adına kişiselleştirilmiş mesaj üretilmez.
- AI soru-cevap ve pazar yeri ürün kapsamında değildir.

## Şu an: çekirdek / iskelet

Öncelik sırası:

1. Kuran okuyucu: 114 sure, gerçek Arapça metin, doğru navigasyon.
2. Temel Türkçe meal: uygulamayla birlikte, çevrimdışı.
3. Okuma görünümü: Arapça + meal / yalnız Arapça / yalnız meal.
4. Okuyucu ayarları: Arapça ve meal boyutu ayrı; satır aralığı; ileride sınırlı sayıda kaliteli Kuran fontu.
5. Kaldığın yeri hatırlama ve ana ekrandan devam etme.
6. Ayet seçimi: tek veya çoklu ayet.
7. Vurgulama renkleri, Kaydet, Not, Kopyala; sonra Paylaş, Görüntü, Karşılaştır, Dua.
8. Sure/ayet ve meal içinde arama.
9. `Siz` sekmesinde kişisel arşiv: Vurgular, Kaydedilenler, Notlar, Planlar; kayıtlar ilgili ayete geri götürür.
10. Günün Ayeti: Arapça + seçili Türkçe meal, tamamen yerel veriyle.

## Sonraki ana modül: Namaz

Alt sekme eklenmez.

- **Ana Sayfa:** kompakt “sonraki namaz” kartı ve geri sayım.
- **Keşfedin → Namaz Vakitleri:** tam namaz ekranı, bugün/yarın, Hicri tarih, vakitler, bildirim ve kıble kısayolu.
- **Siz → Ayarlar → Namaz:** otomatik konum / manuel şehir, hesaplama yöntemi, standart/Hanefi ikindi, yüksek enlem kuralı, dakika düzeltmeleri, bildirimler.
- Hesap mümkün olduğunca cihazda yapılır; konum sunucuya gönderilmez.
- Hesaplama yöntemleri: Diyanet, MWL, Umm al-Qura, Egyptian, Karachi, ISNA vb.; bölgeye göre öneri yapılabilir ama kullanıcı değiştirebilir.

## Keşfedin araçları

Kademeli olarak:

- Namaz Vakitleri
- Kıble
- Zikirmatik
- Sabah / Akşam Zikirleri (arayüzde “Ezkâr” ana adı kullanılmaz)
- Hafızlık / Ezber
- Tefsirler
- Sesli Kuran
- Esmaül Hüsna
- Kaynaklı hadisler
- Konuya göre ayetler

## Zikirmatik

- Tamamen offline.
- Hazır zikirler + özel metin.
- 33 / 99 / özel hedef.
- Haptic, isteğe bağlı ses, sıfırla.
- Günlük toplam / ilerleme cihazda.
- İleride iOS/Android ana ekran widget’ı.

## Sabah / Akşam Zikirleri

- “Sabah Zikirleri” ve “Akşam Zikirleri” gibi açık Türkçe isimler.
- Kaynakları belli içerikler.
- Tamamlanma ilerlemesi; gerektiğinde zamana bağlı Ana Sayfa kartı.

## Hafızlık / Ezber

- Ayet veya sayfa aralığı seçip tekrar dinleme.
- Kâri seçimi, 1x / 3x / 5x / sınırsız tekrar.
- Kelimeleri kademeli gizleme.
- Ezberlenen bölümü işaretleme.
- Günlük tekrar listesi ve aralıklı tekrar.
- Sure / cüz / genel ilerleme.
- 604 sayfalık Medine Mushafı sayfa metadata’sı ileride eklenebilir.
- Mikrofonla ezber kontrolü ancak Kuran kıraatinde yeterli doğruluk gerçekten sağlanırsa yapılır; basit speech-to-text ile sahte doğruluk sunulmaz.

## “Sana Göre” konsepti

**Keşfedin** içinde isteğe bağlı kişiselleştirme alanı olabilir. Uzun onboarding yapılmaz.

Örnek ihtiyaçlar:
- Huzur
- Sabır
- Kaygı
- Yalnızlık
- Disiplin
- Şükür
- Affetmek
- Amaç arayışı

Seçim cihazda tutulur. AI gerekmez; önceden küratörlenmiş, kaynağı belli ayetler/planlar kullanılır. “Allah’a yakınlık %55” gibi manevi puanlama yapılmaz. “Seni duyduk” gibi Allah adına konuşuyor izlenimi veren ifadeler kullanılmaz.

## Widget ve bildirim fikirleri

İleride:
- Günün Ayeti ana ekran / kilit ekran widget’ı.
- Zikirmatik widget’ı.
- Günlük ayet bildirimi.
- Namaz vakti bildirimleri.
- Kullanıcı izni doğru bağlamda istenir; ilk açılışta izin bombardımanı yapılmaz.

## Mikro animasyon standardı

- Dokunma: yaklaşık %97–98 ölçek, bırakınca kısa spring.
- Seçim: kayan kapsül + hafif haptic.
- Bottom sheet: kısa, yumuşak giriş.
- Ayet seçimi/vurgu: 150–250 ms geçiş.
- Kaydetme: küçük ikon bounce.
- Zikirmatik: sayaç mikro-scale + haptic.
- Alt navigasyon: glass yüzey ve parmakla sekmeler üzerinde kaydırma.
- Animasyon gösteri değil geri bildirimdir; eski Android cihazlarda akıcılık önceliklidir.

## Ana Sayfa prensibi

Aynı anda her şeyi göstermemek. Genellikle 3–5 anlamlı kart:

- Günün Ayeti
- Kaldığın Yerden Devam Et
- Sonraki namaz
- Aktif okuma planı
- Zamana göre Sabah/Akşam Zikirleri veya kısa içerik

## Hesap / senkronizasyon

İlk sürüm hesap gerektirmez. Vurgular, notlar, kaydedilen ayetler, okuma konumu ve tercihlerin tamamı local çalışır. Daha sonra Google/Apple vb. hesap geldiğinde yerel veriler isteğe bağlı bulut senkronuna bağlanabilir.

## Bilerek ertelenenler / yapılmayacaklar

- Pazar yeri: yapılmayacak.
- AI dinî soru-cevap: yapılmayacak.
- Açık global sosyal ağ: ilk aşamada yapılmayacak.
- Gereksiz 6. alt sekme: yapılmayacak.
- Çok sayıda ağır tema, video veya görsel paket: yapılmayacak.
- Uygulama daha kullanılmadan puan istemek: yapılmayacak; uygun başarı anında istenir.
