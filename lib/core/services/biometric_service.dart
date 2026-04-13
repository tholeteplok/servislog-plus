// 🛡️ ServisLog+ Hybrid Security Policy — Biometric Service Wrapper
// Future-proof abstraction layer untuk biometric authentication
// Support: 3x retry, PIN fallback, emergency mode

import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 📊 Biometric Verification Result
class BiometricResult {
  final bool success;
  final int retryCount;
  final String? error;
  
  BiometricResult({
    required this.success,
    required this.retryCount,
    this.error,
  });
  
  bool get hasRetries => retryCount < 3;
}

// 🛠️ Biometric Service Class
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  static const _pinKey = 'biometric_pin';
  
  // ─────────────────────────────────────────────────────────────
  // AVAILABILITY CHECK
  // ─────────────────────────────────────────────────────────────
  
  /// Check if biometric is available on device
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('❌ Biometric availability check failed: $e');
      return false;
    }
  }
  
  /// Check if device has biometric hardware
  Future<bool> canCheckBiometricHardware() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }
  
  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
  
  /// Check if biometric is enrolled
  Future<bool> isBiometricEnrolled() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }
  
  // ─────────────────────────────────────────────────────────────
  // VERIFICATION (MAIN METHODS)
  // ─────────────────────────────────────────────────────────────
  
  /// Simple verify (for critical actions)
  Future<bool> verify({
    required String reason,
    bool biometricOnly = true,
  }) async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        debugPrint('⚠️ Biometric not available');
        return false;
      }
      
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('❌ Biometric verification error: $e');
      return false;
    }
  }
  
  /// Verify with retry (for emergency mode) — 3x retry
  Future<BiometricResult> verifyWithRetry({
    required String reason,
    int maxRetry = 3,
  }) async {
    int retry = 0;
    String? lastError;
    
    while (retry < maxRetry) {
      try {
        final canCheck = await canCheckBiometrics();
        if (!canCheck) {
          return BiometricResult(
            success: false,
            retryCount: retry,
            error: 'Biometric not available',
          );
        }
        
        final verified = await _localAuth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        
        if (verified) {
          debugPrint('✅ Biometric verified (retry: $retry)');
          return BiometricResult(
            success: true,
            retryCount: retry,
          );
        }
        
        lastError = 'Verification failed';
      } catch (e) {
        lastError = e.toString();
        debugPrint('⚠️ Biometric attempt ${retry + 1} failed: $e');
      }
      
      retry++;
      
      // Delay between retries
      if (retry < maxRetry) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    
    debugPrint('❌ Biometric max retry reached ($maxRetry)');
    return BiometricResult(
      success: false,
      retryCount: retry,
      error: lastError,
    );
  }
  
  // ─────────────────────────────────────────────────────────────
  // PIN STORAGE
  // ─────────────────────────────────────────────────────────────
  
  /// Save PIN to secure storage (called after biometric enrollment)
  Future<void> savePin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
    debugPrint('🔐 Biometric PIN saved');
  }

  /// Clear stored PIN (called when disabling biometric)
  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinKey);
    debugPrint('🗑️ Biometric PIN cleared');
  }
  
  /// Verify PIN against the stored PIN
  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: _pinKey);
    return stored != null && stored == pin;
  }
  
  /// Check if PIN is set
  Future<bool> isPinSet() async {
    final stored = await _secureStorage.read(key: _pinKey);
    return stored != null;
  }

  // ─────────────────────────────────────────────────────────────
  // COMPATIBILITY ALIASES
  // (used by screens that predate the v2 API rename)
  // ─────────────────────────────────────────────────────────────

  /// Alias for [canCheckBiometrics] — checks hardware + enrolled status
  Future<bool> isAvailable() => canCheckBiometrics();

  /// Alias for [verify] with a default reason string
  Future<bool> authenticate({String reason = 'Verifikasi identitas Anda'}) =>
      verify(reason: reason);
  
  // ─────────────────────────────────────────────────────────────
  // EMERGENCY MODE HELPER
  // ─────────────────────────────────────────────────────────────
  
  /// Emergency verification: 3x biometric → return result for PIN fallback
  Future<BiometricResult> emergencyVerify() async {
    return await verifyWithRetry(
      reason: 'Verifikasi Emergency Override',
      maxRetry: 3,
    );
  }
}

// 🔄 Riverpod Providers
final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(biometricServiceProvider);
  return await service.canCheckBiometrics();
});

final biometricTypesProvider = FutureProvider<List<BiometricType>>((ref) async {
  final service = ref.read(biometricServiceProvider);
  return await service.getAvailableBiometrics();
});

