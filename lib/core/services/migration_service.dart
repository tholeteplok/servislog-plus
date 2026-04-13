import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'encryption_service.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryption = EncryptionService();

  /// Jalankan migrasi enkripsi untuk satu bengkel.
  /// Menarik semua data PII lama, mengenkripsinya, lalu mengunggahnya kembali.
  Future<void> migrateToEncryption(String bengkelId) async {
    try {
      debugPrint('Starting Migration for Bengkel: $bengkelId');

      // 1. Migrate Customers
      final customersSnapshot = await _firestore
          .collection('bengkel')
          .doc(bengkelId)
          .collection('customers')
          .get();

      for (var doc in customersSnapshot.docs) {
        final data = doc.data();
        // Cek apakah sudah terenkripsi menggunakan prefix baru
        final nameStr = data['name']?.toString() ?? '';
        if (nameStr.startsWith(EncryptionService.encryptionPrefix)) continue;

        await doc.reference.update({
          'name': _encryption.encryptText(data['name'] ?? ''),
          'phone': _encryption.encryptText(data['phone'] ?? ''),
          'address': _encryption.encryptText(data['address'] ?? ''),
          'isEncrypted': true,
          'migratedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Migrate Transactions
      final transactionsSnapshot = await _firestore
          .collection('bengkel')
          .doc(bengkelId)
          .collection('transactions')
          .get();

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final nameStr = data['customerName']?.toString() ?? '';
        if (nameStr.startsWith(EncryptionService.encryptionPrefix)) continue;

        await doc.reference.update({
          'customerName': _encryption.encryptText(data['customerName'] ?? ''),
          'customerPhone': _encryption.encryptText(data['customerPhone'] ?? ''),
          'complaint': _encryption.encryptText(data['complaint'] ?? ''),
          'mechanicNotes': _encryption.encryptText(data['mechanicNotes'] ?? ''),
          'notes': _encryption.encryptText(data['notes'] ?? ''),
          'isEncrypted': true,
          'migratedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Migrate Staff
      final staffSnapshot = await _firestore
          .collection('bengkel')
          .doc(bengkelId)
          .collection('staff')
          .get();

      for (var doc in staffSnapshot.docs) {
        final data = doc.data();
        final nameStr = data['name']?.toString() ?? '';
        if (nameStr.startsWith(EncryptionService.encryptionPrefix)) continue;

        await doc.reference.update({
          'name': _encryption.encryptText(data['name'] ?? ''),
          'phone': _encryption.encryptText(data['phone'] ?? ''),
          'isEncrypted': true,
          'migratedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('Migration Completed Successfully for $bengkelId');
    } catch (e) {
      debugPrint('Migration Error: $e');
      rethrow;
    }
  }
}
