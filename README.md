# Reverse Engineering Toolkit (REA Agents & Apktool)

Toolkit dan lingkungan kerja praktis untuk analisis keamanan dan **Reverse Engineering** aplikasi Android (APK), biner, dan web assets.

## 🛠 Komponen Toolkit

Toolkit ini mengintegrasikan dua alat utama:
1. **Apktool (v2.10.0):**
   - Mendekompilasi berkas `.apk` menjadi kode Smali, `AndroidManifest.xml`, dan *decoded resources* (`res/`, `values/`).
   - Mampu membangun ulang (*rebuild*) proyek modifikasi menjadi APK kembali.
2. **REA Agents (Reverse Engineer Anything v6.7.0+):**
   - Toolkit agen AI dan CLI terintegrasi untuk reverse engineering modern.
   - Analisis statik struktur kelas Android, deteksi build framework (Flutter, React Native, dll.), pelacakan referensi, serta ekstraksi resource secara otomatis.

---

## 🚀 Panduan Penggunaan

### 1. Dekompilasi APK Menggunakan Apktool
Untuk membongkar file APK menjadi file Smali dan resource XML yang dapat dibaca:
```powershell
.\apktool.bat d "path\to\target.apk" -o "output_folder"
```

Untuk mengompilasi ulang setelah analisis:
```powershell
.\apktool.bat b "output_folder" -o "rebuilt_app.apk"
```

### 2. Analisis APK Menggunakan REA (Reverse Engineer Anything)
Jalankan perintah melalui wrapper `rea.bat`:

* **Cek Status & Kemampuan REA:**
  ```powershell
  .\rea.bat capabilities
  ```
* **Dekode Resource & Manifest Android:**
  ```powershell
  .\rea.bat decode-android-resources "path\to\target.apk"
  ```
* **Cari / Inventarisasi Kelas Android di dalam APK:**
  ```powershell
  .\rea.bat search-android-classes "path\to\target.apk"
  ```
* **Identifikasi Build Flutter (Dart Snapshot Engine):**
  ```powershell
  .\rea.bat identify-flutter-build "path\to\target.apk"
  ```

---

## 📋 Prasyarat Sistem
- **Java:** OpenJDK 17 LTS (Adoptium Temurin)
- **Node.js:** v20+ / v24+
- **Sistem Operasi:** Windows (PowerShell / Command Prompt)
