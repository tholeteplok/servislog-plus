import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'device_session_service.dart';

// 🎯 Policy Constants
class SessionPolicy {
  // Grace Periods (Three Zones)
  static const Duration ownerGracePeriod = Duration(hours: 24);
  static const Duration staffGracePeriod = Duration(hours: 9);
  
  // Warning Thresholds
  static const Duration ownerWarningThreshold = Duration(hours: 12);
  static const Duration staffWarningThreshold = Duration(hours: 8);
  
  // Handshake Configuration
  static const Duration handshakeCacheTtl = Duration(minutes: 15);
  static const int handshakeMaxRetry = 3;
  static const Duration handshakeTimeout = Duration(seconds: 5);
  
  // Master Password
  static const String masterPasswordKey = 'master_password_hash';
}

// 📊 Session Status Enum
enum SessionStatus {
  full,       // Zone 1: Full access (Online / < warningThreshold)
  warning,    // Zone 2: Restricted access (< gracePeriod)
  blocked,    // Zone 3: No access (> gracePeriod)
  valid,      // Alias for full
  invalid,    // Alias for blocked
}

extension SessionStatusX on SessionStatus {
  int get zone {
    switch (this) {
      case SessionStatus.valid:
      case SessionStatus.full:
        return 1;
      case SessionStatus.warning:
        return 2;
      case SessionStatus.blocked:
      case SessionStatus.invalid:
        return 3;
    }
  }

  String get zoneLabel {
    switch (zone) {
      case 1:
        return 'Terlindungi';
      case 2:
        return 'Terbatas';
      case 3:
      default:
        return 'Terkunci';
    }
  }
}

// 🔐 Access Level Enum
enum AccessLevel {
  full,               // Create, Read, Update, Delete*
  readOnly,           // Read only (all)
  readOnlyFinancial,  // Read only (non-financial)
  blocked,            // No access
}

// 🎯 Critical Action Types
enum CriticalActionType {
  deleteTransaction,
  editPaidFee,
  exportData,
  viewFinancials,
  manageStaff,
  changeSettings,
}

// 🛠️ Session Manager Class
class SessionManager {
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────
  // CONFIGURATION
  // ─────────────────────────────────────────────────────────────
  
  // TODO: Pastikan Region dan Project ID sesuai dengan deployment Anda
  static const String _handshakeUrl = 'https://us-central1-servislog-plus.cloudfunctions.net/verifySession';
  
  // ─────────────────────────────────────────────────────────────
  // MASTER PASSWORD (OWNER ONLY)
  // ─────────────────────────────────────────────────────────────
  
  /// Hash and save Master Password with a random salt (during registration)
  Future<void> setupMasterPassword(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final saltBytes = utf8.encode(salt);
    final pinBytes = utf8.encode(pin);
    
    // Hash: SHA-256(salt + pin)
    final hash = sha256.convert([...saltBytes, ...pinBytes]).toString();
    
    // Store as salt:hash
    await _secureStorage.write(
      key: SessionPolicy.masterPasswordKey, 
      value: '$salt:$hash',
    );
    debugPrint('🔐 Master Password setup complete (Salted & Hashed)');
  }
  
  /// Verify Master Password using constant-time comparison to prevent timing attacks.
  Future<bool> verifyMasterPassword(String pin) async {
    final savedValue = await _secureStorage.read(key: SessionPolicy.masterPasswordKey);
    if (savedValue == null) return false;

    // Handle legacy (unsalted) or new (salted) format
    if (!savedValue.contains(':')) {
      final inputHash = sha256.convert(utf8.encode(pin)).toString();
      return _safeEquals(savedValue, inputHash);
    }

    final parts = savedValue.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final savedHash = parts[1];
    
    final saltBytes = utf8.encode(salt);
    final pinBytes = utf8.encode(pin);
    final inputHash = sha256.convert([...saltBytes, ...pinBytes]).toString();

    return _safeEquals(savedHash, inputHash);
  }

