// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sharedPreferencesHash() => r'd6ff5a76096f5cc5efc48aeb27532f2ca5ed6058';

/// See also [sharedPreferences].
@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = Provider<SharedPreferences>.internal(
  sharedPreferences,
  name: r'sharedPreferencesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sharedPreferencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SharedPreferencesRef = ProviderRef<SharedPreferences>;
String _$trxNumberServiceHash() => r'05f5fbe71cf14f58e434e8a7913d15d53564d511';

/// See also [trxNumberService].
@ProviderFor(trxNumberService)
final trxNumberServiceProvider = AutoDisposeProvider<TrxNumberService>.internal(
  trxNumberService,
  name: r'trxNumberServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trxNumberServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TrxNumberServiceRef = AutoDisposeProviderRef<TrxNumberService>;
String _$encryptionServiceHash() => r'38c86d5786979d73370b3ffaa6baceb66c7f33a0';

/// See also [encryptionService].
@ProviderFor(encryptionService)
final encryptionServiceProvider = Provider<EncryptionService>.internal(
  encryptionService,
  name: r'encryptionServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$encryptionServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EncryptionServiceRef = ProviderRef<EncryptionService>;
String _$backupServiceHash() => r'7e6c987626b327de072331935562c0cc6322173f';

/// See also [backupService].
@ProviderFor(backupService)
final backupServiceProvider = AutoDisposeProvider<BackupService>.internal(
  backupService,
  name: r'backupServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backupServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BackupServiceRef = AutoDisposeProviderRef<BackupService>;
String _$localBackupServiceHash() =>
    r'237c3ba0bc0717ec0d7923b19b2020c860a7d54b';

/// See also [localBackupService].
@ProviderFor(localBackupService)
final localBackupServiceProvider =
    AutoDisposeProvider<LocalBackupService>.internal(
  localBackupService,
  name: r'localBackupServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localBackupServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LocalBackupServiceRef = AutoDisposeProviderRef<LocalBackupService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
