import 'package:flutter/foundation.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service untuk encrypt/decrypt PII (Personally Identifiable Information)
/// seperti nama dan no HP pelanggan sebelum disimpan ke database lokal/cloud.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  encrypt.Encrypter? _encrypter;

  final String _keyAlias = 'servislog_master_key';
  static const String encryptionPrefix = 'enc:v1:';
  static const int pbkdf2Iterations = 100000;

  /// Inisialisasi: Generate key if not exists, and store to Secure Storage.
  bool get isInitialized => _encrypter != null;

  /// Check if the master key exists in secure storage
  Future<bool> isMasterKeySet() async {
    return await _storage.containsKey(key: _keyAlias);
  }

  Future<void> init() async {
    try {
      String? keyBase64 = await _storage.read(key: _keyAlias);

      if (keyBase64 != null) {
        final keyBytes = base64Decode(keyBase64);
        final key = encrypt.Key(keyBytes);

        // Gunakan GCM untuk integritas data
        _encrypter = encrypt.Encrypter(
          encrypt.AES(key, mode: encrypt.AESMode.gcm),
        );
        debugPrint('🛡️ EncryptionService initialized with existing key');
      } else {
        debugPrint('🛡️ EncryptionService NOT initialized (key missing)');
      }
    } catch (e) {
      debugPrint('EncryptionService Error: $e');
    }
  }

  /// Generate a brand new master key. 
  /// ONLY call this during brand new workshop creation.
  Future<void> generateNewMasterKey() async {
    final key = encrypt.Key.fromSecureRandom(32);
    final keyBase64 = base64Encode(key.bytes);
    await _storage.write(key: _keyAlias, value: keyBase64);
    
    // Re-init with the new key
    await init();
  }

  /// Derive a 256-bit key from a 6-digit PIN using PBKDF2-HMAC-SHA256.
  /// Standard: OWASP 2023 (100,000 iterations minimum).
  Future<encrypt.Key> deriveKey(String pin, String salt) async {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    final params = Pbkdf2Parameters(
      Uint8List.fromList(utf8.encode(salt)),
      pbkdf2Iterations,
      32,
    );
    pbkdf2.init(params);
    
    final keyBytes = pbkdf2.process(Uint8List.fromList(utf8.encode(pin)));
    return encrypt.Key(keyBytes);
  }

  /// Legacy derivation for migration purposes
  encrypt.Key _deriveKeyLegacy(String pin, String salt) {
    final codec = const Utf8Codec();
    final pinBytes = codec.encode(pin);
    final saltBytes = codec.encode(salt);
    var hash = sha256.convert([...pinBytes, ...saltBytes]);
    for (var i = 0; i < 10000; i++) {
      hash = sha256.convert(hash.bytes);
    }
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  /// Save derived key securely (for Biometric Auto-Unlock)
  Future<void> saveDerivedKeySecurely(String pin, String bengkelId) async {
    final key = await deriveKey(pin, bengkelId);
    await _storage.write(
      key: 'biometric_derived_key_$bengkelId',
      value: key.base64,
    );
  }

  /// Get saved derived key after Biometric success
  Future<encrypt.Key?> getSavedDerivedKey(String bengkelId) async {
    final keyBase64 = await _storage.read(key: 'biometric_derived_key_$bengkelId');
    if (keyBase64 == null) return null;
    return encrypt.Key.fromBase64(keyBase64);
  }

  /// Clear saved derived key (Disable Biometric)
  Future<void> clearSavedDerivedKey(String bengkelId) async {
    await _storage.delete(key: 'biometric_derived_key_$bengkelId');
  }

  /// Lock the service by clearing the in-memory encrypter.
  /// This forces the app to re-authenticate via AuthGate -> UnlockScreen.
  void lock() {
    _encrypter = null;
    debugPrint('🛡️ EncryptionService locked');
  }

  /// Clear all secure data (keys, biometrics, PINs) during logout
  Future<void> clearAllSecureData() async {
    await _storage.deleteAll();
    _encrypter = null;
  }


  /// Encrypt string text using AES-GCM with a secure random IV and prefix.
  String encryptText(String plainText) {
    if (_encrypter == null || plainText.isEmpty) return plainText;
    
    // Prevent double encryption
    if (plainText.startsWith(encryptionPrefix)) return plainText;

    // Use Secure Random IV (12 bytes is standard for GCM)
    final iv = encrypt.IV.fromSecureRandom(12);

    final encrypted = _encrypter!.encrypt(plainText, iv: iv);

    // Store as prefix:IV:Ciphertext
    return '$encryptionPrefix${iv.base64}:${encrypted.base64}';
  }
  /// Encrypt string text using a provided key. Useful for secure backups (Audit K-1).
  String encryptTextWithKey(String plainText, encrypt.Key key) {
    if (plainText.isEmpty) return plainText;
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '$encryptionPrefix${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt string text using a provided key. Useful for restoring backups (Audit K-1).
  String decryptTextWithKey(String encryptedText, encrypt.Key key) {
    if (encryptedText.isEmpty) return encryptedText;
    if (!encryptedText.startsWith(encryptionPrefix)) return encryptedText;
    
    try {
      final body = encryptedText.substring(encryptionPrefix.length);
      final parts = body.split(':');
      if (parts.length != 2) return encryptedText;

      final iv = encrypt.IV.fromBase64(parts[0]);
      final ciphertext = parts[1];
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      
      return encrypter.decrypt64(ciphertext, iv: iv);
    } catch (_) {
      return '[Gagal Dekripsi]';
    }
  }

  /// Decrypt string text with structured result handling.
  DecryptionResult decryptText(String encryptedText) {
    if (_encrypter == null) return DecryptionResult.failed(status: DecryptionStatus.notInitialized);
    if (encryptedText.isEmpty) return DecryptionResult.empty();

    // Check for our prefix
    bool hasPrefix = encryptedText.startsWith(encryptionPrefix);
    String workingText = hasPrefix 
        ? encryptedText.substring(encryptionPrefix.length) 
        : encryptedText;

    if (!workingText.contains(':')) {
      return DecryptionResult.unencrypted(workingText);
    }

    try {
      final parts = workingText.split(':');
      if (parts.length != 2) return DecryptionResult.failed(status: DecryptionStatus.invalidFormat);

      final iv = encrypt.IV.fromBase64(parts[0]);
      final ciphertext = parts[1];

      final decrypted = _encrypter!.decrypt64(ciphertext, iv: iv);
      return DecryptionResult.success(decrypted);
    } catch (e) {
      debugPrint('DecryptText Error: $e');
      return DecryptionResult.failed(status: DecryptionStatus.failed);
    }
  }

  /// Encrypt primary master key with a PIN using PBKDF2 and AES-GCM.
  Future<String?> wrapMasterKey(String pin, String bengkelId) async {
    final masterKeyBase64 = await _storage.read(key: _keyAlias);
    if (masterKeyBase64 == null) return null;

    final secondaryKey = await deriveKey(pin, bengkelId);
    // Use GCM for authenticated key wrapping
    final secondaryEncrypter = encrypt.Encrypter(
      encrypt.AES(secondaryKey, mode: encrypt.AESMode.gcm),
    );

    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypted = secondaryEncrypter.encrypt(masterKeyBase64, iv: iv);

    // Format: prefix:base64(IV):base64(Ciphertext)
    return '$encryptionPrefix${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt primary master key using a PIN.
  /// Handles migration from legacy key derivation if needed.
  ///
  /// [onMigrationComplete] — callback dipanggil dengan wrapped key baru
  /// setelah migrasi legacy → PBKDF2 berhasil. Caller bertanggung jawab
  /// untuk push key ini ke Firestore (LGK-06).
  Future<bool> unwrapAndSaveMasterKey(
    String wrappedKey,
    String pin,
    String bengkelId, {
    Future<void> Function(String newWrappedKey)? onMigrationComplete,
  }) async {
    try {
      // 1. Try with new PBKDF2 derivation
      final secondaryKey = await deriveKey(pin, bengkelId);
      final success = await _unwrapWithKey(wrappedKey, secondaryKey);
      
      if (success) return true;

      // 2. Fallback to legacy derivation for migration
      debugPrint('🛡️ PBKDF2 unwrap failed, trying legacy derivation...');
      final legacyKey = _deriveKeyLegacy(pin, bengkelId);
      final legacySuccess = await _unwrapWithKey(wrappedKey, legacyKey);

      if (legacySuccess) {
        debugPrint('🛡️ Legacy derivation successful. Migrating to PBKDF2...');
        // LGK-06 FIX: Re-wrap dengan PBKDF2 key baru dan push ke Firestore
        // agar device lain tidak terus menggunakan legacy key.
        try {
          final newWrappedKey = await wrapMasterKey(pin, bengkelId);
          if (newWrappedKey != null && onMigrationComplete != null) {
            await onMigrationComplete(newWrappedKey);
            debugPrint('✅ PBKDF2 migration complete — wrapped key baru sudah di-push ke Firestore.');
          }
        } catch (migrationError) {
          // Migrasi gagal tidak boleh menghalangi login — log saja.
          debugPrint('⚠️ PBKDF2 migration push gagal (akan dicoba lagi saat login berikutnya): $migrationError');
        }
        return true;
      }
      return legacySuccess;
    } catch (e) {
      debugPrint('UnwrapMasterKey Error: $e');
      return false;
    }
  }

  /// Decrypt primary master key using a saved derived key (Biometric)
  Future<bool> unwrapWithSavedKey(String wrappedKey, encrypt.Key key) async {
    return await _unwrapWithKey(wrappedKey, key);
  }

  Future<bool> _unwrapWithKey(
    String wrappedKey,
    encrypt.Key secondaryKey,
  ) async {
    try {
      // Handle optional prefix
      String body = wrappedKey.startsWith(encryptionPrefix)
          ? wrappedKey.substring(encryptionPrefix.length)
          : wrappedKey;

      final parts = body.split(':');
      if (parts.length != 2) return false;

      final iv = encrypt.IV.fromBase64(parts[0]);
      final ciphertext = parts[1];

      // Use GCM mode to match wrapping
      final secondaryEncrypter = encrypt.Encrypter(
        encrypt.AES(secondaryKey, mode: encrypt.AESMode.gcm),
      );

      final masterKeyBase64 = secondaryEncrypter.decrypt64(ciphertext, iv: iv);
      await _storage.write(key: _keyAlias, value: masterKeyBase64);

      // Re-init with new key
      await init();
      return true;
    } catch (e) {
      // Silently fail as this is used in fallback logic
      return false;
    }
  }
}

/// Structured result for decryption operations to prevent ciphertext leakage in UI.
enum DecryptionStatus { success, empty, unencrypted, wrongKey, corrupted, invalidFormat, failed, notInitialized }

class DecryptionResult {
  final String? data;
  final DecryptionStatus status;

  const DecryptionResult({this.data, required this.status});

  factory DecryptionResult.success(String data) => DecryptionResult(data: data, status: DecryptionStatus.success);
  factory DecryptionResult.empty() => const DecryptionResult(data: '', status: DecryptionStatus.empty);
  factory DecryptionResult.unencrypted(String data) => DecryptionResult(data: data, status: DecryptionStatus.unencrypted);
  factory DecryptionResult.failed({DecryptionStatus status = DecryptionStatus.failed}) => DecryptionResult(data: null, status: status);

  bool get isSuccess => status == DecryptionStatus.success || status == DecryptionStatus.empty || status == DecryptionStatus.unencrypted;
  bool get isFailure => !isSuccess;

  /// Returns a safe display string for the UI. NEVER returns ciphertext.
  String get displayValue {
    if (isSuccess) return data ?? '';
    switch (status) {
      case DecryptionStatus.wrongKey: return '[Data Terkunci - PIN Salah]';
      case DecryptionStatus.corrupted: return '[Data Corrupt]';
      case DecryptionStatus.notInitialized: return '[Menunggu Aktivasi...]';
      default: return '[Gagal Membaca Data]';
    }
  }
}