  /// Constant-time comparison
  bool _safeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
  
  // ─────────────────────────────────────────────────────────────
  // SESSION MANAGEMENT
  // ─────────────────────────────────────────────────────────────
  
  /// Save session after successful login
  Future<void> saveSession({
    required String token,
    required String userId,
    required String role,
    required String bengkelId,
  }) async {
    try {
      final expiry = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();

      // SEC-04 FIX: Tidak lagi menyimpan 'auth_token' di SecureStorage.
      // Firebase Auth SDK sudah mengelola token-nya sendiri secara aman.
      // Menyimpan duplikat hanya menambah attack surface tanpa manfaat.
      // Gunakan FirebaseAuth.instance.currentUser.getIdToken() jika token diperlukan.
      await _secureStorage.write(key: 'user_id', value: userId);
      await _secureStorage.write(key: 'user_role', value: role);
      await _secureStorage.write(key: 'bengkel_id', value: bengkelId);
      await _secureStorage.write(key: 'last_auth_timestamp', value: now.millisecondsSinceEpoch.toString());
      await _secureStorage.write(key: 'token_expiry', value: expiry.millisecondsSinceEpoch.toString());
      await _secureStorage.write(key: 'session_version', value: '2.0');
      
      debugPrint('✅ Session saved for user: $userId (role: $role)');
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
      rethrow;
    }
  }
  
  /// Clear session (logout)
  Future<void> clearSession() async {
    await _secureStorage.deleteAll();
    await _auth.signOut();
    debugPrint('🚪 Session cleared & Signed out');
  }
  
  // ─────────────────────────────────────────────────────────────
  // SESSION VALIDATION (MAIN ENTRY POINT)
  // ─────────────────────────────────────────────────────────────
  
  /// Validate session (online → handshake, offline → local validation)
  Future<SessionStatus> validateSession() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isConnected = connectivity != ConnectivityResult.none;
      
