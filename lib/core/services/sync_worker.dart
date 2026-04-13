import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../domain/entities/sync_queue_item.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/pelanggan.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/stok.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_item.dart';
import '../../domain/entities/stok_history.dart';
import 'firestore_sync_service.dart';
import '../providers/objectbox_provider.dart';
import '../../objectbox.g.dart';
import '../sync/sync_lock_manager.dart';
import '../sync/circuit_breaker.dart';
import '../sync/sync_telemetry.dart';
import '../sync/concurrency_pool.dart';
import 'device_session_service.dart';

/// 🏎️ SyncWorker — Optimized background worker with Concurrency Pool(2).
/// Implements the ServisLog+ Sync Framework v1.4 for production reliability.
class SyncWorker {
  final ObjectBoxProvider _db;
  final FirestoreSyncService _syncService;
  final DeviceSessionService? _deviceService;
  final String bengkelId;
  final String? userId;

  // FIX [PERINGATAN]: Tambah parameter syncWifiOnly agar setting dari UI
  // pengaturan benar-benar diterapkan saat memproses antrian sync.
  final bool syncWifiOnly;

  Timer? _timer;
  bool _isRunning = false;
  StreamSubscription? _connectivitySubscription;

  // Framework Components
  final _lockManager = SyncLockManager();
  final _circuitBreaker = HierarchicalCircuitBreaker();
  final _pool = Pool(2); // Concurrency Level 2

  // Callbacks for UI updates
  void Function(SyncWorkerState state)? onStateChanged;

  SyncWorker({
    required ObjectBoxProvider db,
    required FirestoreSyncService syncService,
    required this.bengkelId,
    this.userId,
    DeviceSessionService? deviceService,
    this.onStateChanged,
    this.syncWifiOnly = false, // default: sync di semua koneksi
  })  : _db = db,
        _syncService = syncService,
        _deviceService = deviceService;

  /// Start background sync — checks every 30 seconds + on network change.
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Process immediately
    _processQueue();

