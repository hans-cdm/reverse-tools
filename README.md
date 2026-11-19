# Reverse Engineering Toolkit (REA Agents, Apktool & JADX-GUI)

Toolkit dan lingkungan kerja praktis untuk analisis keamanan dan **Reverse Engineering** aplikasi Android (APK), biner, dan web assets.

## 🛠 Komponen Toolkit

Toolkit ini mengintegrasikan komponen utama:
1. **JADX-GUI (v1.5.7):**
   - Decompiler visual interaktif untuk mengubah bytecode DEX/APK menjadi kode sumber Java/Kotlin secara instan.
   - Dilengkapi pencarian fungsi, xrefs (cross-references), dan deobfuscator nama variabel.
2. **Apktool (v2.10.0):**
   - Mendekompilasi berkas `.apk` menjadi kode Smali, `AndroidManifest.xml`, dan *decoded resources* (`res/`, `values/`).
   - Mampu membangun ulang (*rebuild*) proyek modifikasi menjadi APK kembali.
3. **REA Agents (Reverse Engineer Anything v6.7.0+):**
   - Toolkit agen AI dan CLI terintegrasi untuk reverse engineering modern.
   - Analisis statik struktur kelas Android, deteksi build framework (Flutter, React Native, dll.), pelacakan referensi, serta ekstraksi resource secara otomatis.
4. **Script Otomatisasi Unduh (`download_apk.ps1`):**
   - Mengunduh otomatis APK target latihan (seperti OWASP MASTG Crackme) atau URL APK kustom.

---

## 🚀 Panduan Penggunaan

### 1. Membuka APK Secara Visual (JADX-GUI)
Untuk membuka antarmuka grafis JADX dan langsung melihat kode Java:
```powershell
.\jadx.bat
# Atau langsung membuka file target:
.\jadx.bat UnCrackable-Level1.apk
```

### 2. Dekompilasi Resource & Smali Menggunakan Apktool
Untuk membongkar file APK menjadi file Smali dan resource XML yang dapat diedit:
```powershell
.\apktool.bat d "target.apk" -o "output_folder"
```

Untuk mengompilasi ulang setelah analisis:
```powershell
.\apktool.bat b "output_folder" -o "rebuilt_app.apk"
```

### 3. Analisis APK Menggunakan REA (Reverse Engineer Anything)
Jalankan perintah melalui wrapper `rea.bat`:
```powershell
# Dekode Resource & Manifest Android:
.\rea.bat decode-android-resources "target.apk"

# Identifikasi Build Flutter (Dart Snapshot Engine):
.\rea.bat identify-flutter-build "target.apk"
```

### 4. Mengunduh APK Target Latihan Otomatis
```powershell
# Unduh tantangan lab OWASP:
.\download_apk.ps1 -Target uncrackable1
.\download_apk.ps1 -Target uncrackable2
.\download_apk.ps1 -Target uncrackable3

# Unduh dari URL langsung:
.\download_apk.ps1 -Url "https://example.com/target.apk" -OutputFile "app.apk"
```

---

## 📋 Prasyarat Sistem
- **Java:** OpenJDK 17 LTS (Adoptium Temurin)
- **Node.js:** v20+ / v24+
- **Sistem Operasi:** Windows (PowerShell / Command Prompt)
