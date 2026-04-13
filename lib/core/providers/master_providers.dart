import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:objectbox/objectbox.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/service_master.dart';
import '../../domain/entities/vehicle.dart';
import '../../data/repositories/master_repositories.dart';
import 'objectbox_provider.dart';
import 'sync_provider.dart';

part 'master_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Staff Providers
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
StaffRepository staffRepository(StaffRepositoryRef ref) {
  final db = ref.watch(dbProvider);
  return StaffRepository(Box<Staff>(db.store));
}

@riverpod
class StaffList extends _$StaffList {
  @override
  FutureOr<List<Staff>> build() async {
    final repository = ref.watch(staffRepositoryProvider);
    return repository.getAll();
  }

  Future<void> add(Staff staff) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(staffRepositoryProvider);
      final syncWorker = ref.read(syncWorkerProvider);
      repository.save(staff);
      syncWorker?.enqueue(entityType: 'staff', entityUuid: staff.uuid);
      return repository.getAll();
    });
  }

  Future<void> updateStaff(Staff staff) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(staffRepositoryProvider);
      final syncWorker = ref.read(syncWorkerProvider);
      repository.save(staff);
      syncWorker?.enqueue(entityType: 'staff', entityUuid: staff.uuid);
      return repository.getAll();
    });
  }

  Future<void> delete(int id) async {
    final stateBefore = state.valueOrNull ?? [];
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(staffRepositoryProvider);
      final syncWorker = ref.read(syncWorkerProvider);
      final staff = repository.getById(id);
      if (staff != null && repository.softDelete(id)) {
        syncWorker?.enqueue(entityType: 'staff', entityUuid: staff.uuid);
        return repository.getAll();
      }
      return stateBefore;
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service Master Providers
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
ServiceMasterRepository serviceMasterRepository(
    ServiceMasterRepositoryRef ref) {
  final db = ref.watch(dbProvider);
  return ServiceMasterRepository(Box<ServiceMaster>(db.store));
}

@riverpod
class ServiceMasterList extends _$ServiceMasterList {
  @override
  FutureOr<List<ServiceMaster>> build() async {
    final repository = ref.watch(serviceMasterRepositoryProvider);
    return repository.getAll();
  }

  Future<void> addItem(ServiceMaster item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(serviceMasterRepositoryProvider);
      repository.save(item);
      return repository.getAll();
    });
  }

  Future<void> updateItem(ServiceMaster item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(serviceMasterRepositoryProvider);
      repository.save(item);
      return repository.getAll();
    });
  }

  Future<void> deleteItem(int id) async {
    final stateBefore = state.valueOrNull ?? [];
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(serviceMasterRepositoryProvider);
      if (repository.softDelete(id)) {
        return repository.getAll();
      }
      return stateBefore;
    });
  }

  // FIX [MINOR]: search() shell dihapus. Gunakan provider turunan di bawah.
}

// Provider turunan untuk pencarian service master — menggantikan shell search().
// Gunakan ini di UI: ref.watch(filteredServiceMasterProvider(query))
@riverpod
List<ServiceMaster> filteredServiceMaster(
    FilteredServiceMasterRef ref, String query) {
  final asyncList = ref.watch(serviceMasterListProvider);
  final list = asyncList.valueOrNull ?? [];
  if (query.isEmpty) return list;
  final q = query.toLowerCase();
  return list.where((s) => s.name.toLowerCase().contains(q)).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Providers
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
VehicleRepository vehicleRepository(VehicleRepositoryRef ref) {
  final db = ref.watch(dbProvider);
  return VehicleRepository(Box<Vehicle>(db.store));
}

@riverpod
class VehicleList extends _$VehicleList {
  @override
  FutureOr<List<Vehicle>> build() async {
    final repository = ref.watch(vehicleRepositoryProvider);
    return repository.getAll();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(vehicleRepositoryProvider);
      final syncWorker = ref.read(syncWorkerProvider);
      repository.save(vehicle);
      syncWorker?.enqueue(entityType: 'vehicle', entityUuid: vehicle.uuid);
      return repository.getAll();
    });
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(vehicleRepositoryProvider);
      final syncWorker = ref.read(syncWorkerProvider);
      repository.save(vehicle);
      syncWorker?.enqueue(entityType: 'vehicle', entityUuid: vehicle.uuid);
      return repository.getAll();
    });
  }

  Future<void> deleteVehicle(int id) async {
    final stateBefore = state.valueOrNull ?? [];
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(vehicleRepositoryProvider);
      final syncWorker = ref.read(syncWorkerProvider);
      final vehicle = repository.getById(id);
      if (vehicle != null && repository.softDelete(id)) {
        syncWorker?.enqueue(entityType: 'vehicle', entityUuid: vehicle.uuid);
        return repository.getAll();
      }
      return stateBefore;
    });
  }

  // FIX [MINOR]: search() shell dihapus.
}

@riverpod
List<Vehicle> customerVehicles(CustomerVehiclesRef ref, int pelangganId) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return repository.getByOwnerId(pelangganId);
}