    // Check every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _processQueue();
    });

    // Also process on network change
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _processQueue();
      }
    });

    SyncTelemetry().log(SyncEvent(
      type: 'worker_started',
      metadata: {'bengkelId': bengkelId, 'syncWifiOnly': syncWifiOnly},
      level: TelemetryLevel.info,
      timestamp: DateTime.now(),
    ));
  }

  /// Stop background sync.
  void stop() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    _isRunning = false;
    _lockManager.stopAutoHeartbeat();
    SyncTelemetry().log(SyncEvent(
      type: 'worker_stopped',
      level: TelemetryLevel.info,
      timestamp: DateTime.now(),
    ));
  }

  /// Enqueue an entity for sync.
  void enqueue({
    required String entityType,
    required String entityUuid,
    SyncPriority priority = SyncPriority.normal,
  }) {
    if (_db.store.isClosed()) {
      SyncTelemetry().log(SyncEvent(
        type: 'enqueue_skipped',
        metadata: {'reason': 'store_closed'},
        level: TelemetryLevel.warning,
        timestamp: DateTime.now(),
      ));
      return;
    }
    final item = SyncQueueItem(
      entityType: entityType,
      entityUuid: entityUuid,
      priority: priority.code,
    );
    _db.syncQueueBox.put(item);

    // Try to process immediately for critical items
    if (priority == SyncPriority.critical) {
      _processQueue();
    }
  }

  /// Process the queue — using SyncLockManager and Concurrency Pool.
  Future<void> _processQueue() async {
    if (_db.store.isClosed()) return;

    // 1. Acquire lock with heartbeat
    if (!await _lockManager.acquire()) {
      debugPrint('SyncWorker: Another sync process is active, skipping');
      return;
    }

    // 1b. Device Heartbeat Sync
    final currentUserId = userId;
    if (_deviceService != null && currentUserId != null) {
      unawaited(_deviceService.heartbeatSync(currentUserId));
    }

    try {
      _lockManager.startAutoHeartbeat();
      SyncTelemetry().lockAcquired();

      // FIX [PERINGATAN]: Pemeriksaan koneksi sekarang menghormati
      // setting syncWifiOnly dari pengaturan pengguna.
      final connectivity = await Connectivity().checkConnectivity();

      if (connectivity == ConnectivityResult.none) {
        // Tidak ada koneksi sama sekali — skip
        return;
      }

      if (syncWifiOnly && connectivity != ConnectivityResult.wifi) {
        // User memilih "Sync hanya via WiFi" tapi sedang pakai data seluler
        debugPrint('SyncWorker: Skipping sync — not on WiFi (syncWifiOnly=true)');
        SyncTelemetry().log(SyncEvent(
          type: 'sync_skipped_wifi_only',
          metadata: {'connectivity': connectivity.toString()},
          level: TelemetryLevel.info,
          timestamp: DateTime.now(),
        ));
        return;
      }

      onStateChanged?.call(SyncWorkerState.syncing);

      // 2. Fetch pending items
      final items = _db.syncQueueBox
          .query(SyncQueueItem_.status.equals('pending'))
          .order(SyncQueueItem_.priority)
          .order(SyncQueueItem_.createdAt)
          .build()
          .find();

      if (items.isEmpty) {
        onStateChanged?.call(SyncWorkerState.idle);
        return;
      }

      // 3. Process with Concurrency Pool(2)
      await Future.wait(
        items.map((item) => _pool.withResource(() => _syncWithProtection(item))),
        eagerError: false,
      );

      final hasErrors = _db.syncQueueBox
              .query(SyncQueueItem_.status.equals('pending'))
              .build()
              .count() >
          0;

      onStateChanged?.call(
          hasErrors ? SyncWorkerState.error : SyncWorkerState.success);
    } catch (e, stack) {
      SyncTelemetry().log(SyncEvent(
        type: 'queue_processing_error',
        metadata: {'error': e.toString()},
        level: TelemetryLevel.error,
        stackTrace: stack,
        timestamp: DateTime.now(),
      ));
      onStateChanged?.call(SyncWorkerState.error);
    } finally {
      await _lockManager.release();
      SyncTelemetry().lockReleased();
    }
  }

  /// Protects single item sync with CircuitBreaker and Telemetry.
  Future<void> _syncWithProtection(SyncQueueItem item) async {
    final decision =
        _circuitBreaker.shouldProceed(item.entityUuid, DriveErrorType.unknown);
    if (decision == SyncDecision.block) return;

    try {
      item.status = 'syncing';
      _db.syncQueueBox.put(item);

      SyncTelemetry().syncStart(item.entityUuid, item.entityType);
      final startTime = DateTime.now();

      await _syncEntity(item);

      item.status = 'synced';
      item.syncedAt = DateTime.now();
      item.retryCount = 0;
      _db.syncQueueBox.put(item);

      _circuitBreaker.recordSuccess(item.entityUuid);
      SyncTelemetry()
          .syncSuccess(item.entityUuid, DateTime.now().difference(startTime));
    } catch (e) {
      item.retryCount++;
      final errorType = _classifyError(e);
      _circuitBreaker.recordFailure(item.entityUuid, errorType);

      if (item.retryCount >= 5) {
        item.status = 'failed';
      } else {
        item.status = 'pending';
      }
      _db.syncQueueBox.put(item);

      SyncTelemetry().syncFailed(
        item.entityUuid,
        e.toString(),
        errorType: errorType,
        retryCount: item.retryCount,
      );
    }
  }

  /// Categorize errors for CircuitBreaker decisions.
  DriveErrorType _classifyError(dynamic e) {
    final errorString = e.toString().toLowerCase();
    if (errorString.contains('quota')) return DriveErrorType.quotaExceeded;
    if (errorString.contains('ratelimit') || errorString.contains('429')) {
      return DriveErrorType.rateLimit;
    }
    if (errorString.contains('auth') || errorString.contains('401')) {
      return DriveErrorType.auth;
    }
    if (errorString.contains('permission') || errorString.contains('403')) {
      return DriveErrorType.permission;
    }
    if (errorString.contains('not found') || errorString.contains('404')) {
      return DriveErrorType.notFound;
    }
    if (errorString.contains('network') ||
        errorString.contains('connectivity')) {
      return DriveErrorType.network;
    }
    return DriveErrorType.unknown;
  }

  /// Sync a single entity (Core Implementation).
  Future<void> _syncEntity(SyncQueueItem item) async {
    switch (item.entityType) {
      case 'transaction':
        final tx = _db.transactionBox
            .query(Transaction_.uuid.equals(item.entityUuid))
            .build()
            .findFirst();
        if (tx != null) {
          await _syncService.pushTransaction(bengkelId, tx);
          tx.syncStatus = SyncStatus.synced.code;
          tx.lastSyncedAt = DateTime.now();
          _db.transactionBox.put(tx);
        }
        break;
      case 'pelanggan':
        final p = _db.pelangganBox
            .query(Pelanggan_.uuid.equals(item.entityUuid))
            .build()
            .findFirst();
        if (p != null) await _syncService.pushPelanggan(bengkelId, p);
        break;
      case 'stok':
        final s = _db.stokBox
            .query(Stok_.uuid.equals(item.entityUuid))
            .build()
            .findFirst();
        if (s != null) await _syncService.pushStok(bengkelId, s);
        break;
      case 'staff':
        final s = _db.staffBox
            .query(Staff_.uuid.equals(item.entityUuid))
            .build()
            .findFirst();
        if (s != null) await _syncService.pushStaff(bengkelId, s);
        break;
      case 'vehicle':
        final v = _db.vehicleBox
            .query(Vehicle_.uuid.equals(item.entityUuid))
            .build()
            .findFirst();
        if (v != null) await _syncService.pushVehicle(bengkelId, v);
        break;
      case 'stok_history':
        final sh = _db.stokHistoryBox
            .query(StokHistory_.uuid.equals(item.entityUuid))
            .build()
            .findFirst();
        if (sh != null) await _syncService.pushStokHistory(bengkelId, sh);
        break;
    }
  }

  /// Rebuild local database from Firestore data (Restore process).
  Future<void> syncDownAll(Map<String, List<Map<String, dynamic>>> data) async {
    if (_db.store.isClosed()) return;

    await _db.store.runInTransactionAsync(TxMode.write, (store, dataMap) {
      // 1. Staff
      final staffBox = store.box<Staff>();
      final staffList = (dataMap['staff'] as List).map((m) {
        return Staff(
          name: m['name'] ?? '',
          role: m['role'] ?? 'mekanik',
          phoneNumber: m['phone'],
          uuid: m['uuid'],
        )
          ..bengkelId = m['bengkelId'] ?? ''
          ..isActive = m['isActive'] ?? true;
      }).toList();
      staffBox.putMany(staffList);

      // 2. Customers
      final customerBox = store.box<Pelanggan>();
      final customerList = (dataMap['customers'] as List).map((m) {
        return Pelanggan(
          nama: m['name'] ?? '',
          telepon: m['phone'] ?? '',
          alamat: m['address'] ?? '',
          uuid: m['uuid'],
        )..bengkelId = m['bengkelId'] ?? '';
      }).toList();
      customerBox.putMany(customerList);

      // 3. Vehicles
      final vehicleBox = store.box<Vehicle>();
      final vehicleList = (dataMap['vehicles'] as List).map((m) {
        final v = Vehicle(
          model: m['model'] ?? '',
          plate: m['plate'] ?? '',
          year: m['year'],
          color: m['color'],
          uuid: m['uuid'],
        );
        final ownerUuid = m['ownerUuid'] as String?;
        if (ownerUuid != null) {
          final owner = customerBox
              .query(Pelanggan_.uuid.equals(ownerUuid))
              .build()
              .findFirst();
          if (owner != null) v.owner.target = owner;
        }
        return v;
      }).toList();
      vehicleBox.putMany(vehicleList);

      // 4. Inventory (Stok)
      final stokBox = store.box<Stok>();
      final stokList = (dataMap['inventory'] as List).map((m) {
        return Stok(
          nama: m['nama'] ?? '',
          sku: m['sku'],
          hargaBeli: m['hargaBeli'] ?? 0,
          hargaJual: m['hargaJual'] ?? 0,
          jumlah: m['jumlah'] ?? 0,
          minStok: m['minStok'] ?? 5,
          kategori: m['kategori'] ?? 'Sparepart',
          uuid: m['uuid'],
        )
          ..bengkelId = m['bengkelId'] ?? ''
          ..createdAt = _toDateTime(m['createdAt'])
          ..updatedAt = _toDateTime(m['updatedAt']);
      }).toList();
      stokBox.putMany(stokList);

      // 5. Transactions & Items
      final transactionBox = store.box<Transaction>();
      final transactionItemBox = store.box<TransactionItem>();

      for (var m in (dataMap['transactions'] as List)) {
        final tx = Transaction(
          customerName: m['customerName'] ?? '',
          customerPhone: m['customerPhone'] ?? '',
          vehicleModel: m['vehicleModel'] ?? '',
          vehiclePlate: m['vehiclePlate'] ?? '',
          uuid: m['uuid'],
          trxNumber: m['trxNumber'],
          complaint: m['complaint'],
          mechanicNotes: m['mechanicNotes'],
          recommendationTimeMonth: m['recommendationTimeMonth'],
          recommendationKm: m['recommendationKm'],
          odometer: m['odometer'],
        )
          ..bengkelId = m['bengkelId'] ?? ''
          ..status = m['status'] ?? 'pending'
          ..statusValue = m['statusValue'] ?? 0
          ..paymentMethod = m['paymentMethod']
          ..totalAmount = m['totalAmount'] ?? 0
          ..partsCost = m['partsCost'] ?? 0
          ..laborCost = m['laborCost'] ?? 0
          ..totalRevenue = m['totalRevenue'] ?? 0
          ..totalHpp = m['totalHpp'] ?? 0
          ..totalMechanicBonus = m['totalMechanicBonus'] ?? 0
          ..totalProfit = m['totalProfit'] ?? 0
          ..createdAt = _toDateTime(m['createdAt'])
          ..updatedAt = _toDateTime(m['updatedAt'])
          ..syncStatus = 2;

        final custUuid = m['customerUuid'] as String?;
        if (custUuid != null) {
          tx.pelanggan.target = customerBox
              .query(Pelanggan_.uuid.equals(custUuid))
              .build()
              .findFirst();
        }
        final vehUuid = m['vehicleUuid'] as String?;
        if (vehUuid != null) {
          tx.vehicle.target = vehicleBox
              .query(Vehicle_.uuid.equals(vehUuid))
              .build()
              .findFirst();
        }
        final mechUuid = m['mechanicUuid'] as String?;
        if (mechUuid != null) {
          tx.mechanic.target = staffBox
              .query(Staff_.uuid.equals(mechUuid))
              .build()
              .findFirst();
        }

        transactionBox.put(tx);

        final List<Map<String, dynamic>> itemsList = m['items'] ?? [];
        for (var im in itemsList) {
          final item = TransactionItem(
            name: im['name'] ?? '',
            price: im['price'] ?? 0,
            costPrice: im['costPrice'] ?? 0,
            quantity: im['quantity'] ?? 1,
            isService: im['isService'] ?? false,
            notes: im['notes'],
            mechanicBonus: im['mechanicBonus'] ?? 0,
            uuid: im['uuid'],
            createdAt: _toDateTime(im['createdAt']),
            updatedAt: _toDateTime(im['updatedAt']),
          );
          item.transaction.target = tx;
          transactionItemBox.put(item);
        }
      }

      // 6. Inventory History
      final historyBox = store.box<StokHistory>();
      final historyList = (dataMap['stok_history'] as List).map((m) {
        return StokHistory(
          stokUuid: m['stokUuid'] ?? '',
          quantityChange: m['changeAmount'] ?? 0,
          previousQuantity: m['previousAmount'] ?? 0,
          newQuantity: m['newAmount'] ?? 0,
          type: m['type'] ?? 'adjustment',
          note: m['notes'],
          uuid: m['uuid'],
          createdAt: _toDateTime(m['createdAt']),
        );
      }).toList();
      historyBox.putMany(historyList);
    }, data);
  }

  DateTime _toDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.now();
  }

  void cleanupSyncedItems() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final oldItems = _db.syncQueueBox
        .query(SyncQueueItem_.status.equals('synced') &
            SyncQueueItem_.syncedAt
                .lessThan(cutoff.millisecondsSinceEpoch))
        .build()
        .find();
    for (final item in oldItems) {
      _db.syncQueueBox.remove(item.id);
    }
  }
}

enum SyncWorkerState { idle, syncing, success, error }
