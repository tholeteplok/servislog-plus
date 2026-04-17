# ServisLog+ Documentation

Complete documentation for the ServisLog+ workshop management application.

## Documentation Structure

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Overview and quick start |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture and design |
| [FEATURES.md](FEATURES.md) | Feature descriptions |
| [SECURITY.md](SECURITY.md) | Security architecture |
| [API_SERVICES.md](API_SERVICES.md) | Services and API reference |

## Quick Overview

**ServisLog+** is a Flutter-based workshop management application featuring:

- Multi-platform (Android, iOS, Web, Desktop)
- Offline-first with cloud sync
- Riverpod state management
- ObjectBox + Firestore database
- AES-GCM encryption
- Biometric authentication

## Quick Start

Resolving dependencies...
Downloading packages...
  _fe_analyzer_shared 67.0.0 (99.0.0 available)
  _flutterfire_internals 1.3.59 (1.3.69 available)
  analyzer 6.4.1 (12.1.0 available)
  analyzer_plugin 0.11.3 (0.14.8 available)
  archive 3.6.1 (4.0.9 available)
  build 2.4.1 (4.0.5 available)
  build_config 1.1.2 (1.3.0 available)
  build_resolvers 2.4.2 (3.0.4 available)
  build_runner 2.4.13 (2.13.1 available)
  build_runner_core 7.3.2 (9.3.2 available)
  cloud_firestore 5.6.12 (6.3.0 available)
  cloud_firestore_platform_interface 6.6.12 (7.2.0 available)
  cloud_firestore_web 4.4.12 (5.3.0 available)
  connectivity_plus 5.0.2 (7.1.1 available)
  connectivity_plus_platform_interface 1.2.4 (2.1.0 available)
  custom_lint_core 0.6.3 (0.8.2 available)
  dart_style 2.3.6 (3.1.8 available)
  device_info_plus 12.4.0 (13.0.0 available)
  device_info_plus_platform_interface 7.0.3 (8.0.0 available)
  extension_google_sign_in_as_googleapis_auth 2.0.13 (3.0.0 available)
  firebase_auth 5.7.0 (6.4.0 available)
  firebase_auth_platform_interface 7.7.3 (8.1.9 available)
  firebase_auth_web 5.15.3 (6.1.5 available)
  firebase_core 3.15.2 (4.7.0 available)
  firebase_core_web 2.24.1 (3.6.0 available)
  firebase_crashlytics 4.3.10 (5.2.0 available)
  firebase_crashlytics_platform_interface 3.8.10 (3.8.20 available)
  firebase_storage 12.4.10 (13.3.0 available)
  firebase_storage_platform_interface 5.2.10 (5.2.20 available)
  firebase_storage_web 3.10.17 (3.11.5 available)
  fl_chart 0.70.2 (1.2.0 available)
  flat_buffers 23.5.26 (25.9.23 available)
  flutter_launcher_icons 0.13.1 (0.14.4 available)
  flutter_riverpod 2.5.1 (3.3.1 available)
  freezed_annotation 2.4.4 (3.1.0 available)
  google_sign_in 6.3.0 (7.2.0 available)
  google_sign_in_android 6.2.1 (7.2.10 available)
  google_sign_in_ios 5.9.0 (6.3.0 available)
  google_sign_in_platform_interface 2.5.0 (3.1.0 available)
  google_sign_in_web 0.12.4+4 (1.1.3 available)
  googleapis 13.2.0 (16.0.0 available)
  googleapis_auth 1.6.0 (2.3.0 available)
  image 4.3.0 (4.8.0 available)
  image_picker_android 0.8.13+15 (0.8.13+16 available)
  js 0.6.7 (0.7.2 available)
  local_auth 2.3.0 (3.0.1 available)
  local_auth_android 1.0.56 (2.0.8 available)
  local_auth_darwin 1.6.1 (2.0.3 available)
  local_auth_windows 1.0.11 (2.0.1 available)
  lottie 3.3.0 (3.3.3 available)
  meta 1.17.0 (1.18.2 available)
  mobile_scanner 5.2.3 (7.2.0 available)
  objectbox 4.1.0 (5.3.1 available)
  objectbox_flutter_libs 4.1.0 (5.3.1 available)
  objectbox_generator 4.1.0 (5.3.1 available)
  path_provider_android 2.2.23 (2.3.1 available)
  pointycastle 3.9.1 (4.0.0 available)
  riverpod 2.5.1 (3.2.1 available)
  riverpod_analyzer_utils 0.5.1 (0.5.10 available)
  riverpod_annotation 2.3.5 (4.0.2 available)
  riverpod_generator 2.4.0 (4.0.3 available)
  share_plus 10.1.4 (13.0.0 available)
  share_plus_platform_interface 5.0.2 (7.0.0 available)
  shelf_web_socket 2.0.1 (3.0.0 available)
  source_gen 1.5.0 (4.2.2 available)
  test_api 0.7.10 (0.7.11 available)
  vector_math 2.2.0 (2.3.0 available)
  vm_service 15.0.2 (15.1.0 available)
  win32 5.15.0 (6.0.1 available)
  win32_registry 2.1.0 (3.0.3 available)
