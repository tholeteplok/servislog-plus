import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/encryption_service.dart';
import '../services/transaction_number_service.dart';
import '../services/backup_service.dart';
import '../services/local_backup_service.dart';
import 'objectbox_provider.dart';

part 'system_providers.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
}

@riverpod
TrxNumberService trxNumberService(TrxNumberServiceRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TrxNumberService(prefs);
}

@Riverpod(keepAlive: true)
EncryptionService encryptionService(EncryptionServiceRef ref) {
  return EncryptionService();
}

@riverpod
BackupService backupService(BackupServiceRef ref) {
  final db = ref.watch(dbProvider);
  final encryption = ref.watch(encryptionServiceProvider);
  return BackupService(db, encryption);
}

@riverpod
LocalBackupService localBackupService(LocalBackupServiceRef ref) {
  final db = ref.watch(dbProvider);
  return LocalBackupService(db);
}
