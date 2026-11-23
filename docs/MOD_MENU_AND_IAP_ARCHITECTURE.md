# Blueprint Arsitektur Mod Menu & Mekanisme Pembelian Gratis (IAP)

Dokumen ini merangkum hasil rekayasa balik dua arsitektur Mod Menu Android yang berbeda (**Unity IL2CPP** vs **Cocos2d-x C++**) sebagai referensi teknis lengkap untuk analisis maupun pembuatan Mod Menu pada proyek APK berikutnya.

---

## Bagian 1: Arsitektur Mod Menu *Packed Native* (Studi Kasus: *Otherworld Legends v3.8.0 - 5play*)

Target merupakan game berbasis **Unity IL2CPP** (`arm64-v8a`) dengan `libil2cpp.so` (`80,8 MB`), `libunity.so` (`20,7 MB`), dan `global-metadata.dat` versi 31 (`13,04 MB`).

### 1.1 Struktur & Letak Mod Menu

Mod tidak menanamkan UI di file Smali/XML standar secara terbuka, melainkan menggunakan pola **Loader Java Minimal + Native Packed Engine (`libRMS.so`)**:

1. **Titik Masuk (*Loader*) di `Application` (`classes2.dex`):**
   - Pada kelas `com.chillyroomsdk.sdkbridge.BasePlayerApplication`, modder menyuntikkan pemuatan library di blok `static`:
     ```java
     static {
         System.loadLibrary("RMS");
     }
     ```
   - Karena `BasePlayerApplication` adalah kelas `Application` utama, `libRMS.so` dimuat paling awal saat proses aplikasi dibuat—sebelum `Activity` maupun engine Unity berjalan.
2. **Jembatan JNI (`classes4.dex`):**
   - Kelas `com.fiveplay.mod.RMS.Proxy` mendeklarasikan metode native minimal:
     ```java
     public class Proxy {
         private static native boolean A();
         private static native boolean B();
         private static native boolean C();
         private static native boolean D();
         private static native boolean E();
         private static native boolean F();
     }
     ```
   - Metode-metode ini di-bind secara dinamis oleh `libRMS.so` melalui `RegisterNatives` saat runtime.
3. **Engine & Payload Terproteksi (`lib/arm64-v8a/libRMS.so` — `7,18 MB`):**
   - **Obfuskasi Header ELF:** Nilai `e_phentsize` pada header ELF diubah menjadi `17` untuk menggagalkan parser statis (`readelf`, `llvm-readobj`) membaca segmen `PT_DYNAMIC`, sementara *Section Headers* (`e_shoff`) tetap utuh.
   - **Pemisahan Stub vs Payload:**
     - `.text` hanya berukuran **`23.904 byte` (~23 KB)**: berisi *unpacker stub*, `JNI_OnLoad` (`0x8B84`), dan thread pemeriksaan integritas (*anti-tamper*).
     - `.data` berukuran **`7.146.641 byte` (~7,14 MB)**: menyimpan payload utama Mod Menu dan hook engine dalam bentuk terkompresi/terenkripsi (`zlib` `inflate`, `crc32`).
   - **Anti-Tamper Internal:** Thread di `0x8AA8` memeriksa konsistensi flag internal; jika terdeteksi modifikasi pada `libRMS.so`, ia langsung memanggil `kill(..., 9)` (`0x8B74`–`0x8B80`).
   - **Mekanisme Runtime Hook:** `libRMS.so` mengimpor `dlopen`, `dlsym`, `pthread_create`, `fopen`, `fgets`, dan `strstr` untuk memindai `/proc/self/maps`, menemukan alamat basis `libil2cpp.so` di memori, lalu mendekripsi payload `.data` dan memasang hook ke fungsi-fungsi game serta merender overlay Mod Menu.

### 1.2 Cara Kerja Pembelian Gratis (*Free Purchase* / IAP Bypass)

1. **Kode Billing Java Tetap Standar:**
   - Hasil dekompilasi `com.android.billingclient.api.BillingClientImpl` (`classes.dex`), `com.chillyroomsdk.sdkbridge.pay.BasePayAgent` (`classes2.dex`), dan `PayRecordManager` (`classes2.dex`) menunjukkan **tidak ada patch di sisi Java**.
2. **Intersepsi di Layer Native Unity IL2CPP (`libRMS.so` $\rightarrow$ `libil2cpp.so`):**
   - Game menggunakan **Unity IAP** (`assets/AOTReferences/Unity.Purchasing.dll.bytes`) yang terhubung ke agen ChillyRoom di sisi C#/IL2CPP (`GooglePlayPayAgent`, `ProcessPurchase`, `OnPurchaseComplete`, `CallPurchaseSucceededUpdateReceipt`, `CanPurchase`, `IAPOrdersPatch` di `global-metadata.dat`).
   - Alih-alih mengutak-atik `BillingClient` di Smali, `libRMS.so` melakukan **runtime hooking langsung pada fungsi pemrosesan/verifikasi IAP di memori `libil2cpp.so`**.
   - Ketika tombol beli ditekan, alur dialihkan agar langsung memicu callback pembelian berhasil / mengembalikan status kepemilikan item sebagai sudah terbeli secara lokal tanpa validasi Google Play.