Got dependencies!
70 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
[INFO] Generating build script...
[INFO] Generating build script completed, took 589ms

[INFO] Initializing inputs
[INFO] Reading cached asset graph...
[INFO] Reading cached asset graph completed, took 594ms

[INFO] Checking for updates since last build...
[INFO] Checking for updates since last build completed, took 10.3s

[INFO] Running build...
[INFO] 1.1s elapsed, 0/16 actions completed.
[WARNING] riverpod_generator on lib/core/providers/auth_provider.dart:
Your current `analyzer` version may not fully support your current SDK version.

Analyzer language version: 3.4.0
SDK language version: 3.11.0

Please update to the latest `analyzer` version (12.1.0) by running
`flutter packages upgrade`.

If you are not getting the latest version by running the above command, you
can try adding a constraint like the following to your pubspec to start
diagnosing why you can't get the latest version:

dev_dependencies:
  analyzer: ^12.1.0

[SEVERE] riverpod_generator on lib/core/widgets/atelier_header.dart:

This builder requires Dart inputs without syntax errors.
However, package:servislog_core/core/widgets/atelier_header.dart (or an existing part) contains the following errors.
atelier_header.dart:94:19: Expected an identifier.
atelier_header.dart:94:27: Expected to find ':'.
atelier_header.dart:94:27: Expected an identifier.
And 3 more...

Try fixing the errors and re-running the build.

[INFO] 2.4s elapsed, 5/21 actions completed.
[INFO] 3.4s elapsed, 8/21 actions completed.
[INFO] 4.5s elapsed, 8/21 actions completed.
[INFO] 5.6s elapsed, 9/45 actions completed.
[INFO] 6.6s elapsed, 20/48 actions completed.
[INFO] 7.8s elapsed, 27/107 actions completed.
[INFO] 8.8s elapsed, 53/117 actions completed.
[INFO] 9.9s elapsed, 78/155 actions completed.
[INFO] 10.9s elapsed, 169/251 actions completed.
[INFO] 12.0s elapsed, 253/315 actions completed.
[INFO] 13.0s elapsed, 371/398 actions completed.
[INFO] 15.9s elapsed, 415/433 actions completed.
[INFO] 29.0s elapsed, 415/433 actions completed.
[WARNING] No actions completed for 15.5s, waiting on:
  - build_resolvers:transitive_digests on package:petitparser/parser.dart
  - build_resolvers:transitive_digests on package:petitparser/expression.dart
  - riverpod_generator on lib/core/providers/sync_provider.dart
  - riverpod_generator on lib/core/providers/pelanggan_provider.dart
  - riverpod_generator on lib/core/providers/transaction_providers.dart
  .. and 13 more

