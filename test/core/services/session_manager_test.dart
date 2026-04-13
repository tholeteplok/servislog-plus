// ─────────────────────────────────────────────────────────────
// Unit Tests: SessionManager & Core Logic
// Phase 3 — Testing
// ─────────────────────────────────────────────────────────────
//
// Menguji logika validasi sesi di SessionManager secara terisolasi
// tanpa kebutuhan Firebase/Firebase Emulator.
//
// Jalankan dengan: flutter test test/core/services/session_manager_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:servislog_core/core/services/session_manager.dart';
import 'package:servislog_core/core/utils/error_handler.dart';
import 'package:servislog_core/core/providers/transaction_providers.dart';

// ─────────────────────────────────────────────────────────────
// TESTS: SessionPolicy Constants
// ─────────────────────────────────────────────────────────────

void main() {
  group('SessionPolicy Constants', () {
    test('Owner grace period is 24 hours', () {
      expect(SessionPolicy.ownerGracePeriod, const Duration(hours: 24));
    });

    test('Staff grace period is 9 hours', () {
      expect(SessionPolicy.staffGracePeriod, const Duration(hours: 9));
    });

    test('Owner warning threshold is 12 hours', () {
      expect(SessionPolicy.ownerWarningThreshold, const Duration(hours: 12));
    });

    test('Staff warning threshold is 8 hours', () {
      expect(SessionPolicy.staffWarningThreshold, const Duration(hours: 8));
    });

    test('Handshake cache TTL is 15 minutes', () {
      expect(SessionPolicy.handshakeCacheTtl, const Duration(minutes: 15));
    });

    test('Handshake max retry is 3', () {
      expect(SessionPolicy.handshakeMaxRetry, 3);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // TESTS: SessionStatus Zone Mapping
  // ─────────────────────────────────────────────────────────────

  group('SessionStatus Zone', () {
    test('full → zone 1', () {
      expect(SessionStatus.full.zone, 1);
    });

    test('valid → zone 1 (alias)', () {
      expect(SessionStatus.valid.zone, 1);
    });

    test('warning → zone 2', () {
      expect(SessionStatus.warning.zone, 2);
    });

    test('blocked → zone 3', () {
      expect(SessionStatus.blocked.zone, 3);
    });

    test('invalid → zone 3 (alias)', () {
      expect(SessionStatus.invalid.zone, 3);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // TESTS: SessionStatus Zone Labels
  // ─────────────────────────────────────────────────────────────

  group('SessionStatus Zone Labels', () {
    test('zone 1 → Terlindungi', () {
      expect(SessionStatus.full.zoneLabel, 'Terlindungi');
    });

    test('zone 2 → Terbatas', () {
      expect(SessionStatus.warning.zoneLabel, 'Terbatas');
    });

    test('zone 3 → Terkunci', () {
      expect(SessionStatus.blocked.zoneLabel, 'Terkunci');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // TESTS: AccessLevel Logic
  // ─────────────────────────────────────────────────────────────

  group('AccessLevel', () {
    test('AccessLevel enum has correct values', () {
      expect(AccessLevel.values.length, 4);
      expect(AccessLevel.values, contains(AccessLevel.full));
      expect(AccessLevel.values, contains(AccessLevel.readOnly));
      expect(AccessLevel.values, contains(AccessLevel.readOnlyFinancial));
      expect(AccessLevel.values, contains(AccessLevel.blocked));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // TESTS: AppErrorHandler
  // ─────────────────────────────────────────────────────────────

  group('AppErrorHandler — from SocketException', () {
    test('SocketException → network category', () {
      AppError result;
      try {
        throw const SocketException('Connection refused');
      } catch (e) {
        result = AppErrorHandler.from(e);
      }
      expect(result.category, ErrorCategory.network);
      expect(result.title, 'Gagal Terhubung');
    });
  });

  group('AppErrorHandler — from generic Exception strings', () {
    test('ObjectBox-related error → storage category', () {
      final result = AppErrorHandler.from(Exception('objectbox database error'));
      expect(result.category, ErrorCategory.storage);
    });

    test('Sync-related error → sync category', () {
      final result = AppErrorHandler.from(Exception('sync failed firestore'));
      expect(result.category, ErrorCategory.sync);
    });

    test('Stok insufficient error → data category', () {
      final result = AppErrorHandler.from(
        Exception('Gagal: Stok "Oli" tidak mencukupi (2 tersedia).'),
      );
      expect(result.category, ErrorCategory.data);
    });

    test('Unknown error → unknown category with fallback title', () {
      final result = AppErrorHandler.from(Exception('some random unhandled error'));
      expect(result.category, ErrorCategory.unknown);
      expect(result.title, 'Terjadi Kesalahan');
    });

    test('AppError has non-null action for common errors', () {
      final result = AppErrorHandler.from(Exception('objectbox error'));
      expect(result.action, isNotNull);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // TESTS: PaginatedTransactionState
  // ─────────────────────────────────────────────────────────────

  group('PaginatedTransactionState', () {
    test('initial state has correct defaults', () {
      const state = PaginatedTransactionState();
      expect(state.items, isEmpty);
      expect(state.isLoadingMore, false);
      expect(state.hasMore, true);
      expect(state.currentPage, 0);
    });

    test('copyWith preserves existing values when not overridden', () {
      const state = PaginatedTransactionState(
        isLoadingMore: true,
        hasMore: false,
        currentPage: 3,
      );

      final updated = state.copyWith(isLoadingMore: false);

      expect(updated.isLoadingMore, false); // changed
      expect(updated.hasMore, false);       // preserved
      expect(updated.currentPage, 3);       // preserved
    });

    test('copyWith can update all fields independently', () {
      const state = PaginatedTransactionState();
      final updated = state.copyWith(
        isLoadingMore: true,
        hasMore: false,
        currentPage: 5,
      );
      expect(updated.isLoadingMore, true);
      expect(updated.hasMore, false);
      expect(updated.currentPage, 5);
    });
  });
}
