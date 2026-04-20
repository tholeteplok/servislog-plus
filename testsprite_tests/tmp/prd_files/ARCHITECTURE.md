# ServisLog+ Architecture

## Overview
Clean Architecture with Flutter and Riverpod.

## Layers
1. Presentation - Screens, Widgets, Providers
2. Domain - Entities, Business Logic
3. Data - Repositories, Data Sources

## State Management
- Riverpod for reactive state
- Code generation with riverpod_generator

## Database
- ObjectBox for local storage
- Firestore for cloud sync

## Security
- AES-GCM 256-bit encryption
- PBKDF2 key derivation
- Biometric authentication

## Project Structure
lib/core/ - Core utilities
lib/data/ - Repositories  
lib/domain/ - Entities
lib/features/ - Feature modules

## Key Components

### Providers
- auth_provider.dart - Authentication
- transaction_providers.dart - Transactions
- stok_provider.dart - Inventory
- pelanggan_provider.dart - Customers
- stats_provider.dart - Statistics

### Entities
- Transaction, Pelanggan, Vehicle, Stok, Staff

### Services
- AuthService, EncryptionService, BiometricService, SyncService

---

Last updated: April 2026
