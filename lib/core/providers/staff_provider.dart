// DEPRECATED — File ini akan dihapus.
//
// staffListProvider kini ada di master_providers.dart (StaffList — AsyncNotifier)
// yang mendukung soft delete dan sinkronisasi Firebase.
//
// LANGKAH MIGRASI untuk mekanik_screen.dart dan create_transaction_screen.dart:
//
// 1. Hapus import file ini:
//    import 'package:servislog_core/core/providers/staff_provider.dart';
//
// 2. Tambahkan import master_providers:
//    import 'package:servislog_core/core/providers/master_providers.dart';
//
// 3. Ganti penggunaan di widget:
//    Lama: ref.watch(staffListProvider)
//    Baru: ref.watch(staffListProvider).valueOrNull ?? []
//
//    Lama: ref.read(staffListProvider.notifier).add(staff)
//    Baru: ref.read(staffListProvider.notifier).add(staff)   ← API sama
//
//    Lama: ref.read(staffListProvider.notifier).update(staff)
//    Baru: ref.read(staffListProvider.notifier).updateStaff(staff)
//
//    Lama: ref.read(staffListProvider.notifier).delete(id)
//    Baru: ref.read(staffListProvider.notifier).delete(id)   ← API sama
//
// Setelah semua screen dimigrasikan, hapus file ini.

// ignore_for_file: unused_import
export 'master_providers.dart' show staffListProvider;
