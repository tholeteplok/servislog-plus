// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reminderTransactionsHash() =>
    r'4346100452ad66df2b5d6542b607130d6424d87e';

/// Provider untuk daftar transaksi yang memerlukan pengingat servis.
/// Memastikan hanya mengambil transaksi terbaru untuk setiap kendaraan yang sudah LUNAS.
///
/// Copied from [reminderTransactions].
@ProviderFor(reminderTransactions)
final reminderTransactionsProvider =
    AutoDisposeProvider<List<Transaction>>.internal(
  reminderTransactions,
  name: r'reminderTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reminderTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ReminderTransactionsRef = AutoDisposeProviderRef<List<Transaction>>;
String _$reminderCountHash() => r'b321cfcd772f6903c91bfa1ff2e17421a3ab7397';

/// Provider untuk jumlah total pengingat aktif (untuk ditampilkan di Bento Card).
///
/// Copied from [reminderCount].
@ProviderFor(reminderCount)
final reminderCountProvider = AutoDisposeProvider<int>.internal(
  reminderCount,
  name: r'reminderCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reminderCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ReminderCountRef = AutoDisposeProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
