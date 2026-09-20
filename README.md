# Kur’an-ı Kerim

Modern, hızlı ve **offline-first** bir Kuran uygulaması. Ürün hedefi: premium his, düşük donanım ve düşük veri kullanımında da akıcı deneyim.

**Planlanan mağaza adı:** `Kur’an, Sesli Kuran & Namaz`  
**Uygulama içi marka:** `Kur’an-ı Kerim`  
**Alt açıklama:** `Sesli Kuran, Namaz, Mealler ve Okuma Planları`

## Ürün iskeleti

- Ana Sayfa
- Kuran
- Okuma Planları
- Keşfedin
- Siz
- Cihaz diline göre arayüz ve varsayılan meal
- Meal kısa kodu ile hızlı çeviri değiştirme
- İsteğe bağlı çevrimdışı meal indirme
- Günün Ayeti
- Sesli Kuran
- Notlar, kayıtlar ve ilerleme

## Teknik ilkeler

1. **Local-first:** Temel Kuran okuma sunucuya bağlı olmayacak.
2. **Offline-first:** Arapça Kuran ve temel metadata cihazda bulunacak.
3. **Package, don’t stream:** Mealler ve planlar ayet/gün başına değil paket halinde indirilecek.
4. **Cache:** Aynı veri boş yere ikinci kez indirilmez.
5. **Hafiflik:** Ağır video, gereksiz SDK ve büyük görsel paketleri temel uygulamaya eklenmez.
6. **Düşük cihaz hedefi:** Modern görünüm pahalı donanım gerektirmemeli.

## Boyut hedefi

İlk mağaza sürümünde temel kurulum için yaklaşık **20–35 MB** hedefleniyor. Ses paketleri ve ek mealler isteğe bağlı indirilecek.

## Android APK

GitHub Actions, `main` dalına yapılan değişikliklerde otomatik test APK’ları üretir. Actions ekranındaki en yeni `Android APK` çalıştırmasının `Artifacts` bölümünden indirilebilir.

> Bu repo şu anda geliştirme aşamasındadır. Gerçek meal metinleri, ticari/offline dağıtım lisansları doğrulandıktan sonra eklenecektir.
