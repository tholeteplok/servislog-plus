class AppSettings {
  static const String workshopName = 'workshop_name';
  static const String workshopAddress = 'workshop_address';
  static const String workshopWhatsapp = 'workshop_whatsapp';
  static const String ownerName = 'owner_name';
  static const String ownerPhone = 'owner_phone';
  static const String themeMode = 'theme_mode'; // 'siang', 'malam', 'otomatis', 'time'
  static const String themeStartTime = 'theme_start_time'; // String "HH:mm"
  static const String themeEndTime = 'theme_end_time'; // String "HH:mm"
  static const String darkMode = 'dark_mode'; // bool
  static const String isDemoMode = 'is_demo_mode';
  static const String barcodeEnabled = 'barcode_enabled';
  static const String qrisEnabled = 'qris_enabled';
  static const String qrisImagePath = 'qris_image_path';
  static const String lastBackupAt = 'last_backup_at';
  static const String workshopId = 'workshop_id';
  static const String isBiometricEnabled = 'is_biometric_enabled';
  static const String autoLockDuration = 'auto_lock_duration'; // int: 0, 1, 5, 10, 30, 60
  static const String requireBiometricSensitive = 'require_biometric_sensitive';
  static const String autoLock30m = 'auto_lock_30m'; // Deprecated in favor of autoLockDuration
  static const String syncWifiOnly = 'sync_wifi_only';
  static const String syncCompressionMax = 'sync_compression_max';
  static const String reminderThresholdDays = 'reminder_threshold_days';
  static const String monthlyTarget = 'monthly_target';
  static const String hasSeenOnboarding = 'has_seen_onboarding';
  static const String hasCheckedBackupDiscovery = 'has_checked_backup_discovery';
}
