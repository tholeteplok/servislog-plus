# ServisLog+ Cloud Migration Progress (Phase 2-4)

## Overview
Successfully integrated the core cloud synchronization and security architecture for ServisLog+. The app now supports background synchronization between local ObjectBox and remote Firestore with field-level encryption for PII.

## Technical Architecture
### 1. Synchronization (`SyncWorker` & `FirestoreSyncService`)
- Automated background sync using `SyncWorker` and `connectivity_plus`.
- Firestore mapping for `transactions`, `customers`, and `staff`.
- Conflict resolution: `updatedAt` server timestamp wins.

### 2. Security & Encryption (`EncryptionService`)
- **Primary Key**: AES-256 key stored in `FlutterSecureStorage`.
- **Secondary Key (Master Password)**: User-defined password used to derive a key (PBKDF2/SHA256) to wrap the Primary Key.
- **Key Recovery**: The wrapped Primary Key is stored in Firestore (`/bengkel/{id}/masterKey`), allowing other devices to join by entering the Master Password.
- **PII Protection**: Fields like `customerName`, `customerPhone`, and `address` are encrypted using a deterministic IV (stored as `IV:Ciphertext`) to support exact-match searches in Firestore.

### 3. Role-Based Access Control (RBAC)
- Custom Claims (`role`, `bengkelId`) managed via Cloud Functions.
- `AuthService` updated to handle `IdTokenResult` and role verification.

## Implemented Services
- `EncryptionService`: Key wrapping/unwrapping and PII encryption.
- `FirestoreSyncService`: CRUD operations on Firestore with encryption integration.
- `BengkelService`: Ownership claiming and staff joining with key sync.
- `MigrationService`: One-time encryption logic for legacy Firestore data.

## Deployment Status
- `firebase.json`: Configured for Firestore and Functions.
- `firestore.rules`: Scoped by `bengkelId` and Roles.
- `Cloud Functions`: Scaffolding for `setRole` is ready.
- **Pending**: Final deployment and multi-device E2E testing.
