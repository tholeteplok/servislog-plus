import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../providers/objectbox_provider.dart';
import '../../domain/entities/stok.dart';
import '../../domain/entities/pelanggan.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/service_master.dart';

class LocalBackupService {
  final ObjectBoxProvider _db;

  LocalBackupService(this._db);

  /// Exports all application data to a single JSON file and shares it.
  Future<void> exportToJson() async {
    final Map<String, dynamic> data = {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'stok': _db.stokBox.getAll().map((e) => _stokToMap(e)).toList(),
      'pelanggan': _db.pelangganBox
          .getAll()
          .map((e) => _pelangganToMap(e))
          .toList(),
      'transactions': _db.transactionBox
          .getAll()
          .map((e) => _transactionToMap(e))
          .toList(),
      'sales': _db.saleBox.getAll().map((e) => _saleToMap(e)).toList(),
      'staff': _db.staffBox.getAll().map((e) => _staffToMap(e)).toList(),
      'serviceMaster': _db.store
          .box<ServiceMaster>()
          .getAll()
          .map((e) => _serviceMasterToMap(e))
          .toList(),
      'vehicles': _db.store
          .box<Vehicle>()
          .getAll()
          .map((e) => _vehicleToMap(e))
          .toList(),
    };

    final jsonString = jsonEncode(data);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/ServisLog_Backup_${_timestamp()}.json',
    );
    await file.writeAsString(jsonString);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'ServisLog+ JSON Data Export');
  }

  /// Exports specific data type to CSV for Excel compatibility.
  Future<void> exportToCsv(String type) async {
    List<List<dynamic>> rows = [];
    String filename = '';

    if (type == 'STOK') {
      filename = 'Laporan_Stok_${_timestamp()}.csv';
      rows.add([
        'Nama',
        'SKU',
        'Kategori',
        'Jumlah',
        'Min Stok',
        'Harga Beli',
        'Harga Jual',
      ]);
      for (var item in _db.stokBox.getAll()) {
        rows.add([
          item.nama,
          item.sku ?? '-',
          item.kategori,
          item.jumlah,
          item.minStok,
          item.hargaBeli,
          item.hargaJual,
        ]);
      }
    } else if (type == 'TRANS') {
      filename = 'Laporan_Transaksi_${_timestamp()}.csv';
      rows.add([
        'No Trx',
        'Tanggal',
        'Pelanggan',
        'Kendaraan',
        'Plat',
        'Status',
        'Total',
        'Metode Bayar',
      ]);
      for (var trx in _db.transactionBox.getAll()) {
        rows.add([
          trx.trxNumber,
          DateFormat('yyyy-MM-dd HH:mm').format(trx.createdAt),
          trx.customerName,
          trx.vehicleModel,
          trx.vehiclePlate,
          trx.status,
          trx.totalAmount,
          trx.paymentMethod ?? '-',
        ]);
      }
    } else if (type == 'PELANGGAN') {
      filename = 'Daftar_Pelanggan_${_timestamp()}.csv';
      rows.add(['Nama', 'Telepon', 'Alamat']);
      for (var p in _db.pelangganBox.getAll()) {
        rows.add([p.nama, p.telepon, p.alamat]);
      }
    }

    if (rows.isEmpty) return;

    String csvData = csv.encode(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(csvData);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'ServisLog+ CSV Export ($type)');
  }

  String _timestamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  // --- Mappers ---

  Map<String, dynamic> _stokToMap(Stok item) => {
    'uuid': item.uuid,
    'nama': item.nama,
    'sku': item.sku,
    'hargaBeli': item.hargaBeli,
    'hargaJual': item.hargaJual,
    'jumlah': item.jumlah,
    'minStok': item.minStok,
    'kategori': item.kategori,
    'createdAt': item.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _pelangganToMap(Pelanggan p) => {
    'uuid': p.uuid,
    'nama': p.nama,
    'telepon': p.telepon,
    'alamat': p.alamat,
    'catatan': p.catatan,
    'createdAt': p.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _transactionToMap(Transaction t) => {
    'uuid': t.uuid,
    'trxNumber': t.trxNumber,
    'customerName': t.customerName,
    'customerPhone': t.customerPhone,
    'vehicleModel': t.vehicleModel,
    'vehiclePlate': t.vehiclePlate,
    'totalAmount': t.totalAmount,
    'partsCost': t.partsCost,
    'laborCost': t.laborCost,
    'status': t.status,
    'statusValue': t.statusValue,
    'paymentMethod': t.paymentMethod,
    'notes': t.notes,
    'complaint': t.complaint,
    'mechanicNotes': t.mechanicNotes,
    'createdAt': t.createdAt.toIso8601String(),
    'items': t.items
        .map(
          (i) => {
            'name': i.name,
            'quantity': i.quantity,
            'price': i.price,
            'subtotal': i.subtotal,
            'isService': i.isService,
            'stokUuid': i.stok.target?.uuid,
          },
        )
        .toList(),
  };

  Map<String, dynamic> _saleToMap(Sale s) => {
    'uuid': s.uuid,
    'totalPrice': s.totalPrice,
    'paymentMethod': s.paymentMethod,
    'customerName': s.customerName,
    'createdAt': s.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _staffToMap(Staff s) => {
    'uuid': s.uuid,
    'name': s.name,
    'role': s.role,
    'phoneNumber': s.phoneNumber,
  };

  Map<String, dynamic> _serviceMasterToMap(ServiceMaster s) => {
    'uuid': s.uuid,
    'name': s.name,
    'basePrice': s.basePrice,
    'category': s.category,
  };

  Map<String, dynamic> _vehicleToMap(Vehicle v) => {
    'uuid': v.uuid,
    'model': v.model,
    'plate': v.plate,
    'ownerName': v.owner.target?.nama ?? '',
    'ownerPhone': v.owner.target?.telepon ?? '',
  };
}
