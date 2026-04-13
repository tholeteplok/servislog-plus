import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/transaction.dart' as entity;
import '../../domain/entities/pelanggan.dart';
import '../../domain/entities/stok.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/stok_history.dart';
import '../sync/sync_telemetry.dart';
import 'encryption_service.dart';

/// Full-featured Firestore sync service for CRUD operations with collision handling.
class FirestoreSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryption = EncryptionService();

  // ===== TRANSACTIONS =====

  /// Push a Transaction to Firestore under /bengkel/{id}/transactions/{uuid}.
  /// Also pushes all TransactionItems as a sub-collection for full recovery.
  Future<void> pushTransaction(String bengkelId, entity.Transaction tx) async {
    final batch = _firestore.batch();
    
    final txRef = _firestore
        .collection('bengkel')
        .doc(bengkelId)
        .collection('transactions')
        .doc(tx.uuid);

    batch.set(txRef, {
      'uuid': tx.uuid,
      'bengkelId': bengkelId,
      'trxNumber': tx.trxNumber,
      'customerName': _encryption.encryptText(tx.customerName),
      'customerPhone': _encryption.encryptText(tx.customerPhone),
      'vehicleModel': tx.vehicleModel,
      'vehiclePlate': tx.vehiclePlate,
      'totalAmount': tx.totalAmount,
      'partsCost': tx.partsCost,
      'laborCost': tx.laborCost,
      'totalRevenue': tx.totalRevenue,
      'totalHpp': tx.totalHpp,
      'totalMechanicBonus': tx.totalMechanicBonus,
      'totalProfit': tx.totalProfit,
      'status': tx.status,
      'statusValue': tx.statusValue,
      'paymentMethod': tx.paymentMethod,
      'complaint': _encryption.encryptText(tx.complaint ?? ''),
      'mechanicNotes': _encryption.encryptText(tx.mechanicNotes ?? ''),
      'mechanicName': tx.mechanicName,
      'notes': _encryption.encryptText(tx.notes ?? ''),
      'odometer': tx.odometer,
      'recommendationTimeMonth': tx.recommendationTimeMonth,
      'recommendationKm': tx.recommendationKm,
      'photoCloudUrl': tx.photoCloudUrl,
      'isDeleted': tx.isDeleted,
      'deletedBy': tx.deletedBy,
      'deletedAt': tx.deletedAt != null
          ? Timestamp.fromDate(tx.deletedAt!)
          : null,
      'createdAt': Timestamp.fromDate(tx.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'startTime': tx.startTime != null
          ? Timestamp.fromDate(tx.startTime!)
          : null,
      'endTime':
          tx.endTime != null ? Timestamp.fromDate(tx.endTime!) : null,
      'lastReminderSentAt': tx.lastReminderSentAt != null
          ? Timestamp.fromDate(tx.lastReminderSentAt!)
          : null,
      'syncStatus': 2, // synced
    }, SetOptions(merge: true));

    // Push Items as sub-collection
    for (var item in tx.items) {
      final itemRef = txRef.collection('items').doc(item.uuid);
      batch.set(itemRef, {
        'uuid': item.uuid,
        'name': _encryption.encryptText(item.name),
        'price': item.price,
        'costPrice': item.costPrice,
        'quantity': item.quantity,
        'subtotal': item.subtotal,
        'isDeleted': item.isDeleted,
        'isService': item.isService,
        'notes': _encryption.encryptText(item.notes ?? ''),
        'mechanicBonus': item.mechanicBonus,
        'createdAt': Timestamp.fromDate(item.createdAt),
        'updatedAt': Timestamp.fromDate(item.updatedAt),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Pull a single Transaction from Firestore.
  Future<Map<String, dynamic>?> pullTransaction(
      String bengkelId, String uuid) async {
    final doc = await _firestore
        .collection('bengkel')
        .doc(bengkelId)
        .collection('transactions')
        .doc(uuid)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  /// Listen to real-time transaction changes for a bengkel.
  Stream<List<Map<String, dynamic>>> listenTransactions(String bengkelId) {
    return _firestore
        .collection('bengkel')
        .doc(bengkelId)
        .collection('transactions')
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ===== CUSTOMERS =====

  /// Push a Pelanggan to Firestore.
  Future<void> pushPelanggan(String bengkelId, Pelanggan p) async {
    final ref = _firestore
        .collection('bengkel')
        .doc(bengkelId)
        .collection('customers')
        .doc(p.uuid);

    await ref.set({
      'uuid': p.uuid,
      'name': _encryption.encryptText(p.nama),
      'phone': _encryption.encryptText(p.telepon),
      'address': _encryption.encryptText(p.alamat),
      'createdAt': Timestamp.fromDate(p.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===== INVENTORY =====

  /// Push a Stok item to Firestore.
  Future<void> pushStok(String bengkelId, Stok s) async {
    final ref = _firestore
        .collection('bengkel')
        .doc(bengkelId)
        .collection('inventory')
        .doc(s.uuid);

    await ref.set({
      'uuid': s.uuid,
      'name': s.nama,
      'category': s.kategori,
      'buyPrice': s.hargaBeli,
      'sellPrice': s.hargaJual,
      'stock': s.jumlah,
      'minStock': s.minStok,
      'unit': 'Unit', // Default since not in entity yet
      'createdAt': Timestamp.fromDate(s.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===== STAFF =====

  /// Push a Staff record to Firestore.
  Future<void> pushStaff(String bengkelId, Staff s) async {
    final ref = _firestore
        .collection('bengkel')
        .doc(bengkelId)
        .collection('staff')
        .doc(s.uuid);

    await ref.set({
      'uuid': s.uuid,
      'name': _encryption.encryptText(s.name),
      'phone': _encryption.encryptText(s.phoneNumber ?? ''),
      'role': s.role,
      'createdAt': Timestamp.fromDate(s.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===== VEHICLES =====

  /// Push a Vehicle record to Firestore.
  Future<void> pushVehicle(String bengkelId, Vehicle v) async {
    final ref = _firestore
        .collection('bengkel')
        .doc(bengkelId)
        .collection('vehicles')
        .doc(v.uuid);

    await ref.set({
      'uuid': v.uuid,
      'model': v.model,
      'type': v.type,
      'plate': v.plate,
      'color': v.color,
      'year': v.year,
      'vin': _encryption.encryptText(v.vin ?? ''),
      'ownerUuid': v.owner.target?.uuid,
      'isDeleted': v.isDeleted,
      'createdAt': Timestamp.fromDate(v.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===== STOCK HISTORY =====

  /// Push a StokHistory record to Firestore.
  Future<void> pushStokHistory(String bengkelId, StokHistory sh) async {
    final ref = _firestore
        .collection('bengkel')
        .doc(bengkelId)
        .collection('inventory_history')
        .doc(sh.uuid);

    await ref.set({
      'uuid': sh.uuid,
      'stokUuid': sh.stokUuid,
      'type': sh.type,
      'quantityChange': sh.quantityChange,
      'previousQuantity': sh.previousQuantity,
      'newQuantity': sh.newQuantity,
      'note': sh.note,
      'createdAt': Timestamp.fromDate(sh.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===== COLLISION RESOLUTION =====

  /// Merge local and remote data — remote wins if updatedAt is newer.
  Map<String, dynamic> mergeData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localUpdated = (local['updatedAt'] as Timestamp?)?.toDate();
    final remoteUpdated = (remote['updatedAt'] as Timestamp?)?.toDate();

    if (localUpdated == null) return remote;
    if (remoteUpdated == null) return local;

    // Remote is newer → use remote
    if (remoteUpdated.isAfter(localUpdated)) {
      return remote;
    }
    // Local is newer → use local
    return local;
  }

  // ===== BULK OPERATIONS =====

  /// Initial sync — pull all data for a bengkel (used after first login).
  Future<Map<String, List<Map<String, dynamic>>>> pullAllData(
      String bengkelId) async {
    try {
      final bengkelRef = _firestore.collection('bengkel').doc(bengkelId);

      // 1. Fetch main collections
      final futures = [
        bengkelRef.collection('transactions').where('isDeleted', isEqualTo: false).get(),
        bengkelRef.collection('customers').get(),
        bengkelRef.collection('inventory').get(), // Maps to 'Stok'
        bengkelRef.collection('staff').get(),
        bengkelRef.collection('vehicles').get(),
        bengkelRef.collection('inventory_history').get(), // Maps to 'StokHistory'
      ];

      final results = await Future.wait(futures);
      
      final txDocs = results[0] as QuerySnapshot;
      final customerDocs = results[1] as QuerySnapshot;
      final inventoryDocs = results[2] as QuerySnapshot;
      final staffDocs = results[3] as QuerySnapshot;
      final vehicleDocs = results[4] as QuerySnapshot;
      final historyDocs = results[5] as QuerySnapshot;

      // 2. Fetch ITEMS for every transaction (parallelized)
      final List<Map<String, dynamic>> decryptedTransactions = [];
      final List<Future<void>> itemFetchers = [];

      for (var doc in txDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final txData = decryptTransaction(data);
        final List<Map<String, dynamic>> items = [];
        txData['items'] = items; // Placeholder
        decryptedTransactions.add(txData);

        itemFetchers.add(
          doc.reference.collection('items').get().then((itemSnap) {
            for (var itemDoc in itemSnap.docs) {
              final itemData = itemDoc.data();
              items.add(decryptTransactionItem(itemData));
            }
          })
        );
      }

      // Wait for all items to be fetched
      if (itemFetchers.isNotEmpty) {
        await Future.wait(itemFetchers);
      }

      return {
        'transactions': decryptedTransactions,
        'customers': customerDocs.docs.map((d) => decryptCustomer(d.data() as Map<String, dynamic>)).toList(),
        'inventory': inventoryDocs.docs.map((d) => d.data() as Map<String, dynamic>).toList(),
        'staff': staffDocs.docs.map((d) => d.data() as Map<String, dynamic>).toList(),
        'vehicles': vehicleDocs.docs.map((d) => d.data() as Map<String, dynamic>).toList(),
        'stok_history': historyDocs.docs.map((d) => d.data() as Map<String, dynamic>).toList(),
      };
    } catch (e) {
      debugPrint('Pull All Data Error: $e');
      rethrow;
    }
  }

  // ===== MASTER KEY SYNC =====

  /// Store the wrapped master key in Firestore for other devices to sync.
  Future<void> uploadMasterKey(String bengkelId, String wrappedKey) async {
    final secretRef = _firestore.collection('bengkel').doc(bengkelId).collection('secrets').doc('masterKey');
    
    await secretRef.set({
      'value': wrappedKey,
      'updatedAt': FieldValue.serverTimestamp(),
      'version': 'v1',
    });

    // Record audit event
    SyncTelemetry().log(SyncEvent(
      type: 'security_key_uploaded',
      metadata: {'bengkelId': bengkelId},
      level: TelemetryLevel.warning,
      timestamp: DateTime.now(),
    ));
  }

  /// Download the wrapped master key from Firestore.
  Future<String?> downloadMasterKey(String bengkelId) async {
    final bengkelRef = _firestore.collection('bengkel').doc(bengkelId);
    
    // 1. Try new location first
    final secretDoc = await bengkelRef.collection('secrets').doc('masterKey').get();
    if (secretDoc.exists) {
      // Record audit event for access
      SyncTelemetry().log(SyncEvent(
        type: 'security_key_downloaded',
        metadata: {'bengkelId': bengkelId, 'source': 'secrets_sub'},
        level: TelemetryLevel.info,
        timestamp: DateTime.now(),
      ));
      return secretDoc.data()?['value'] as String?;
    }

    // 2. Fallback to legacy root location
    final doc = await bengkelRef.get();
    if (!doc.exists) return null;
    
    final legacyKey = doc.data()?['masterKey'] as String?;
    if (legacyKey != null) {
      SyncTelemetry().log(SyncEvent(
        type: 'security_key_downloaded',
        metadata: {'bengkelId': bengkelId, 'source': 'legacy_root'},
        level: TelemetryLevel.warning,
        timestamp: DateTime.now(),
      ));
    }
    return legacyKey;
  }

  // ===== DECRYPTION HELPERS =====

  /// Decrypt a transaction map from Firestore.
  Map<String, dynamic> decryptTransaction(Map<String, dynamic> data) {
    return {
      ...data,
      'customerName': _encryption.decryptText(data['customerName'] ?? '').displayValue,
      'customerPhone': _encryption.decryptText(data['customerPhone'] ?? '').displayValue,
      'complaint': _encryption.decryptText(data['complaint'] ?? '').displayValue,
      'mechanicNotes': _encryption.decryptText(data['mechanicNotes'] ?? '').displayValue,
      'notes': _encryption.decryptText(data['notes'] ?? '').displayValue,
    };
  }

  /// Decrypt a transaction item map from Firestore.
  Map<String, dynamic> decryptTransactionItem(Map<String, dynamic> data) {
    return {
      ...data,
      'name': _encryption.decryptText(data['name'] ?? '').displayValue,
      'notes': _encryption.decryptText(data['notes'] ?? '').displayValue,
    };
  }

  /// Decrypt a customer map from Firestore.
  Map<String, dynamic> decryptCustomer(Map<String, dynamic> data) {
    return {
      ...data,
      'name': _encryption.decryptText(data['name'] ?? '').displayValue,
      'phone': _encryption.decryptText(data['phone'] ?? '').displayValue,
      'address': _encryption.decryptText(data['address'] ?? '').displayValue,
    };
  }
}
