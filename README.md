# Prime Capital — Mobile (Flutter)

Backend'dagi `Webapp/` (Telegram/brauzer mijoz ilovasi) bilan bir xil
funksionallikni beruvchi native mobil ilova: auth, balanslar, kvartiralar,
moliya tracker, investitsiya/pul yechish so'rovlari, support, bildirishnomalar,
video darslar va "investitsiya haqida xabar berish".

Backend'ga to'g'ridan-to'g'ri REST orqali ulanadi (`Backend/src/platform`,
`properties`, `balances` controller'lari) — Telegram initData orqali kirish
bu yerda ishlatilmaydi (u faqat Telegram Mini App uchun), shuning uchun bu
ilovada faqat email/parol bilan ro'yxatdan o'tish/kirish bor.

## Muhim: birinchi marta ishga tushirishdan oldin

Bu loyiha **faqat Dart kodini** (`lib/`, `pubspec.yaml`) o'z ichiga oladi.
`android/` va `ios/` platforma papkalari qasddan qo'shilmagan — ular Flutter
SDK versiyangiz, Android SDK/Gradle va (agar bo'lsa) Xcode versiyangizga mos
holda avtomatik generatsiya qilinishi kerak; buni qo'lda yozish xato va nomos
loyihaga olib kelishi mumkin edi. Shuning uchun:

```bash
cd Mobile
flutter create .          # android/ ios/ va boshqa platforma papkalarini yaratadi,
                           # lib/ va pubspec.yaml'ga tegmaydi
flutter pub get
flutter run                # yoki: flutter build apk --debug
```

`flutter create .` mavjud loyiha ustida ishlatilganda faqat yetishmayotgan
platforma fayllarini qo'shadi, `lib/` papkangizni o'chirmaydi/ustidan
yozmaydi.

## Backend URL'ni sozlash

Standart holatda ilova production API'ga (`https://api.primecapital.uz/api/v1`)
ulanadi (`lib/core/constants.dart`). Boshqa manzil bilan ishga tushirish:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1   # Android emulator -> local backend
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000/api/v1   # real qurilma -> shu Wi-Fi'dagi kompyuter
```

Real telefonda `localhost`/`127.0.0.1` — bu har doim telefonning o'zi, backend
ishlab turgan kompyuter emas.

## Loyiha tuzilishi

```
lib/
  main.dart                 — ilova kirish nuqtasi, til/sessiya provayderlari
  core/
    api_client.dart         — Backend REST client (JWT, barcha endpoint'lar)
    session.dart            — auth holati (token, profil)
    i18n.dart                — uz/ru/ar/en tarjimalar (Webapp'dagi wa.* kalitlar bilan bir xil)
    models.dart              — Balance/PropertyListing/Profile/FinanceEntry/ContentItem
    format.dart               — pul formatlash (so'm/$ )
    constants.dart            — ranglar, tema, API URL
  screens/                    — Auth, Home, Apartments, Finance, Profile, Shell(bottom-nav)
  widgets/                    — modallar (invest/withdraw, support, videos,
                                 notifications, promotion-report) va umumiy komponentlar
```

## Nima verifikatsiya qilinmagan (muhim!)

Bu ilova bulutli (cloud) muhitda yozildi — bu muhitning tarmoq siyosati
`pub.dev` va Flutter SDK/engine serverlariga (`storage.googleapis.com`)
ulanishni bloklaydi, shuning uchun bu yerda **`flutter pub get`,
`flutter analyze` yoki build birorta ham ishga tushirilmadi/tekshirilmadi**.
Kod qo'lda, sintaksis va Flutter API'lariga alohida e'tibor berib yozildi va
qayta-qayta ko'rib chiqildi, lekin haqiqiy kompilyatsiya tekshiruvi faqat
sizning mashinangizda birinchi `flutter pub get`/`flutter run` paytida
bo'ladi. Agar xatolik chiqsa — menga xabar bering, birga tuzatamiz.

## Logotip

`widgets/prime_logo.dart` — bu Webapp'dagi aniq brend-SVG (murakkab vektor
path) o'rniga soddalashtirilgan wordmark (gradient kvadrat + "PRIME CAPITAL"
matni). Asl logotip faylini (SVG/PNG) qo'shsangiz, shu faylni almashtirib
qo'yish kifoya.
