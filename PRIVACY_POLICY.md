# Kebijakan Privasi ServisLog+

**Terakhir Diperbarui: 14 April 2026**

Selamat datang di **ServisLog+**. Kami menghargai privasi Anda dan berkomitmen untuk melindungi data pribadi Anda serta data pelanggan bengkel Anda. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi informasi Anda saat Anda menggunakan aplikasi Android ServisLog+.

---

## 1. Informasi yang Kami Kumpulkan

Kami mengumpulkan informasi untuk memberikan layanan manajemen bengkel yang efisien dan aman.

### A. Informasi Akun Pengguna (Pemilik Bengkel/Staff)
- **Informasi Identitas:** Nama lengkap, alamat email, dan identitas unik pengguna saat mendaftar melalui Firebase Authentication (termasuk Google Sign-In).
- **Informasi Bengkel:** Nama bengkel, alamat, nomor telepon bengkel, dan logo.

### B. Data Pelanggan dan Kendaraan (Dikelola oleh Anda)
Aplikasi ini memungkinkan Anda menyimpan data pihak ketiga (pelanggan Anda), yang meliputi:
- **Identitas Pelanggan:** Nama dan nomor telepon.
- **Informasi Kendaraan:** Nomor plat (TNKB), merk, model, nomor rangka, dan riwayat servis.
- **Catatan Transaksi:** Detail layanan yang dilakukan, produk yang dibeli, harga, dan tanggal transaksi.

### C. Informasi Teknis dan Perangkat
- **Identitas Perangkat:** Nama perangkat, model, dan ID unik perangkat (Fingerprint) untuk keperluan keamanan sesi dan lisensi.
- **Data Log & Crash:** Melalui Google Firebase Crashlytics, kami mengumpulkan laporan teknis jika terjadi kesalahan aplikasi guna meningkatkan stabilitas.

---

## 2. Bagaimana Kami Menggunakan Informasi Anda

ServisLog+ menggunakan data yang dikumpulkan untuk:
1. **Operasional Aplikasi:** Mengelola inventaris, riwayat servis, dan pencatatan keuangan bengkel Anda.
2. **Sinkronisasi Awan:** Memungkinkan Anda mengakses data dari berbagai perangkat secara real-time melalui layanan Cloud Firestore.
3. **Keamanan:** Mencegah akses yang tidak sah melalui verifikasi perangkat dan sesi tunggal (Single Device Policy).
4. **Komunikasi:** Mengirimkan nota atau bukti transaksi kepada pelanggan Anda melalui integrasi pihak ketiga (seperti WhatsApp).

---

## 3. Penyimpanan dan Keamanan Data

Keamanan data adalah prioritas utama kami. Kami menerapkan standar industri untuk melindungi informasi Anda:

### A. Enkripsi Tingkat Tinggi
Semua data sensitif dan PII (Personally Identifiable Information) dienkripsi menggunakan standar **AES-256-GCM** sebelum disimpan, baik di penyimpanan lokal maupun di awan. Kunci enkripsi dikelola secara aman menggunakan **Flutter Secure Storage**.

### B. Penyimpanan Lokal dan Awan
- **Lokal:** Data disimpan di perangkat Anda menggunakan database **ObjectBox** yang berperforma tinggi.
- **Awan (Cloud):** Data disinkronkan ke **Google Cloud Firestore**. Meskipun berada di server kami, data tetap terenkripsi dan hanya dapat dibuka oleh kunci enkripsi yang ada pada perangkat Anda atau Master Password Anda.

### C. Keamanan Akses
Aplikasi mendukung penguncian biometrik (sidik jari/wajah) dan PIN untuk mencegah akses fisik yang tidak sah ke data aplikasi.

---

## 4. Berbagi Informasi dengan Pihak Ketiga

Kami tidak menjual data Anda kepada pihak ketiga. Kami hanya berbagi informasi dengan penyedia layanan yang membantu operasional aplikasi:
- **Google Firebase:** Untuk otentikasi, penyimpanan basis data, dan laporan *crash*.
- **WhatsApp:** Saat Anda memilih untuk membagikan nota digital ke pelanggan, nomor telepon dan detail transaksi akan diteruskan ke aplikasi WhatsApp di perangkat Anda.

---

## 5. Hak Anda atas Data

Anda memiliki kontrol penuh atas data Anda:
- **Akses dan Koreksi:** Anda dapat melihat dan mengubah semua data pelanggan, transaksi, dan profil bengkel kapan saja melalui menu aplikasi.
- **Penghapusan Data (Logout):** Saat Anda keluar (Logout) dan memilih untuk menghapus sesi, kunci enkripsi akan dihapus dari perangkat untuk memastikan data tidak dapat diakses tanpa login kembali.
- **Penghapusan Akun:** Anda dapat meminta penghapusan akun permanen yang akan menghapus semua data Anda dari server Cloud Firestore kami.

---

## 6. Perubahan Kebijakan Ini

Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Kami akan memberitahu Anda tentang perubahan apa pun dengan memposting kebijakan baru di halaman ini atau melalui notifikasi di dalam aplikasi.

---

## 7. Kontak Kami

Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini, silakan hubungi kami melalui:
- **Email:** support.servislog@gmail.com

---
*Dokumen ini disusun berdasarkan arsitektur teknis ServisLog+ yang menggunakan enkripsi AES-256.*
