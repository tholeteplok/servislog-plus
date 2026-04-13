# Secure Logout & Sync Settings Optimization (2026-04-05)

## Summary
Updated the application with a comprehensive logout mechanism and enhanced secure display for the Bengkel ID in Sync Settings.

## Changes

### 1. Comprehensive Logout
- **EncryptionService**: Added `clearAllSecureData()` to wipe all keys, biometrics, and PINs from `FlutterSecureStorage`.
- **AuthProvider**: Added `logoutProvider` to wrap `clearAllSecureData()`, Firebase `signOut()`, and provider invalidation.
- **PengaturanScreen**: Added a "Keluar dari Akun" tile with a confirmation dialog and automated redirection to `LoginScreen`.

### 2. Sync Settings Security
- **SyncSettingsScreen**: Refactored Bengkel ID display to prioritize `currentProfileProvider` over default settings.
- **Visibility Toggle**: Added `_showBengkelId` toggle using `LucideIcons.eye/eyeOff`.
- **Copy to Clipboard**: Added long-press functionality to copy the raw `bengkelId`.
- **Styling**: Applied `GoogleFonts.jetBrainsMono` to the Bengkel ID for a professional "unique code" aesthetic.

## Key Files
- `lib/core/services/encryption_service.dart`
- `lib/core/providers/auth_provider.dart`
- `lib/features/pengaturan/pengaturan_screen.dart`
- `lib/features/pengaturan/sub/sync_settings_screen.dart`