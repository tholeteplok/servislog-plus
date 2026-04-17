import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/encryption_service.dart';
import 'auth_provider.dart';
import 'pengaturan_provider.dart';

/// Provider to monitor app inactivity and background time.
/// Triggers auto-lock if enabled and 30 minutes have passed in background.
final inactivityMonitorProvider = Provider<InactivityMonitor>((ref) {
  final monitor = InactivityMonitor(ref);
  // Initialize monitoring
  WidgetsBinding.instance.addObserver(monitor);
  
  // Cleanup on dispose
  ref.onDispose(() => monitor.dispose());
  
  return monitor;
});

class InactivityMonitor extends WidgetsBindingObserver {
  final Ref _ref;
  DateTime? _backgroundTime;
  Timer? _timer;

  InactivityMonitor(this._ref);

  void start() {
    // This can be used to explicitly start if needed
    debugPrint('🛡️ InactivityMonitor started');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = _ref.read(settingsProvider);
    if (settings.autoLockDuration <= 0) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundTime = DateTime.now();
      debugPrint('🕒 App went to background at $_backgroundTime');
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final diff = DateTime.now().difference(_backgroundTime!);
        debugPrint('🕒 App resumed. Background duration: ${diff.inMinutes}m');

        if (diff.inMinutes >= settings.autoLockDuration) {
          _lockApp(settings.autoLockDuration);
        }
        _backgroundTime = null;
      }
    }
  }

  void _lockApp(int duration) {
    debugPrint('☢️ Auto-lock triggered (${duration}m inactivity)');
    // Clearing the in-memory encrypter will force AuthGate to show UnlockScreen
    EncryptionService().lock();
    
    // We need to trigger a rebuild of the AuthGate. 
    // Invalidating authStateProvider is a clean way to force a re-check.
    _ref.invalidate(authStateProvider);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }
}
