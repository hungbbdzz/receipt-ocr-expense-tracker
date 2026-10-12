# Receipt OCR & Expense Tracker

Flutter 3.x / Dart 3. Scan receipts, extract total/date/merchant with on-device ML Kit OCR and a Dart regex parser, store in SQLite, view custom CustomPainter charts.

## Setup

```
flutter create . --org vn.vku --project-name receipt_tracker   # chi lan dau, de sinh android/ios
flutter pub get
flutter run
```

Copy `lib/` and `pubspec.yaml` from this repo over the generated project.

### Android
- `android/app/build.gradle`: `minSdkVersion 21` (ML Kit yeu cau).
- `AndroidManifest.xml`, trong `<application>`:

```xml
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

### iOS
`ios/Runner/Info.plist`: them `NSCameraUsageDescription` va `NSPhotoLibraryUsageDescription`.

## Build signed release APK

```
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Tao `android/key.properties` (storePassword, keyPassword, keyAlias, storeFile) va cau hinh `signingConfigs.release` trong `android/app/build.gradle` theo huong dan chinh thuc cua Flutter ("Build and release an Android app"). Sau do:

```
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Khong commit keystore va `key.properties`.

## Structure

```
lib/
  main.dart                      Material 3 light/dark, bottom nav
  data/expense_db.dart           Expense model + sqflite CRUD
  providers/expense_provider.dart  Provider state, filters, chart data
  services/receipt_parser.dart   Regex heuristics (total, date, merchant)
  services/ocr_service.dart      ML Kit OCR + receipt image caching
  screens/                       scan flow, review, list, charts
  widgets/charts.dart            Donut + weekly bar (CustomPainter)
```

## Regex design

- Text duoc bo dau + lowercase truoc khi match (OCR hay mat dau tieng Viet).
- Total: dong chua tong/thanh toan/total/amount, loai dong khach dua/tien thua/giam gia/VAT; lay so lon nhat; nhan `150.000`, `150,000`, `1.250.000,00`.
- Date: `DD/MM/YYYY`, `DD-MM-YYYY`, `YYYY-MM-DD`, kiem tra ngay hop le.
- Merchant: thuong hieu quen thuoc trong 6 dong dau, neu khong co thi dong chu dau tien.
