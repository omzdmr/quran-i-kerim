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

## v0.3 Kuran çekirdeği — uygulandı

- 114 sure ve gerçek Arapça Kuran metni.
- Temel Türkçe meal build sırasında uygulamanın asset paketine gömülür; çalışma anında internet gerekmez.
- Arapça + meal / yalnız Arapça / yalnız meal görünümleri.
- Arapça ve meal yazı boyutu ayrı; Sık / Normal / Ferah satır aralığı.
- Tek veya çoklu ayet seçimi.
- Vurgu renkleri, Kaydet, Not ve Kopyala; veriler cihazda tutulur.
- Kuran araması: sure adı, `2:255` gibi referans ve offline Türkçe meal içinde kelime araması.
- Ana Sayfadaki “Kaldığın Yerden Devam Et” ve Günün Ayeti doğrudan ilgili ayeti açar.
- `Siz` arşivinde Vurgular / Kaydedilenler / Notlar listelenir; karta dokunmak ilgili ayeti açar.
- Alt navigasyonda hafif glass yüzey, kayan seçim kapsülü, sürükleme ve haptic davranışı.
- Flutter 3.47.2 üzerinde `flutter analyze` ve Android release APK build doğrulaması başarıyla geçti.

Bir sonraki Kuran çekirdeği cilaları: gerçek cihaz testi sonrası ölçü/typography düzeltmeleri, Paylaş/Görüntü/Karşılaştır/Dua eylemleri, seçili ayet akışında küçük UX iyileştirmeleri ve okuma konumunu yalnız dokunmayla değil kaydırılan görünür ayete göre de hassas takip etme.

## YouVersion APK araştırmasından alınan teknik/ürün kararları

YouVersion 11.31 Android APKM paketi yalnızca **ilham ve mimari karşılaştırma** amacıyla incelendi. Özel kod, görsel, font veya içerik kopyalanmayacak. Yararlı olan genel teknik kalıplar kendi mimarimize uygun ve daha hafif biçimde uygulanabilir.

- YouVersion’ın güncel Android uygulaması da Flutter ağırlıklı çalışıyor; Flutter seçimi ürünümüz için makul kalıyor.
- Cihaz diline göre **bir varsayılan Kutsal Kitap içeriğini yerel paketleyip**, diğer çevirileri sonradan indirme modeli kullanılıyor. Bizim kararımız aynı yönde kalır: **Arapça + varsayılan Türkçe meal bundled, ek mealler indirilebilir**.
- İçerik büyük tek bir nesne yerine küçük bölümlere ayrılmış. Çoklu meal aşamasında Türkçe meal deposunu **sure bazlı parçalar + küçük sıcak cache** modeline geçirmek değerlendirilecek. Bu, tüm mealleri her açılışta RAM’e almak yerine yalnız gereken sureyi yüklemeyi sağlar.
- Okuyucuda tam ayete gitme ve görünür konumu takip etme için `scrollable_positioned_list` benzeri item-position yaklaşımı iyi bir örnek. Bizde **kaydırırken görünür ayeti otomatik kaydetme** çekirdek cilasına alınacak; yalnız ayete dokunmaya bağımlı kalmayacak.
- YouVersion offline aramada SQLite **FTS5** kullanıyor. Bizim mevcut 6 bin civarı ayette basit yerel tarama yeterli; ancak birden fazla meal/tefsir geldiğinde ayrı **FTS5 arama indeksi** daha doğru ölçekleme yolu olacak.
- Arama deneyiminde **son aramalar, ilgili aramalar, sonuçları sureye göre filtreleme ve offline arama durumu** gibi fikirler yararlı. İlk sürümde yalnız gerekli olanlar alınacak; arama ekranı şişirilmeyecek.
- Okuyucuda **son okunan pasajlar / okuma geçmişi** tutulması yararlı. İleride sure seçicide veya `Siz` içinde son 5–10 konuma hızlı dönüş eklenebilir.
- İndirilebilir içerik için tek tek özelliklerin kendi indirme kodunu yazması yerine ortak bir **Download Manager** katmanı planlanacak: içerik ID’si, türü, sürüm, boyut, URL, durum, hata, checksum/doğrulama ve güncelleme bilgisi.
- Büyük indirmeler (özellikle ses) Android’de WorkManager benzeri arka plan işiyle, iOS’ta uygun native arka plan indirme altyapısıyla yapılmalı. **Wi‑Fi ile indir** tercihi ve indirme yönetimi `Siz → İndirilenler` altında olmalı.
- Ses için ekran açıkken çalışan sıradan oynatıcı yeterli değil. **Arka planda oynatma, lock-screen medya kontrolleri, foreground media service/media session, kaldığı saniye, hız, sleep timer, kâri tercihi ve sıra** mimarinin parçası olacak. Flutter tarafında bunu sağlayan hafif ve olgun bir medya katmanı seçilecek; YouVersion’ın özel kodu kopyalanmayacak.
- Varsayılan içerik metadata’sında yalnız ad/kod değil **content_version/build, kaynak, lisans, offline izin, güncelleme politikası, checksum, varsa numaralandırma şeması** tutulmalı. Mevcut translation catalog zamanla bu alanlarla genişletilecek.
- YouVersion farklı metin numaralandırma sistemlerini ayrı `versification` katmanıyla ele alıyor. Bizde daha önce gördüğümüz ayet sayımı farkları nedeniyle **kanonik iç kimlik ile ekranda gösterilen numaralandırmayı karıştırmama** ilkesi korunacak; gelecekte gerekirse `verse_scheme` metadata alanı kullanılacak.
- Ek fontları zorunlu olarak ana pakete yığmak yerine **opsiyonel offline font paketleri** mantıklı. Arapça için uygulamada iyi bir varsayılan font bulunacak; en fazla birkaç kaliteli alternatif indirilebilir olacak.
- Ayet görüntüsü aracında arka plan seçme/kırpma yanında **blur, parlaklık, metin opaklığı, satır aralığı** gibi az sayıda anlamlı kontrol yeterli. Tasarım sade kalacak; sosyal medya editörüne dönmeyecek.
- `Siz` arşivi büyüdüğünde **sureye göre filtre, arama, isteğe bağlı etiketler ve kompakt görünüm** değerlendirilebilir. İlk sürümde mevcut Tümü/Vurgu/Kaydedilen/Notlar yeterli.
- Günün Ayeti için Android/iOS widget mimarisi ayrı native yüzey olarak planlanmalı; uygulama içi Flutter ekranının ekran görüntüsünü widget diye kullanma yaklaşımı tercih edilmeyecek.
- Hesap/senkron geldiğinde local-first yapı korunacak. Sunucuya her dokunuşta doğrudan yazmak yerine **yerel outbox/sync kuyruğu + retry/backoff** yaklaşımı kullanılabilir; böylece offline not/vurgu/kaydet işlemleri kaybolmaz.
- YouVersion güvenli değerler için `flutter_secure_storage`/Keystore benzeri katman kullanıyor. Bizde hesap geldiğinde token/anahtarlar ve gerekirse özel not şifreleme anahtarı güvenli depoda tutulacak.
- Remote Config/A-B deney altyapısı YouVersion’da yoğun; biz **kullanıcı tabanı ve gerçek ihtiyaç oluşmadan** Firebase/Braze/Amplitude benzeri ağır SDK’ları eklemeyeceğiz. Uygulamanın küçük ve hızlı kalması daha önemli.
- YouVersion’ın gerçek cihazda gereken paket boyutu bizim hedefimizden belirgin büyük; bunda native SDK, analytics, sosyal, ödeme ve medya katmanları etkili. Biz **gereksiz üçüncü taraf SDK eklemeyerek 20–35 MB civarı hafif hedefi** koruyacağız.
- Android `PROCESS_TEXT` benzeri sistem entegrasyonuyla başka uygulamada seçilen metni “Kuran’da ara” şeklinde açmak ileride hoş bir bonus olabilir; çekirdek öncelik değildir.
- YouVersion’ın uzun kişiselleştirme onboarding’i örnek alınmayacak. Bizim daha önceki kararımız geçerli: ilk açılış kısa, kişiselleştirme `Keşfedin → Sana Göre` içinde isteğe bağlı.

