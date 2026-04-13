# Global Static QRIS & Branding Implementation (2026-04-04)

## Global Static QRIS
- **Floating Icon**: A global QRIS quick-access button is implemented as a `Positioned` widget in `MainScreen.dart` (Top-Left). It floats over all main navigation tabs.
- **Overlay View (`QRViewView`)**:
    - Displays the uploaded QRIS image in a white container for scanner compatibility.
    - **Auto-Brightness**: Uses `screen_brightness` to maximize brightness when open and restore to the previous level on close.
- **Payment Integration**: The `TheCeremonyDialog` now includes a "Lihat QR" button when the payment method is set to QRIS.
- **Persistent Storage**: QRIS images are picked and copied to the application's internal documents directory (`qris/` folder) to ensure availability even if the original gallery file is deleted. Old files are automatically purged on update.

## Branded Identity
- **App Icons**: The asset `assets/icons/app_icons.png` is now used as:
    - The main feature icon in `TentangScreen.dart`.
    - The global **Launcher Icon** for both Android and iOS.
- **Launcher Configuration**: Integrated `flutter_launcher_icons` in `pubspec.yaml` with `remove_alpha_ios: true` for App Store compliance.

## UI/UX Optimizations
- **Blocked Icons Fix**: Removed a transparent `AppBar` from `MainScreen` that was intercepting touches on the `HomeScreen` settings icon. Replaced it with a minimal `Positioned` widget.
- **Redundancy Cleanup**: Removed the QR icon from the `HomeScreen` header as it is now available globally from the floating button.

## Dependencies Added
- `screen_brightness: ^2.1.7`
- `flutter_launcher_icons: ^0.13.1` (dev)
