import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servislog_core/features/home/create_transaction_screen.dart';
import 'package:servislog_core/core/providers/transaction_providers.dart';
import 'package:servislog_core/core/providers/pelanggan_provider.dart';
import 'package:servislog_core/core/providers/stok_provider.dart';
import 'package:servislog_core/core/providers/master_providers.dart';
import 'package:servislog_core/core/providers/objectbox_provider.dart';
import 'package:servislog_core/core/providers/sync_provider.dart';
import 'package:servislog_core/core/providers/auth_provider.dart';
import 'package:servislog_core/core/providers/navigation_provider.dart';
import 'package:servislog_core/core/providers/stats_provider.dart';
import 'package:servislog_core/core/services/session_manager.dart';
import '../../mocks/manual_mocks.dart';

void main() {
  late FakeSyncWorker fakeSyncWorker;
  late FakeObjectBoxProvider fakeDb;

  setUp(() {
    fakeSyncWorker = FakeSyncWorker();
    fakeDb = FakeObjectBoxProvider();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        dbProvider.overrideWith((ref) => fakeDb),
        syncWorkerProvider.overrideWith((ref) => fakeSyncWorker),
        // Mock auth state to bypass guards if any
        currentAccessLevelProvider.overrideWithValue(AccessLevel.full),
        // Initialize lists to empty
        pelangganListProvider.overrideWith((ref) => []),
        stokListProvider.overrideWith((ref) => []),
        staffListProvider.overrideWith((ref) => const AsyncData([])),
        vehicleListProvider.overrideWith((ref) => const AsyncData([])),
        transactionListProvider.overrideWith((ref) => const AsyncData([])),
      ],
      child: const MaterialApp(
        home: CreateTransactionScreen(),
      ),
    );
  }

  group('CreateTransactionScreen Widget Tests', () {
    testWidgets('Should render Step 1: Unit Info', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Informasi Unit'), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(2));
    });

    testWidgets('Should show error if Next is pressed without plate', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nextButton = find.text('Selanjutnya');
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Check for snackbar or validation error
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
