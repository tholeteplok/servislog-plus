// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$historyFilterNotifierHash() =>
    r'bf05ca86f622ff34e91e10ffd2b4bf5f9cf32b23';

/// See also [HistoryFilterNotifier].
@ProviderFor(HistoryFilterNotifier)
final historyFilterNotifierProvider =
    AutoDisposeNotifierProvider<HistoryFilterNotifier, HistoryFilter>.internal(
  HistoryFilterNotifier.new,
  name: r'historyFilterNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historyFilterNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HistoryFilterNotifier = AutoDisposeNotifier<HistoryFilter>;
String _$historySearchActiveHash() =>
    r'bbeb240027af2b672c89ee52087d140e8222ae54';

/// Provider to toggle search mode in History screen
///
/// Copied from [HistorySearchActive].
@ProviderFor(HistorySearchActive)
final historySearchActiveProvider =
    AutoDisposeNotifierProvider<HistorySearchActive, bool>.internal(
  HistorySearchActive.new,
  name: r'historySearchActiveProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historySearchActiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HistorySearchActive = AutoDisposeNotifier<bool>;
String _$historySearchQueryHash() =>
    r'f21e58fb68d9e86aa95c4c6c2550fddb68c4dc1f';

/// Provider to store the current search query for History
///
/// Copied from [HistorySearchQuery].
@ProviderFor(HistorySearchQuery)
final historySearchQueryProvider =
    AutoDisposeNotifierProvider<HistorySearchQuery, String>.internal(
  HistorySearchQuery.new,
  name: r'historySearchQueryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$historySearchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HistorySearchQuery = AutoDisposeNotifier<String>;
String _$historyListHash() => r'c4c1b2617780a0eb0e2c72897fda4f55f6f57ba4';

/// Notifier to handle paginated, merged history (Transactions + Sales)
///
/// Copied from [HistoryList].
@ProviderFor(HistoryList)
final historyListProvider =
    AutoDisposeNotifierProvider<HistoryList, HistoryState>.internal(
  HistoryList.new,
  name: r'historyListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$historyListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HistoryList = AutoDisposeNotifier<HistoryState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
