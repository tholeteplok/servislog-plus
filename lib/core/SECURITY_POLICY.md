# 🛡️ ServisLog+ Hybrid Security Policy (v2.0)

## Overview
Implementasi keamanan berbasis **Three Zones v2.0** yang mengoptimalkan keseimbangan antara keamanan data dan kelancaran operasional bengkel (UX) dalam kondisi konektivitas tidak stabil.

## Tiga Zona Keamanan (Three Zones)

| Zona | Status | Kondisi (Offline) | Akses |
| :--- | :--- | :--- | :--- |
| **Zone 1: Safety** | 🟢 Green | Owner < 12h, Staff < 8h | **Full Access** (Create, Read, Update, Delete*) |
| **Zone 2: Warning** | 🟡 Yellow | Owner 12-24h, Staff 8-9h | **Restricted**: ReadOnly (Staff) / RO Financial (Owner) |
| **Zone 3: Blocked** | 🔴 Red | Owner > 24h, Staff > 9h | **No Access** (Perlu Online Handshake) |

> [!IMPORTANT]
> **Hard Limit**: Kedaluwarsa Token JWT Firebase tetap menjadi batas absolut. Jika Token habis, aplikasi akan terkunci (Blocked) tanpa memandang durasi offline.

## Mekanisme Verifikasi

### 1. Online Handshake
Dilakukan otomatis setiap kali ada koneksi internet (dengan cache 15 menit).
- **Endpoint**: `functions/verifySession`
- **Logic**: Memeriksa validitas token, status akun, dan device ID.
- **Auto-Sync**: Mengunggah *Emergency Audit Logs* ke Firestore jika ada.
- **JWT Refresh**: Melakukan `getIdToken(true)` untuk memastikan token tetap segar.

### 2. Critical Action Guard
Setiap aksi kritis wajib melewati re-autentikasi (Biometrik):
- Hapus Transaksi
- Edit Biaya Lunas
- Export Data
- Lihat Laporan Keuangan
- Kelola Staff
- Ubah Pengaturan

### 3. Emergency Override (Owner Only)
Owner dapat memperpanjang sesi offline selama 24 jam dalam kondisi darurat:
- Verifikasi Biometrik (3x percobaan).
- Fallback ke **6-digit Master Password** (PIN khusus Owner).
- Setiap Override dicatat dalam Audit Log yang akan di-sync saat online.

## Integrasi Kode

### Menambahkan Status Bar
Letakkan `SessionStatusBar()` di bawah `AppBar` pada setiap screen utama.
```dart
Scaffold(
  appBar: AppBar(title: Text('Dashboard')),
  body: Column(
    children: [
      const SessionStatusBar(), // <-- Indikator Status
      Expanded(child: MainContent()),
    ],
  ),
)
```

### Melindungi Aksi Kritis
Bungkus widget interaktif dengan `CriticalActionGuard`.
```dart
CriticalActionGuard(
  actionType: CriticalActionType.deleteTransaction,
  onVerified: () => _performDelete(),
  child: Icon(Icons.delete),
)
```

## Audit Logging
Semua kejadian keamanan dicatat secara lokal di `FlutterSecureStorage` dan disinkronisasi ke koleksi `bengkel/{id}/security_audit_logs` di Firestore saat perangkat kembali online.

---
*Terakhir Diperbarui: 2026-04-06*