## Security / Release Hardening

Test APK’sı üretim güvenliği olarak kabul edilmez. Store sürümünden önce ayrı hardening aşaması yapılacak.

- Flutter production build: `--obfuscate` + `--split-debug-info`; debug symbol dosyaları APK dışında güvenli tutulur.
- Android release küçültme/resource shrinking ve uygun R8/ProGuard kuralları değerlendirilir; Flutter/native plugin uyumluluğu CI’da doğrulanır.
- Google Play’de **Play App Signing**; upload key/parolalar repo içine yazılmaz. CI secret olarak tutulur.
- APK/IPA içine gerçek sunucu secret/client secret gömülmez. Hassas sağlayıcı anahtarları gerekiyorsa backend üzerinden kullanılır.
- Premium/satın alma gibi kritik yetkiler yalnız yerel boolean’a güvenmez; mağaza makbuzu ve gerekiyorsa sunucu doğrulaması kullanılır.
- Hesap tokenları ve kriptografik anahtarlar Android Keystore / iOS Keychain tabanlı güvenli depoda tutulur.
- Kullanıcının özel notları yayın aşamasında ayrıca değerlendirilir; gerekirse cihaz güvenli anahtarıyla şifreli local storage’a taşınır.
- Release loglarında token, özel not, hassas konum veya kullanıcı verisi yazılmaz.
- Hassas backend eylemleri geldiğinde Play Integrity / App Attest benzeri bütünlük kontrolleri değerlendirilebilir; çevrimdışı Kuran okuması bunlara bağlanmaz.
- APK içindeki asset ve istemci kodunun bir gün incelenebileceği varsayılır. Güvenlik **gizlemeye değil, secretları istemcide tutmamaya ve doğru yetkilendirmeye** dayanır.

## Sonraki ana modül: Namaz

Alt sekme eklenmez.

- **Ana Sayfa:** kompakt “sonraki namaz” kartı ve geri sayım.
- **Keşfedin → Namaz Vakitleri:** tam namaz ekranı, bugün/yarın, Hicri tarih, vakitler, bildirim ve kıble kısayolu.
- **Siz → Ayarlar → Namaz:** otomatik konum / manuel şehir, hesaplama yöntemi, standart/Hanefi ikindi, yüksek enlem kuralı, dakika düzeltmeleri, bildirimler.
- Hesap mümkün olduğunca cihazda yapılır; konum sunucuya gönderilmez.
- Hesaplama yöntemleri: Diyanet, MWL, Umm al-Qura, Egyptian, Karachi, ISNA vb.; bölgeye göre öneri yapılabilir ama kullanıcı değiştirebilir.
- **Aylık Vakitler:** ay bazında tablo/liste; tüm vakitler veya tek vakit filtresi.
- **Kıble:** pusula, sensör/kalibrasyon rehberi ve doğruluk uyarısı; mümkünse konum tamamen cihazda kalır.

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
