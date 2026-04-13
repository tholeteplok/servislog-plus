// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'master_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staffRepositoryHash() => r'3f7507dd961dda70aa4a63166e77bf70d3223b27';

/// See also [staffRepository].
@ProviderFor(staffRepository)
final staffRepositoryProvider = Provider<StaffRepository>.internal(
  staffRepository,
  name: r'staffRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$staffRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StaffRepositoryRef = ProviderRef<StaffRepository>;
String _$serviceMasterRepositoryHash() =>
    r'6772bccaeea255a038e3ebf9690502c9fff336a4';

/// See also [serviceMasterRepository].
@ProviderFor(serviceMasterRepository)
final serviceMasterRepositoryProvider =
    Provider<ServiceMasterRepository>.internal(
  serviceMasterRepository,
  name: r'serviceMasterRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$serviceMasterRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ServiceMasterRepositoryRef = ProviderRef<ServiceMasterRepository>;
String _$filteredServiceMasterHash() =>
    r'81b020ca6c9420a04c8faa0c94335709f7374cc0';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [filteredServiceMaster].
@ProviderFor(filteredServiceMaster)
const filteredServiceMasterProvider = FilteredServiceMasterFamily();

/// See also [filteredServiceMaster].
class FilteredServiceMasterFamily extends Family<List<ServiceMaster>> {
  /// See also [filteredServiceMaster].
  const FilteredServiceMasterFamily();

  /// See also [filteredServiceMaster].
  FilteredServiceMasterProvider call(
    String query,
  ) {
    return FilteredServiceMasterProvider(
      query,
    );
  }

  @override
  FilteredServiceMasterProvider getProviderOverride(
    covariant FilteredServiceMasterProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'filteredServiceMasterProvider';
}

/// See also [filteredServiceMaster].
class FilteredServiceMasterProvider
    extends AutoDisposeProvider<List<ServiceMaster>> {
  /// See also [filteredServiceMaster].
  FilteredServiceMasterProvider(
    String query,
  ) : this._internal(
          (ref) => filteredServiceMaster(
            ref as FilteredServiceMasterRef,
            query,
          ),
          from: filteredServiceMasterProvider,
          name: r'filteredServiceMasterProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filteredServiceMasterHash,
          dependencies: FilteredServiceMasterFamily._dependencies,
          allTransitiveDependencies:
              FilteredServiceMasterFamily._allTransitiveDependencies,
          query: query,
        );

  FilteredServiceMasterProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    List<ServiceMaster> Function(FilteredServiceMasterRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredServiceMasterProvider._internal(
        (ref) => create(ref as FilteredServiceMasterRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<ServiceMaster>> createElement() {
    return _FilteredServiceMasterProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredServiceMasterProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FilteredServiceMasterRef on AutoDisposeProviderRef<List<ServiceMaster>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _FilteredServiceMasterProviderElement
    extends AutoDisposeProviderElement<List<ServiceMaster>>
    with FilteredServiceMasterRef {
  _FilteredServiceMasterProviderElement(super.provider);

  @override
  String get query => (origin as FilteredServiceMasterProvider).query;
}

String _$vehicleRepositoryHash() => r'590a65227e98069a3ae72c79d4d2ec120594d1be';

/// See also [vehicleRepository].
@ProviderFor(vehicleRepository)
final vehicleRepositoryProvider = Provider<VehicleRepository>.internal(
  vehicleRepository,
  name: r'vehicleRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$vehicleRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VehicleRepositoryRef = ProviderRef<VehicleRepository>;
String _$customerVehiclesHash() => r'8d7f7ac78a6e6c9e205ed43a1e620c94b8a54675';

/// See also [customerVehicles].
@ProviderFor(customerVehicles)
const customerVehiclesProvider = CustomerVehiclesFamily();

/// See also [customerVehicles].
class CustomerVehiclesFamily extends Family<List<Vehicle>> {
  /// See also [customerVehicles].
  const CustomerVehiclesFamily();

  /// See also [customerVehicles].
  CustomerVehiclesProvider call(
    int pelangganId,
  ) {
    return CustomerVehiclesProvider(
      pelangganId,
    );
  }

  @override
  CustomerVehiclesProvider getProviderOverride(
    covariant CustomerVehiclesProvider provider,
  ) {
    return call(
      provider.pelangganId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'customerVehiclesProvider';
}

/// See also [customerVehicles].
class CustomerVehiclesProvider extends AutoDisposeProvider<List<Vehicle>> {
  /// See also [customerVehicles].
  CustomerVehiclesProvider(
    int pelangganId,
  ) : this._internal(
          (ref) => customerVehicles(
            ref as CustomerVehiclesRef,
            pelangganId,
          ),
          from: customerVehiclesProvider,
          name: r'customerVehiclesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$customerVehiclesHash,
          dependencies: CustomerVehiclesFamily._dependencies,
          allTransitiveDependencies:
              CustomerVehiclesFamily._allTransitiveDependencies,
          pelangganId: pelangganId,
        );

  CustomerVehiclesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.pelangganId,
  }) : super.internal();

  final int pelangganId;

  @override
  Override overrideWith(
    List<Vehicle> Function(CustomerVehiclesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CustomerVehiclesProvider._internal(
        (ref) => create(ref as CustomerVehiclesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        pelangganId: pelangganId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<Vehicle>> createElement() {
    return _CustomerVehiclesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerVehiclesProvider &&
        other.pelangganId == pelangganId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pelangganId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CustomerVehiclesRef on AutoDisposeProviderRef<List<Vehicle>> {
  /// The parameter `pelangganId` of this provider.
  int get pelangganId;
}

class _CustomerVehiclesProviderElement
    extends AutoDisposeProviderElement<List<Vehicle>> with CustomerVehiclesRef {
  _CustomerVehiclesProviderElement(super.provider);

  @override
  int get pelangganId => (origin as CustomerVehiclesProvider).pelangganId;
}

String _$staffListHash() => r'c19e7417a534d941191cdbe0f4b0ef7fa64a0b86';

/// See also [StaffList].
@ProviderFor(StaffList)
final staffListProvider =
    AutoDisposeAsyncNotifierProvider<StaffList, List<Staff>>.internal(
  StaffList.new,
  name: r'staffListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$staffListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StaffList = AutoDisposeAsyncNotifier<List<Staff>>;
String _$serviceMasterListHash() => r'7a31014072a194a60297450824fe82b2dcb969ea';

/// See also [ServiceMasterList].
@ProviderFor(ServiceMasterList)
final serviceMasterListProvider = AutoDisposeAsyncNotifierProvider<
    ServiceMasterList, List<ServiceMaster>>.internal(
  ServiceMasterList.new,
  name: r'serviceMasterListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$serviceMasterListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ServiceMasterList = AutoDisposeAsyncNotifier<List<ServiceMaster>>;
String _$vehicleListHash() => r'64669ac1d31ca3a4e6bb9ecb491591f3ec6cfafa';

/// See also [VehicleList].
@ProviderFor(VehicleList)
final vehicleListProvider =
    AutoDisposeAsyncNotifierProvider<VehicleList, List<Vehicle>>.internal(
  VehicleList.new,
  name: r'vehicleListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$vehicleListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VehicleList = AutoDisposeAsyncNotifier<List<Vehicle>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
