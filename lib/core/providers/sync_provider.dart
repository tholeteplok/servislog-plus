import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_worker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'objectbox_provider.dart';
import 'system_providers.dart';
import 'pengaturan_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 📡 Sync State Models
// ─────────────────────────────────────────────────────────────────────────────

class SyncStatusState {
  final SyncWorkerState state;
  final DateTime? lastSyncedAt;

  SyncStatusState({required this.state, this.lastSyncedAt});

  SyncStatusState copyWith({
    SyncWorkerState? state,
    DateTime? lastSyncedAt,
  }) {
    return SyncStatusState(
      state: state ?? this.state,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🕹️ Sync Notifiers
// ─────────────────────────────────────────────────────────────────────────────

class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  SyncStatusNotifier() : super(SyncStatusState(state: SyncWorkerState.idle));

  void setState(SyncWorkerState newState) {
    state = state.copyWith(
      state: newState,
      lastSyncedAt: newState == SyncWorkerState.success ? DateTime.now() : state.lastSyncedAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 📡 Standard Providers
// ─────────────────────────────────────────────────────────────────────────────

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
  return SyncStatusNotifier();
});

final syncWorkerProvider = Provider<SyncWorker?>((ref) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null || profile.bengkelId.isEmpty) return null;

  final db = ref.watch(dbProvider);
  final syncService = ref.watch(firestoreSyncServiceProvider);
  final deviceService = ref.watch(deviceSessionServiceProvider);
  final sessionManager = ref.watch(sessionManagerProvider);

  // Read settings once; the worker will be recreated if profile changes
  final settings = ref.read(settingsProvider);

  final worker = SyncWorker(
    db: db,
    syncService: syncService,
    deviceService: deviceService,
    sessionManager: sessionManager,
    bengkelId: profile.bengkelId,
    userId: FirebaseAuth.instance.currentUser?.uid,
    syncWifiOnly: settings.syncWifiOnly,
    onStateChanged: (state) {
      if (ref.exists(syncStatusProvider)) {
        ref.read(syncStatusProvider.notifier).setState(state);
      }
    },
  );

  worker.start();

  ref.onDispose(() {
    worker.dispose();
  });

  return worker;
});
