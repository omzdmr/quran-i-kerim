# Mimari Notları

## İçerik katmanı

- **Arapça Kuran:** uygulama paketinde doğrulanmış sabit veri.
- **Mealler:** lisansı uygun olanlar küçük sıkıştırılmış paketler olarak indirilebilir.
- **Manifest:** uygulama seyrek aralıklarla kontrol eder; ETag/304 desteği hedeflenir.
- **Ses:** APK içinde değil. Sure veya makul büyüklükte segmentler halinde, cihaz cache’i ile.
- **Planlar:** günlük ayrı istekler yerine planın tamamı tek küçük paket olarak.

## Ağ bütçesi

Temel okuma, sure değiştirme, ayet kaydetme ve yerel not yazma için **0 ağ isteği** hedeflenir. Normal kullanıcıda içerik güncelleme istekleri düşük çift hanelerde tutulmalıdır.

## Depolama bütçesi

- Temel uygulama: 20–35 MB hedef
- Ek meal: yaklaşık birkaç MB / meal
- Ses: tamamen isteğe bağlı
- Cache: kullanıcı tarafından temizlenebilir

## UI yaklaşımı

Koyu, sakin, tipografi odaklı özgün arayüz. YouVersion’ın bilgi mimarisindeki sadelik referans alınır; görsel varlıklar ve tasarım birebir kopyalanmaz.
