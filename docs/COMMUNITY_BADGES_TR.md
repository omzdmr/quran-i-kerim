# Topluluk ve Rozetler — ürün notu

Bu belge Topluluk/Aktivite ve rozet fikirlerini, açık sosyal ağ veya aşırı oyunlaştırmaya dönüşmeden geliştirmek için sınırları sabitler.

## Topluluk / Aktivite

- Ana Sayfa içindeki **Bugün | Topluluk** yapısı korunur; alt navigasyona yeni sekme eklenmez.
- Arkadaş sistemi gelmeden önce Topluluk, kullanıcının kendi yerel aktivitelerini gösterebilir: ayet kaydetme, vurgu, not ve ileride plan tamamlama.
- Yeni yerel aktivite oluştuğunda `Topluluk` başlığında küçük bir ışık/nokta görünür; kullanıcı Topluluk sekmesini açınca görülmüş sayılır ve nokta söner.
- Aktivite kartı uzun metni tam okuyucuya zorla atmaz. Önce sade bir **pasaj görünümü** açılır; kullanıcı isterse `Surenin tamamını oku` ile tam okuyucuya geçer.
- Arkadaş sistemi geldiğinde akış yalnız kabul edilmiş arkadaşların aktivitelerini gösterir. Halka açık keşfet/feed, takipçi sayısı veya yabancılara yorum yoktur.
- Yorum/reaction yetkileri sunucuda arkadaşlık ilişkisiyle doğrulanır. Notlar varsayılan olarak özel kalır ve kullanıcı açıkça paylaşmadıkça sosyal etkinliğe dönüşmez.

## Rozetler

Rozetler kullanıcının dinî seviyesini ölçmez. `Allah'a yakınlık`, iman puanı veya manevi yüzdelik gibi ifadeler kullanılmaz. Rozet yalnız uygulamadaki somut kullanım kilometre taşını anlatır.

İlk adaylar:

- İlk ayetini kaydettin
- İlk vurgunu yaptın
- İlk notunu aldın
- 7 farklı günde Kuran okudun
- 30 farklı günde Kuran okudun
- İlk okuma planını tamamladın
- 7 günlük okuma serisi
- 30 günlük okuma serisi

Rozetler ilk aşamada local-first hesaplanır; hesap/senkron geldikten sonra kullanıcının hesabıyla eşitlenebilir. Rozet bildirimi kısa ve sakin olur; uygulama kumar makinesine çevrilmez.

## Sonraki sosyal altyapı

Hesap/senkron aşamasından sonra veri modeli `profiles`, `friendships`, `activity_events`, `activity_comments`, `activity_reactions`, `blocks` gibi küçük bir kapalı sosyal katmanla genişletilebilir. Feed algoritmik olmak zorunda değildir; kabul edilmiş arkadaşların son aktivitelerini zamana göre sıralamak yeterlidir.
