# Setup Firebase untuk Login Google & Facebook

## Langkah 1: Buat Firebase Project

1. Buka https://console.firebase.google.com
2. Klik **"Add project"** atau **"Tambah project"**
3. Masukkan nama project: `NewsApp` (atau nama lain yang kamu inginkan)
4. Disable Google Analytics jika tidak diperlukan
5. Klik **"Create project"**

## Langkah 2: Register App untuk Web

1. Di Firebase Console, pilih project yang baru dibuat
2. Klik icon **"</>"** (Web) untuk menambahkan web app
3. Masukkan App nickname: `NewsApp Web`
4. Centang **"Also set up Firebase Hosting"** (opsional)
5. Klik **"Register app"**
6. Copy konfigurasi Firebase yang muncul (akan dipakai nanti)

## Langkah 3: Enable Authentication

1. Di sidebar Firebase Console, klik **"Authentication"**
2. Klik tab **"Sign-in method"**
3. Enable **Google Sign-In**:
   - Klik "Google"
   - Toggle "Enable"
   - Masukkan support email (email kamu)
   - Klik "Save"

4. Enable **Facebook Login**:
   - Klik "Facebook"
   - Toggle "Enable"
   - **Untuk mendapatkan App ID & App Secret Facebook:**
     a. Buka https://developers.facebook.com
     b. Klik "My Apps" → "Create App"
     c. Pilih "Consumer" → Next
     d. Masukkan App Name: `NewsApp`
     e. Masukkan App Contact Email
     f. Klik "Create App"
     g. Di Dashboard, copy **App ID** dan **App Secret**
     h. Di Settings → Basic, scroll ke bawah dan klik "Add Platform"
     i. Pilih "Website"
     j. Masukkan Site URL: `http://localhost` (untuk development)
     k. Di Facebook Login → Settings:
        - Valid OAuth Redirect URIs: Copy dari Firebase Console (ada di bagian Facebook setup)
   - Paste App ID & App Secret di Firebase Console
   - Klik "Save"
   - **IMPORTANT**: Copy OAuth redirect URI dari Firebase dan paste ke Facebook Developers Console di:
     - Facebook Login → Settings → Valid OAuth Redirect URIs

## Langkah 4: Update Konfigurasi di Kode

### Untuk Web (yang sedang kita pakai):

1. Buka file `lib/main.dart`
2. Ganti konfigurasi Firebase dengan nilai dari Firebase Console:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "AIzaSy...",              // Dari Firebase Config
    authDomain: "newsapp-xxxxx.firebaseapp.com",
    projectId: "newsapp-xxxxx",
    storageBucket: "newsapp-xxxxx.appspot.com",
    messagingSenderId: "1234567890",
    appId: "1:1234567890:web:xxxxx",
  ),
);
```

### Untuk Android (jika ingin compile ke Android):

1. Download `google-services.json` dari Firebase Console
2. Paste ke folder `android/app/`
3. Update `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```
4. Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.android.gms.google-services'
```

## Langkah 5: Test Aplikasi

1. Jalankan aplikasi:
```bash
flutter run -d chrome
```

2. Klik tombol "Continue with Google" - akan muncul popup Google Sign-In
3. Pilih akun Google
4. Login berhasil!

## Troubleshooting

### Error: "Firebase not initialized"
- Pastikan Firebase sudah di-initialize di `main.dart` sebelum `runApp()`

### Google Sign-In tidak muncul popup
- Pastikan Google Sign-In sudah enabled di Firebase Console
- Pastikan konfigurasi `apiKey` dan `authDomain` sudah benar

### Facebook Login error
- Pastikan OAuth Redirect URI sudah di-paste ke Facebook Developers Console
- Pastikan App ID dan App Secret sudah benar
- Pastikan Facebook app status = "Live" (bukan Development mode)

### Web: "Unauthorized domain"
- Di Firebase Console → Authentication → Settings → Authorized domains
- Tambahkan `localhost` untuk development

## Notes

- **Google Sign-In**: Langsung bisa dipakai setelah enable di Firebase, tidak perlu setup tambahan
- **Facebook Login**: Butuh setup di Facebook Developers Console (lihat langkah 3)
- **Email/Password**: Jika mau enable login dengan email/password, enable "Email/Password" di Firebase Authentication

## Konfigurasi Cepat (Copy Firebase Config)

Setelah register web app di Firebase, kamu akan dapat config seperti ini:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "your-app.firebaseapp.com",
  projectId: "your-app",
  storageBucket: "your-app.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:xxxxx"
};
```

Copy semua nilai ini dan paste ke `lib/main.dart` sesuai format yang sudah ada.
