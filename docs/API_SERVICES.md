# ServisLog+ API & Services

## Core Services

| Service | File | Description |
|---------|------|-------------|
| AuthService | auth_service.dart | Firebase Google authentication |
| BengkelService | bengkel_service.dart | Workshop CRUD operations |
| EncryptionService | encryption_service.dart | AES-GCM data encryption |
| BiometricService | biometric_service.dart | Fingerprint/Face auth |
| SessionManager | session_manager.dart | User session handling |
| SyncService | sync_service.dart | Abstract sync interface |
| FirestoreSyncService | firestore_sync_service.dart | Firestore implementation |
| BackupService | backup_service.dart | Backup orchestration |
| DriveBackupService | drive_backup_service.dart | Google Drive backup |
| LocalBackupService | local_backup_service.dart | Local file backup |
| TransactionNumberService | transaction_number_service.dart | TRX numbering |
| VehicleDataService | vehicle_data_service.dart | Vehicle operations |
| DeviceSessionService | device_session_service.dart | Device sessions |
| DocumentService | document_service.dart | PDF generation |
| MediaService | media_service.dart | Image handling |
| MigrationService | migration_service.dart | Data migration |

## Repositories

| Repository | File | Purpose |
|------------|------|---------|
| TransactionRepository | transaction_repository.dart | Transaction CRUD |
| PelangganRepository | pelanggan_repository.dart | Customer CRUD |
| StokRepository | stok_repository.dart | Inventory CRUD |
| MasterRepositories | master_repositories.dart | Service master CRUD |
| SaleRepository | sale_repository.dart | Sales CRUD |
| StokHistoryRepository | stok_history_repository.dart | Stock history |

## Providers (State Management)

- auth_provider.dart - Authentication state
- transaction_providers.dart - Transaction state
- stok_provider.dart - Inventory state
- pelanggan_provider.dart - Customer state
- stats_provider.dart - Statistics state
- sync_provider.dart - Sync state
- navigation_provider.dart - Navigation state

---

Last updated: April 2026