[INFO] 34.1s elapsed, 415/433 actions completed.
[INFO] 35.2s elapsed, 435/444 actions completed.
[INFO] 37.5s elapsed, 435/444 actions completed.
[INFO] 38.5s elapsed, 442/444 actions completed.
[INFO] 40.5s elapsed, 463/479 actions completed.
[INFO] 41.6s elapsed, 465/498 actions completed.
[INFO] 42.6s elapsed, 482/527 actions completed.
[INFO] 43.6s elapsed, 546/620 actions completed.
[INFO] 45.7s elapsed, 553/635 actions completed.
[INFO] 46.8s elapsed, 633/701 actions completed.
[INFO] 47.8s elapsed, 669/738 actions completed.
[INFO] 52.9s elapsed, 687/739 actions completed.
[INFO] 53.9s elapsed, 698/744 actions completed.
[INFO] 55.0s elapsed, 721/758 actions completed.
[INFO] 56.3s elapsed, 737/780 actions completed.
[SEVERE] objectbox_generator:resolver on lib/core/widgets/atelier_header.dart:

This builder requires Dart inputs without syntax errors.
However, package:servislog_core/core/widgets/atelier_header.dart (or an existing part) contains the following errors.
atelier_header.dart:94:19: Expected an identifier.
atelier_header.dart:94:27: Expected to find ':'.
atelier_header.dart:94:27: Expected an identifier.
And 3 more...

Try fixing the errors and re-running the build.

[INFO] 58.7s elapsed, 834/862 actions completed.
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:entity Sale(0:0) sync:OFF
[WARNING] objectbox_generator:resolver on lib/domain/entities/sale.dart:
  DateTime property 'createdAt' in entity 'Sale' is stored and read using millisecond precision. To silence this warning, add an explicit type using @Property(type: PropertyType.date) or @Property(type: PropertyType.dateNano) annotation.
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property id(0:0) type:long flags:1
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property uuid(0:0) type:string flags:2080 index:hash
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property isDeleted(0:0) type:bool flags:8 index:value
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property itemName(0:0) type:string flags:2048 index:hash
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property quantity(0:0) type:long flags:0
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property totalPrice(0:0) type:long flags:0
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property costPrice(0:0) type:long flags:0
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property totalProfit(0:0) type:long flags:0
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property transactionId(0:0) type:string flags:2048 index:hash
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property stokUuid(0:0) type:string flags:0
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property customerName(0:0) type:string flags:0
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property paymentMethod(0:0) type:string flags:0
[INFO] objectbox_generator:resolver on lib/domain/entities/sale.dart:  property createdAt(0:0) type:date flags:8 index:value
[INFO] 59.9s elapsed, 844/872 actions completed.
[INFO] 1m 0s elapsed, 864/879 actions completed.
[INFO] 1m 2s elapsed, 870/886 actions completed.
[INFO] 1m 3s elapsed, 895/896 actions completed.
[INFO] objectbox_generator:generator on lib/$lib$:Package: servislog_core
[INFO] objectbox_generator:generator on lib/$lib$:Found 11 entities in: (lib/domain/entities/pelanggan.objectbox.info, lib/domain/entities/sale.objectbox.info, lib/domain/entities/service_master.objectbox.info, ..., lib/domain/entities/transaction_item.objectbox.info, lib/domain/entities/vehicle.objectbox.info)
[INFO] objectbox_generator:generator on lib/$lib$:Using model: lib/objectbox-model.json
[INFO] objectbox_generator:generator on lib/$lib$:Generating code: lib/objectbox.g.dart
[INFO] Running build completed, took 1m 4s

[INFO] Caching finalized dependency graph...
[INFO] Caching finalized dependency graph completed, took 496ms

[SEVERE] Failed after 1m 5s
More than one device connected; please specify a device with the '-d <deviceId>' flag, or use '-d all' to act on all devices.

Windows (desktop) • windows • windows-x64    • Microsoft Windows [Version 10.0.26200.8037]
Chrome (web)      • chrome  • web-javascript • Google Chrome 147.0.7727.56
Edge (web)        • edge    • web-javascript • Microsoft Edge 147.0.3912.60

## Tech Stack

- Flutter 3.x / Dart 3.x
- Riverpod for state management
- ObjectBox for local database
- Firebase (Auth, Firestore, Storage, Crashlytics)
- AES-GCM encryption with PBKDF2

---

Last updated: April 2026
