// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreSyncServiceHash() =>
    r'0ac0a9ea68c4de28965813d8bc96d560da753166';

/// See also [firestoreSyncService].
@ProviderFor(firestoreSyncService)
final firestoreSyncServiceProvider = Provider<FirestoreSyncService>.internal(
  firestoreSyncService,
  name: r'firestoreSyncServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firestoreSyncServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FirestoreSyncServiceRef = ProviderRef<FirestoreSyncService>;
String _$syncWorkerHash() => r'0a3583675eb701d4dc20d631ca401c839a1a2175';

/// See also [syncWorker].
@ProviderFor(syncWorker)
final syncWorkerProvider = Provider<SyncWorker?>.internal(
  syncWorker,
  name: r'syncWorkerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncWorkerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SyncWorkerRef = ProviderRef<SyncWorker?>;
String _$syncStatusHash() => r'5662dc46e719daf4372496462ff306a0d7a9a88b';

/// See also [SyncStatus].
@ProviderFor(SyncStatus)
final syncStatusProvider =
    AutoDisposeNotifierProvider<SyncStatus, SyncStatusState>.internal(
  SyncStatus.new,
  name: r'syncStatusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncStatus = AutoDisposeNotifier<SyncStatusState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
