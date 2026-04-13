# Changelog: Hybrid Security Policy (v1.2.0)

Pembaruan ini menghadirkan sistem keamanan berlapis (Hybrid Security Policy) yang dirancang untuk melindungi data bengkel Anda dari akses tidak sah dan risiko pencurian perangkat, menggabungkan pemantauan instan dan perlindungan cadangan.

## Fitur Utama & Manfaat Bisnis

### 1. Perlindungan Ganda (Hybrid Monitoring)
Sistem kini mengawasi keamanan akun Anda melalui dua jalur sekaligus untuk menjamin perlindungan terus-menerus:
- **Deteksi Instan**: Menutup akses dalam hitungan detik jika ada login dari perangkat lain yang mencurigakan atau jika akses dicabut oleh Owner.
- **Pengecekan Cadangan (Fail-Safe)**: Melakukan validasi ulang secara otomatis setiap 15 menit, memastikan aplikasi tetap aman meskipun koneksi internet tidak stabil.

### 2. Penghapusan Data Jarak Jauh (Remote Wipe)
Fitur "Self-Destruct" yang memastikan data bengkel Anda tidak jatuh ke tangan yang salah. Jika akun dinonaktifkan oleh Owner, sistem akan otomatis:
- **Mengunci Aplikasi**: Memblokir seluruh interaksi agar tidak ada yang bisa melihat data transaksi atau pelanggan Anda.
- **Pembersihan Permanen**: Menghapus seluruh data bengkel, kata sandi, dan kunci enkripsi dari memori perangkat secara permanen.
- **Keamanan Maksimal**: Memastikan perangkat bersih dari informasi sensitif, bahkan jika perangkat fisik dicuri atau hilang.

### 3. Verifikasi Keamanan Berlapis (Anti-Accidental Wipe)
Teknologi pendukung untuk memastikan proteksi hanya berjalan saat benar-benar dibutuhkan:
- Sistem akan melakukan konfirmasi langsung ke server keamanan sebelum mulai menghapus data, guna menghindari kesalahan akibat gangguan sinyal.
- Jika koneksi benar-benar terputus total, sistem akan menunda penghapusan (*Safe Stop*) untuk melindungi data berharga Anda hingga status benar-benar terkonfirmasi.

### 4. Operasi Latar Belakang yang Cerdas
- Proses sinkronisasi data kini bekerja lebih pintar untuk mencegah kerusakan data saat sistem keamanan sedang aktif, menjaga kesehatan database bengkel Anda di segala kondisi.

---
**Catatan Keamanan**:
Data Anda adalah aset paling berharga. Dengan sistem ini, Anda memiliki kendali penuh untuk memutuskan akses dan memusnahkan jejak data sensitif pada perangkat manapun secara jarak jauh.