      if (isConnected) {
        return await _handshakeOnline();
      } else {
        return await _validateOffline();
      }
    } catch (e) {
      debugPrint('❌ Session validation error: $e');
      return SessionStatus.blocked;
    }
  }
  
  /// Online: Handshake with Firebase Cloud Functions + Audit Sync
  /// ✅ ENHANCED: Now sends device fingerprint data for server-side validation.
  Future<SessionStatus> _handshakeOnline() async {
    // Check cache first (15 minutes TTL)
    final cached = await _secureStorage.read(key: 'handshake_cache');
    if (cached != null) {
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(int.parse(cached));
      if (DateTime.now().difference(cachedTime) < SessionPolicy.handshakeCacheTtl) {
        return SessionStatus.valid;
      }
    }

    // LGK-04 FIX: Cek apakah masih dalam periode rate-limit cooldown.
    // Jika ya, skip handshake dan langsung validasi offline tanpa retry.
    final rateLimitStr = await _secureStorage.read(key: 'rate_limit_until');
    if (rateLimitStr != null) {
      final rateLimitUntil = DateTime.fromMillisecondsSinceEpoch(int.parse(rateLimitStr));
      if (DateTime.now().isBefore(rateLimitUntil)) {
        debugPrint('⏳ Handshake skipped — rate limit cooldown aktif hingga $rateLimitUntil');
        return await _validateOffline();
      } else {
        // Cooldown sudah lewat, hapus flag
        await _secureStorage.delete(key: 'rate_limit_until');
      }
    }

    // ── PHASE 1.3: Build Device Fingerprint Payload ────────────
    final deviceService = DeviceSessionService();
    final deviceId = await deviceService.getOrCreateDeviceId();
    String platform = 'unknown';
    try {
      if (Platform.isAndroid) platform = 'android';
      if (Platform.isIOS) platform = 'ios';
    } catch (_) {}

    String appVersion = 'unknown';
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        appVersion = info.version.sdkInt.toString();
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        appVersion = info.systemVersion;
      }
    } catch (_) {}

    final requestBody = jsonEncode({
      'deviceId': deviceId,
      'platform': platform,
      'appVersion': appVersion,
    });

    int retry = 0;
    while (retry < SessionPolicy.handshakeMaxRetry) {
      try {
        final user = _auth.currentUser;
        if (user == null) return SessionStatus.invalid;

        final token = await user.getIdToken(true);
        if (token == null) return SessionStatus.invalid;

        final response = await http.post(
          Uri.parse(_handshakeUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: requestBody,
        ).timeout(SessionPolicy.handshakeTimeout);

        if (response.statusCode == 200) {
          final now = DateTime.now();
          await _secureStorage.write(key: 'handshake_cache', value: now.millisecondsSinceEpoch.toString());
          await _secureStorage.write(key: 'last_auth_timestamp', value: now.millisecondsSinceEpoch.toString());
          await _syncEmergencyLogs();
          return SessionStatus.valid;

        } else if (response.statusCode == 401) {
          debugPrint('🔐 Handshake rejected (401): ${response.body}');
          return SessionStatus.invalid;

        } else if (response.statusCode == 429) {
          // LGK-04 FIX: Simpan timestamp cooldown dengan exponential backoff.
          // Backoff: 5 menit * 2^retry (5m, 10m, 20m, ...) maks 2 jam.
          final backoffMinutes = (5 * (1 << retry)).clamp(5, 120);
          final cooldownUntil = DateTime.now().add(Duration(minutes: backoffMinutes));
          await _secureStorage.write(
            key: 'rate_limit_until',
            value: cooldownUntil.millisecondsSinceEpoch.toString(),
          );
          debugPrint('⚠️ Handshake rate limited (429). Cooldown $backoffMinutes menit hingga $cooldownUntil.');
          return await _validateOffline();
        }
      } catch (e) {
        debugPrint('⚠️ Handshake attempt ${retry + 1} failed: $e');
        retry++;
        if (retry < SessionPolicy.handshakeMaxRetry) {
          // LGK-04 FIX: Exponential backoff antar retry (2s, 4s, 8s)
          final waitSeconds = 2 * (1 << (retry - 1));
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }
      }
      break;
    }

    return await _validateOffline();
  }
  
  /// Offline Validation based on last_auth_timestamp
  Future<SessionStatus> _validateOffline() async {
    final lastAuthStr = await _secureStorage.read(key: 'last_auth_timestamp');
    final tokenExpiryStr = await _secureStorage.read(key: 'token_expiry');
    final role = await _secureStorage.read(key: 'user_role');
    
    if (lastAuthStr == null || tokenExpiryStr == null || role == null) {
      return SessionStatus.blocked;
    }
    
    final lastAuth = DateTime.fromMillisecondsSinceEpoch(int.parse(lastAuthStr));
    final tokenExpiry = DateTime.fromMillisecondsSinceEpoch(int.parse(tokenExpiryStr));
    final now = DateTime.now();
    final offlineDuration = now.difference(lastAuth);
    
    // JWT expiry = HARD LIMIT
    if (now.isAfter(tokenExpiry)) {
      return SessionStatus.blocked;
    }
    
    final gracePeriod = role == 'owner' ? SessionPolicy.ownerGracePeriod : SessionPolicy.staffGracePeriod;
    final warningThreshold = role == 'owner' ? SessionPolicy.ownerWarningThreshold : SessionPolicy.staffWarningThreshold;
    
    if (offlineDuration < warningThreshold) {
      return SessionStatus.full;
    } else if (offlineDuration < gracePeriod) {
      return SessionStatus.warning;
    } else {
      return SessionStatus.blocked;
    }
  }
  
  // ─────────────────────────────────────────────────────────────
  // AUDIT LOGS & SYNC
  // ─────────────────────────────────────────────────────────────
  
  /// Sync local emergency logs to Firestore
  Future<void> _syncEmergencyLogs() async {
    try {
      final logsStr = await _secureStorage.read(key: 'emergency_logs');
      if (logsStr == null) return;
      
      final List<dynamic> logs = jsonDecode(logsStr);
      if (logs.isEmpty) return;
      
      final bengkelId = await _secureStorage.read(key: 'bengkel_id');
      if (bengkelId == null) return;
      
      debugPrint('🚀 Syncing ${logs.length} emergency logs to Firestore...');
      
      final batch = _firestore.batch();
      for (var log in logs) {
        final docRef = _firestore
            .collection('bengkel')
            .doc(bengkelId)
            .collection('security_audit_logs')
            .doc();
        batch.set(docRef, {
          ...Map<String, dynamic>.from(log),
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      await _secureStorage.delete(key: 'emergency_logs');
      debugPrint('✅ Audit logs synced and cleared');
    } catch (e) {
      debugPrint('❌ Failed to sync emergency logs: $e');
    }
  }
  
  /// Record critical security action locally
  Future<void> recordSecurityEvent(String action, {Map<String, dynamic>? extra}) async {
    try {
      final now = DateTime.now().toIso8601String();
      final userId = await _secureStorage.read(key: 'user_id');
      final bengkelId = await _secureStorage.read(key: 'bengkel_id');
      
      final event = {
        'timestamp': now,
        'action': action,
        'userId': userId,
        'bengkelId': bengkelId,
        'offline': true,
        if (extra != null) ...extra,
      };
      
      final logsStr = await _secureStorage.read(key: 'emergency_logs');
      final List<dynamic> logs = logsStr != null ? jsonDecode(logsStr) : [];
      logs.add(event);

      // SEC-02 FIX: Rolling log — batasi maks 100 entry agar tidak mengisi
      // SecureStorage (limit ~64KB di beberapa implementasi Keychain iOS).
      // Hapus entry paling lama jika melebihi batas.
      const int maxLogEntries = 100;
      final trimmedLogs = logs.length > maxLogEntries
          ? logs.sublist(logs.length - maxLogEntries)
          : logs;
      
      await _secureStorage.write(key: 'emergency_logs', value: jsonEncode(trimmedLogs));
    } catch (e) {
      debugPrint('❌ Error recording security event: $e');
    }
  }
  
  // ─────────────────────────────────────────────────────────────
  // EMERGENCY OVERRIDE (Owner Only)
  // ─────────────────────────────────────────────────────────────
  
  Future<bool> activateEmergencyOverride() async {
    try {
      // SEC-03 FIX: Jangan andalkan role dari SecureStorage saja — nilai ini
      // bisa dimanipulasi pada device yang di-root/jailbreak. Verifikasi
      // langsung dari Firebase token (trusted source) sebelum override aktif.
      final user = _auth.currentUser;
      if (user == null) return false;

      final tokenResult = await user.getIdTokenResult(true); // force refresh
      final claimsRole = tokenResult.claims?['role'] as String?;

      if (claimsRole != 'owner') {
        debugPrint('🚫 Emergency override ditolak — role dari Firebase: $claimsRole');
        return false;
      }

      await _secureStorage.write(
        key: 'last_auth_timestamp',
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      
      await recordSecurityEvent('emergency_override_activated', extra: {
        'verified_via': 'firebase_token',
        'claimed_role': claimsRole,
      });
      return true;
    } catch (e) {
      debugPrint('❌ Emergency override failed: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ACCESS CONTROL
  // ─────────────────────────────────────────────────────────────
  
  Future<AccessLevel> getAccessLevel() async {
    final status = await validateSession();
    final role = await _secureStorage.read(key: 'user_role');
    
    switch (status) {
      case SessionStatus.valid:
      case SessionStatus.full:
        return AccessLevel.full;
      case SessionStatus.warning:
        return role == 'owner' ? AccessLevel.readOnlyFinancial : AccessLevel.readOnly;
      case SessionStatus.blocked:
      case SessionStatus.invalid:
        return AccessLevel.blocked;
    }
  }
  
  Future<bool> canPerformAction(CriticalActionType action) async {
    final level = await getAccessLevel();
    if (level == AccessLevel.blocked) return false;
    if (level == AccessLevel.readOnly) return false;
    
    if (level == AccessLevel.readOnlyFinancial) {
      if (action == CriticalActionType.viewFinancials || action == CriticalActionType.exportData) {
        return false;
      }
    }
    return true;
  }
}

// 🔄 Riverpod Providers
final sessionManagerProvider = Provider<SessionManager>((ref) => SessionManager());

/// 🔑 Access Level Provider — sumber kebenaran: Firebase Auth token
/// Logic:
///   1. Jika Firebase Auth tidak ada session → blocked
///   2. Jika Firebase Auth token valid (belum expired) → full
///   3. Jika token expired tapi dalam grace period → warning/readOnly
///   4. Jika melewati grace period → blocked
///
/// Handshake Cloud Function adalah opsional dan tidak memblokir akses.
final accessLevelProvider = StreamProvider<AccessLevel>((ref) async* {
  // 🛡️ SECURITY GUARD: Block all access during Nuclear Sequence (Wipe)
  final isWiping = ref.watch(isWipingProvider);
  if (isWiping) {
    yield AccessLevel.blocked;
    return;
  }

  // Reaktif terhadap perubahan auth state Firebase
  yield* FirebaseAuth.instance.idTokenChanges().asyncMap((user) async {
    if (user == null) {
      return AccessLevel.blocked;
    }

    try {
      // Storage instance (dibuat sekali)
      final storage = FlutterSecureStorage(
        aOptions: const AndroidOptions(),
        iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
      );

      // Ambil token result untuk cek expiry
      final tokenResult = await user.getIdTokenResult();
      final expiry = tokenResult.expirationTime;
      final now = DateTime.now();

      // Token Firebase masih valid → Full Access
      if (expiry != null && now.isBefore(expiry)) {
        // Simpan timestamp otomatis setiap kali token valid
        await storage.write(
          key: 'last_auth_timestamp',
          value: now.millisecondsSinceEpoch.toString(),
        );
        return AccessLevel.full;
      }

      // Token expired → cek grace period dari storage
      final lastAuthStr = await storage.read(key: 'last_auth_timestamp');
      final roleStr = await storage.read(key: 'user_role');

      if (lastAuthStr == null) {
        // Tidak ada histori → anggap readOnly dulu (bukan blocked)
        return AccessLevel.readOnly;
      }

      final lastAuth = DateTime.fromMillisecondsSinceEpoch(int.parse(lastAuthStr));
      final offlineDuration = now.difference(lastAuth);
      final isOwner = roleStr == 'owner';

      final gracePeriod = isOwner ? SessionPolicy.ownerGracePeriod : SessionPolicy.staffGracePeriod;
      final warningThreshold = isOwner ? SessionPolicy.ownerWarningThreshold : SessionPolicy.staffWarningThreshold;

      if (offlineDuration < warningThreshold) {
        return AccessLevel.full;
      } else if (offlineDuration < gracePeriod) {
        return isOwner ? AccessLevel.readOnlyFinancial : AccessLevel.readOnly;
      } else {
        return AccessLevel.blocked;
      }
    } catch (e) {
      debugPrint('❌ accessLevelProvider security error: $e');
      // 🛡️ FAIL-CLOSED: Block all access on security check errors
      return AccessLevel.blocked;
    }
  });
});

final sessionStatusProvider = FutureProvider<SessionStatus>((ref) async {
  return await ref.watch(sessionManagerProvider).validateSession();
});

/// Stream status sesi untuk UI reaktif (Pusat Keamanan)
final sessionStatusStreamProvider = StreamProvider<SessionStatus>((ref) async* {
  // Emit initial status
  final manager = ref.read(sessionManagerProvider);
  yield await manager.validateSession();

  // Reaktif terhadap perubahan auth
  yield* FirebaseAuth.instance.authStateChanges().asyncMap((_) async {
    return await manager.validateSession();
  });
});
