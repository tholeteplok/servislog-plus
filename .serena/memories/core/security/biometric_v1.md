# Biometric Security Integration (v1)

This memory documents the biometric authentication layer added to protect sensitive financial data.

## 1. Security Service
- **Location**: `lib/core/services/security_service.dart`.
- **Package**: `local_auth`.
- **Method**: `authenticate({required String reason})`
    - Checks for available biometrics.
    - Falls back to device PIN/Passcode if biometrics are unavailable or failing (configurable via `biometricOnly: false`).
    - Skips authentication if no biometric hardware is present.

## 2. Global Settings Provider
- **Location**: `lib/core/providers/pengaturan_provider.dart`.
- **State**: `isBiometricEnabled` (Boolean).
- **Persistence**: Persisted via `SharedPreferences`.
- **UI Toggle**: Added to the [Pengaturan Screen](file:///c:/Users/fabian%20nuriel/ServisLog_core/lib/features/pengaturan/pengaturan_screen.dart) under the "Keamanan" section.

## 3. Enforcement Logic
- **Primary Use Case**: Protects the [Statistics Screen](file:///c:/Users/fabian%20nuriel/ServisLog_core/lib/features/statistik/statistik_screen.dart).
- **Pattern**: 
    - `StatistikScreen` checks `settings.isBiometricEnabled` in `initState` calls `_checkSecurity()`.
    - If enabled, triggers `SecurityService.authenticate`.
    - If authentication fails or is cancelled, the screen pops back to Home.
    - A loading state (`_isLoading`) prevents a "flash" of sensitive data before authentication completes.

## 4. Analysis & Stability
- Avoided platform-specific imports (e.g., `local_auth_android/ios`) to prevent analysis errors in unified build environments.
- Uses standard `AuthenticationOptions` for cross-platform compatibility.
