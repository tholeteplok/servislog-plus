import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/firestore_sync_service.dart';
import '../services/sync_worker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'objectbox_provider.dart';
import 'auth_provider.dart';
import 'pengaturan_provider.dart'; // FIX: import settings untuk syncWifiOnly
import '../services/device_session_service.dart';
import '../services/session_manager.dart';

part 'sync_provider.g.dart';

@Riverpod(keepAlive: true)
FirestoreSyncService firestoreSyncService(FirestoreSyncServiceRef ref) {
  return FirestoreSyncService();
}

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
      lastSyncedAt:
          lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

@riverpod
class SyncStatus extends _$SyncStatus {
  @override
  SyncStatusState build() => SyncStatusState(state: SyncWorkerState.idle);

  void setState(SyncWorkerState newState) {
    state = state.copyWith(
      state: newState,
      lastSyncedAt:
          newState == SyncWorkerState.success ? DateTime.now() : state.lastSyncedAt,
    );
  }
}

@Riverpod(keepAlive: true)
SyncWorker? syncWorker(SyncWorkerRef ref) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null || profile.bengkelId.isEmpty) return null;

  final db = ref.watch(dbProvider);
  final syncService = ref.watch(firestoreSyncServiceProvider);
  final deviceService = ref.watch(deviceSessionServiceProvider);
  final sessionManager = ref.watch(sessionManagerProvider);

  // FIX [PERINGATAN]: Baca setting syncWifiOnly dan teruskan ke SyncWorker.
  // Jika user mengubah setting ini, provider akan rebuild dan worker baru
  // akan dibuat dengan setting yang benar.
  // FIX: settingsProvider is AutoDispose (cannot be ref.watch in keepAlive providers).
  // We read once at build time; the SyncWorker will be recreated if this
  // provider is invalidated due to any other keepAlive dependency changing.
  final settings = ref.read(settingsProvider);

  final worker = SyncWorker(
    db: db,
    syncService: syncService,
    deviceService: deviceService,
    sessionManager: sessionManager,
    bengkelId: profile.bengkelId,
    userId: FirebaseAuth.instance.currentUser?.uid,
    syncWifiOnly: settings.syncWifiOnly, // ← setting kini diteruskan
    onStateChanged: (state) {
      ref.read(syncStatusProvider.notifier).setState(state);
    },
  );

  worker.start();

  ref.onDispose(() {
    worker.dispose();
  });

  return worker;
}
