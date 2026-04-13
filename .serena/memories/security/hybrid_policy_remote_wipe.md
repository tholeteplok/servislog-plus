# Hybrid Security Policy & Remote Wipe Integration (v1.2.0)

Pembaruan ini mengimplementasikan kebijakan keamanan hibrida untuk melindungi data bengkel dari akses ilegal dan pencurian perangkat fisik.

## Fitur Utama
- **Hybrid Monitoring**: Menggabungkan `Firestore Streams` (real-time) dan `15-min Polling Timer` di `MainScreen` untuk memantau status validitas akun.
- **Nuclear Sequence (8-Step Remote Wipe)**: Prosedur otomatis untuk menghapus seluruh data lokal jika akun dinonaktifkan/dihapus oleh Owner:
  1. Set `isWiping = true` (global guard).
  2. Buka `AccessRevokedScreen` (overlay pemblokir).
  3. Tutup `ObjectBox Store`.
  4. Hapus direktori database lokal (`/objectbox`).
  5. Bersihkan `SecureStorage` (kunci enkripsi).
  6. Bersihkan cache & shared preferences.
  7. Firebase Sign Out.
  8. Redirect ke Login Screen.
- **Anti-False-Positive Verification**: Menggunakan `FirebaseAuth.reload()` untuk memvalidasi status akun ke server Auth sebelum memulai penghapusan data. Jika gagal koneksi, proses dihentikan (*Safe Stop* untuk mencegah kehilangan data akibat sinyal buruk).
- **isWipingProvider**: State global yang memicu `AccessLevel.blocked` di `SessionManager` untuk mematikan seluruh interaksi UI secara instan.
- **SyncWorker Hardening**: Menambahkan pemeriksaan `store.isClosed()` pada `SyncWorker` untuk mencegah *crash* saat sinkronisasi berjalan bersamaan dengan penutupan database.

## Lokasi File Penting
- `lib/core/services/device_session_service.dart`: Logika utama Nuclear Sequence.
- `lib/features/main/main_screen.dart`: Listener & Polling Timer.
- `lib/core/services/session_manager.dart`: Penegakan akses global via `isWiping`.
- `lib/core/services/sync_worker.dart`: Guard sinkronisasi.
- `lib/features/auth/screens/access_revoked_screen.dart`: UI Overlay Keamanan.

## Catatan Arsitektur
- `deviceId` di SharedPreferences dipertahankan setelah wipe (tidak dihapus total) untuk keperluan *audit trail* perangkat di sisi server.
- Seluruh teks user-facing di `CHANGELOG.md` dan `AccessRevokedScreen` menggunakan bahasa "Owner-Centric" yang berfokus pada keamanan data bisnis.
