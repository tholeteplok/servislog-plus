// DEPRECATED — File ini tidak lagi digunakan dan akan dihapus.
//
// Semua provider yang ada di sini telah dipindahkan ke:
//   - system_providers.dart  (sharedPreferencesProvider, trxNumberServiceProvider,
//                             backupServiceProvider, localBackupServiceProvider)
//
// Jika ada file yang masih import dari service_providers.dart, ganti dengan:
//   import 'package:servislog_core/core/providers/system_providers.dart';
//
// Menghapus file ini akan menghilangkan duplikasi sharedPreferencesProvider
// yang dapat menyebabkan ambiguitas dependency di Riverpod.
//
// File ini dikosongkan (bukan dihapus) untuk menjaga kompatibilitas build
// selama proses migrasi. Hapus file ini setelah tidak ada lagi yang mengimpornya.
