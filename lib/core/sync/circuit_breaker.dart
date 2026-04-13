import 'package:flutter/foundation.dart';

/// 🛡️ HierarchicalCircuitBreaker — Global + per-item error isolation.
/// Prevents repetitive failures from overloading the system or causing lag.
enum SyncDecision { proceed, block, skip }

enum DriveErrorType {
  quotaExceeded,
  rateLimit,
  auth,
  permission,
  notFound,
  server,
  network,
  unknown,
}

class HierarchicalCircuitBreaker {
  // Level 1: Global (untuk quota/auth errors)
  static final _global = _CircuitBreaker(
    name: 'global',
    failureThreshold: 3,
    resetTimeout: const Duration(minutes: 15),
  );

  // Level 2: Per-item tracking
  final Map<String, _CircuitBreaker> _itemBreakers = {};

  /// Evaluate if item should proceed based on its error type and current state.
  SyncDecision shouldProceed(String itemId, DriveErrorType error) {
    // Global always checked first
    if (_global.isOpen) {
      debugPrint('🔴 Global circuit open: ${_global.state}');
      return SyncDecision.block;
    }

    // Per-item breaker for non-global errors
    if (_isItemLevelError(error)) {
      final breaker = _itemBreakers.putIfAbsent(
        itemId,
        () => _CircuitBreaker(name: 'item_$itemId', failureThreshold: 2),
      );

      if (breaker.isOpen) {
        debugPrint('🟡 Item-level breaker open for $itemId: ${breaker.state}');
        return SyncDecision.skip;
      }
    }

    return SyncDecision.proceed;
  }

  void recordSuccess(String itemId) {
    _itemBreakers[itemId]?.recordSuccess();
  }

  void recordFailure(String itemId, DriveErrorType error) {
    if (_isGlobalError(error)) {
      _global.recordFailure();
      debugPrint('🔴 Global circuit failure recorded: ${error.name}');
    } else {
      _itemBreakers.putIfAbsent(
        itemId,
        () => _CircuitBreaker(name: 'item_$itemId', failureThreshold: 2),
      ).recordFailure();
      debugPrint('🟡 Item-level failure recorded: $itemId - ${error.name}');
    }
  }

  bool _isGlobalError(DriveErrorType error) =>
    error == DriveErrorType.quotaExceeded ||
    error == DriveErrorType.rateLimit ||
    error == DriveErrorType.auth;

  bool _isItemLevelError(DriveErrorType error) =>
    error == DriveErrorType.notFound ||
    error == DriveErrorType.permission ||
    error == DriveErrorType.server ||
    error == DriveErrorType.network;

  /// Reset all breakers (for manual recovery or status change).
  void resetAll() {
    _global.reset();
    _itemBreakers.clear();
    debugPrint('🔄 All circuit breakers reset');
  }

  /// Get status for debugging purposes.
  Map<String, dynamic> get status => {
    'global': _global.state,
    'itemBreakerCount': _itemBreakers.length,
  };
}

class _CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;

  _CircuitBreaker({
    required this.name,
    required this.failureThreshold,
    this.resetTimeout = const Duration(minutes: 5),
  });

  bool get isOpen {
    if (_failureCount >= failureThreshold) {
      if (_lastFailureTime != null) {
        final elapsed = DateTime.now().difference(_lastFailureTime!);
        if (elapsed > resetTimeout) {
          reset();
          return false;
        }
      }
      return true;
    }
    return false;
  }

  String get state => isOpen ? 'OPEN' : 'CLOSED';

  void recordSuccess() {
    _failureCount = 0;
    _lastFailureTime = null;
  }

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
  }

  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    debugPrint('🔄 Circuit breaker $name reset');
  }
}
