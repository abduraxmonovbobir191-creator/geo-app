# Nex Map

Yandex Maps, Blink va Strava'ning birlashmasi bo'lgan mobil ilova (Flutter).

- **Xarita**: OpenStreetMap xaritasi, manzil va joy qidirish, yaqin atrofdagi joylar, yangi joy qo'shish
  (xaritani bosib turing), check-in.
- **Do'stlar (Blink kabi)**: do'stlarning jonli joylashuvi, batareya, tezlik, onlayn holat, ghost rejim,
  do'st qidirish va so'rovlar, chat.
- **Mashg'ulotlar (Strava kabi)**: yugurish, velosiped, piyoda va sayohatni GPS bilan yozish, masofa,
  vaqt va temp, lenta, kudos, statistika.
- **Dasturchilar uchun API**: ilovaning o'zidan API kalit yaratish (Profil > Dasturchilar uchun API).

Server: [geo-backend](https://github.com/abduraxmonovbobir191-creator/geo-backend) (Node.js + PostgreSQL).
API hujjati serverning `/docs` sahifasida.

## APK olish

Har bir push'da GitHub Actions APK yig'adi: **Actions > Build APK > oxirgi ishga tushirish > Artifacts >
nex-map-apk**.

Ilova qaysi serverga ulanishini belgilash uchun repo sozlamalarida `API_URL` o'zgaruvchisini qo'shing
(Settings > Secrets and variables > Actions > Variables), masalan `https://api.nexmap.uz`.
Ilovadagi kirish sahifasida (yuqori o'ng burchakdagi server belgisi) manzilni qo'lda ham o'zgartirish mumkin.

## Kompyuterda ishga tushirish

```bash
flutter create . --platforms=android --project-name=nex_map --org uz.nexmap   # android/ papkasini yaratadi
bash tool/configure_android.sh                                                # ruxsatlar va ilova nomi
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3000                        # emulyatordan kompyuterdagi serverga
```

Haqiqiy telefonda `10.0.2.2` o'rniga kompyuteringizning lokal IP manzilini yozing (masalan `http://192.168.1.10:3000`).

## Tuzilishi

```
lib/
  main.dart              ilova, kirish holatiga qarab ekran tanlash
  config.dart            server va xarita manzillari
  api/api_client.dart    REST API klienti
  services/              Socket.IO (real-time) va GPS
  state/                 sessiya, do'stlar va jonli lokatsiya
  screens/               ekranlar (xarita, yozish, lenta, do'stlar, chat, profil, API kalitlar)
  widgets/               umumiy vidjetlar
tool/configure_android.sh  android/ papkasini sozlash
```

## Eslatmalar

- Xarita OpenStreetMap'ning ochiq serveridan olinadi. Ko'p foydalanuvchiga chiqarishdan oldin o'z tile serveringiz
  yoki provayder (MapTiler, Stadia va h.k.) kerak: `--dart-define=TILE_URL=...`.
- iOS uchun build hali sozlanmagan (macOS kerak). `flutter create . --platforms=ios` dan keyin `Info.plist`ga
  joylashuv ruxsati matnlarini qo'shish kerak bo'ladi.