#### Ringkasan 2 Pola IAP Bypass untuk Target Lain
* **Pola A — Java/Smali Layer Hook:** Mengubah subclass `BasePayAgent` / `BillingClientImpl` agar `doPay(...)` langsung memanggil `sendPaySuccess(...)` (mengirim `UnitySendMessage("recvPaySuccess", ...)`). Cocok jika billing dikendalikan penuh oleh SDK Java.
* **Pola B — Native IL2CPP Runtime Hook (Gaya 5play):** Membiarkan Java billing asli, lalu meng-hook metode C# di `libil2cpp.so` (`ProcessPurchase`, `OnPurchaseComplete`, atau getter kepemilikan item) menggunakan offset RVA dari dump `global-metadata.dat`.

---

## Bagian 2: Arsitektur Mod Menu *Modular Overlay + GOT/Vtable Hook* (Studi Kasus: *NS Kurozamenshi v2.3*)

Target merupakan game berbasis **Cocos2d-x C++** (`libcocos2dcpp.so`) dengan simbol `.dynsym` dan relokasi `.rela.plt` / `.rela.dyn` yang masih terbaca jelas.

### 2.1 Struktur Komponen

1. **Floating Overlay UI di Java (`ModMenu.java` $\rightarrow$ `ModMenu*.smali`):**
   - Dipanggil dari `onCreate` Activity utama (`NarutoSenki.smali`):
     ```smali
     invoke-static {p0}, Lns/kurozamenshi/game/ModMenu;->attach(Landroid/app/Activity;)V
     ```
   - **Penempatan Layer di Atas `GLSurfaceView`:** Menggunakan `activity.addContentView(overlay, MATCH_PARENT)` + `overlay.bringToFront()` (tidak perlu izin `SYSTEM_ALERT_WINDOW`). Menggunakan `findViewById(android.R.id.content)` berisiko tertimpa atau tertutup oleh `Cocos2dxGLSurfaceView`.
   - Menyediakan tombol *draggable* (`MOD`) yang membuka `AlertDialog` bertingkat (Input angka per slot skill, pengaturan Projectile, pengaturan Summon/Clone).
2. **Library Hook Native (`libmodmenu.so`):**
   - **Aturan Kompilasi Kritis (NDK):** Wajib menggunakan flag **`-static-libstdc++`** saat mengompilasi dengan `aarch64-linux-android21-clang++`. Jika tidak, `libmodmenu.so` akan bergantung pada `libc++_shared.so` yang biasanya tidak tersedia di dalam APK target, sehingga `System.loadLibrary` gagal dengan `UnsatisfiedLinkError`.
   - Verifikasi dependensi dengan `llvm-readobj --needed-libs`: hanya boleh memuat library sistem (`libc.so`, `libdl.so`, `liblog.so`, `libm.so`).
3. **Teknik Hooking Tanpa Merusak Instruksi (GOT/PLT & Vtable Hooking):**
   - Menemukan alamat basis `libcocos2dcpp.so` saat runtime menggunakan `dl_iterate_phdr`.
   - Mengubah proteksi halaman memori dengan `mprotect(pageStart, pageSize * 2, PROT_READ | PROT_WRITE)` untuk melewati `GNU_RELRO`, menukar pointer fungsi pada tabel `.rela.plt` / `.rela.dyn` atau *vtable*, lalu memanggil `__builtin___clear_cache`.
   - **Keunggulan GOT/Vtable Hook dibanding Inline Hook:** Tidak memerlukan relokasi instruksi `ADRP`/`B`/`CBZ` sehingga jauh lebih stabil dan bebas risiko korupsi instruksi ARM64.
4. **Filter Pemain & Bypass Anti-Tamper:**
   - Memeriksa flag pemain di objek karakter (`*(uint8_t*)(player + 0x228) == 1`) agar pengurangan Cooldown dan bonus Damage hanya berlaku untuk pemain, bukan AI.
   - Jika APK memiliki verifikasi tanda tangan (*signature check*), patch fungsi pengecek di Java (`verifyOfficialPackageIntegrity`) maupun di native C++ (`nativeVerifyOfficialSigner` / `kzv3VerifyOfficialSignerFromContext` menjadi `mov w0, #1; ret`) sebelum melakukan *re-sign* dengan `uber-apk-signer`.

---

## Bagian 3: Checklist Pembuatan Mod Menu di APK Baru

1. **Identifikasi Engine Target:**
   - Cek isi folder `lib/arm64-v8a/` di dalam APK:
     - `libil2cpp.so` + `global-metadata.dat` $\rightarrow$ **Unity IL2CPP** (cari RVA via metadata/dumper, hook via `libil2cpp.so` base + RVA).
     - `libcocos2dcpp.so` $\rightarrow$ **Cocos2d-x** (cek `.dynsym` dan `.rela.plt`/`.rela.dyn` untuk GOT/Vtable hooking).
2. **Temukan Entry Point UI:**
   - Dekompilasi `classes*.dex` dengan JADX (`jadx.cli.JadxCLI`) untuk menemukan `Application` atau `MainActivity` utama.
3. **Bangun UI & Native Bridge:**
   - Buat kelas Java overlay (`addContentView` + `bringToFront`), kompilasi dengan `javac --release 8`, konversi ke `.dex` dengan `r8/d8`, lalu ubah ke `.smali` dengan `apktool`.
   - Kompilasi native C++ dengan NDK menggunakan `-static-libstdc++`.
4. **Rebuild & Re-sign (Android 11+):**
   - Rebuild APK dengan `apktool b`, lalu wajib lakukan `zipalign` + tanda tangan **v1, v2, dan v3** menggunakan `uber-apk-signer.jar`.
