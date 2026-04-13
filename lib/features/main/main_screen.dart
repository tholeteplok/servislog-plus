import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_colors.dart';
import '../home/home_screen.dart';
import '../pelanggan/pelanggan_screen.dart';
import '../katalog/katalog_screen.dart';
import '../home/create_transaction_screen.dart';
import '../pelanggan/create_pelanggan_screen.dart';
import '../katalog/create_barang_screen.dart';
import '../katalog/create_service_master_screen.dart';
import '../katalog/create_sale_screen.dart';
import '../riwayat/history_screen.dart';

import 'package:flutter/services.dart';

import '../../core/providers/navigation_provider.dart';
import '../../core/providers/pelanggan_provider.dart';
import '../../core/providers/stok_provider.dart';
import '../../core/providers/master_providers.dart';
import '../../core/providers/backup_provider.dart';
import '../../core/providers/katalog_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/pengaturan_provider.dart';
import '../../core/providers/history_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/drive_backup_service.dart';
import '../../core/services/device_session_service.dart';
import '../auth/screens/session_displaced_screen.dart';
import '../auth/screens/access_revoked_screen.dart';
import '../pengaturan/sub/restore_screen.dart';
import '../../core/providers/sync_provider.dart';
import '../../core/widgets/standard_dialog.dart';
import 'dart:io' as java_io;
import 'dart:ui' as java_ui;
import 'dart:async';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final PageController _pageController = PageController();
  bool _isMenuExpanded = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _checkBackupStatus();
    _watchDeviceSession();
    _startStatusPolling();
  }

  void _startStatusPolling() {
    // 15-minute periodic check as a secondary safety measure
    _statusTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (ref.read(isWipingProvider)) return;
      ref.invalidate(deviceSessionStatusProvider);
    });
  }

  void _watchDeviceSession() {
    // Listen secara real-time untuk displacement, account deletion, atau remote wipe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(deviceSessionStatusProvider, (previous, next) async {
        if (ref.read(isWipingProvider)) {
          return; // Safety Guard
        }

        final status = next.value;
        if (status == null || 
            status == DeviceSessionStatus.valid || 
            status == DeviceSessionStatus.unknown) {
          return;
        }

        if (!mounted) {
          return;
        }
        final profile = ref.read(currentProfileProvider);
        if (profile == null) {
          return;
        }

        // 1. HANDLE ACCOUNT DISABLED / DELETED (Self-Destruct)
        if (status == DeviceSessionStatus.accountDisabled) {
          final service = ref.read(deviceSessionServiceProvider);
          
          // PHASE: Double-Check Verification
          final isConfirmed = await service.verifyAccountStatusBeforeWipe();
          
          if (isConfirmed && mounted) {
            // STEP 1 & 2: Set Wiping State & Block UI
            // Kita push screen dulu untuk memblokir interaksi
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AccessRevokedScreen()),
              (route) => false,
            );

            // Tunda sebentar untuk transisi UX yang mulus
            await Future.delayed(const Duration(milliseconds: 500));

            // PHASES 3-8: The Nuclear Sequence
            await service.executeNuclearSequence(ref);
          } else {
             debugPrint('🛡️ Verification check: No revocation confirmed or network issue. Skipping wipe.');
          }
          return;
        }

        // 2. HANDLE SESSION DISPLACEMENT (Original logic)
        // Hanya enforce untuk Owner (Single Device Policy)
        if (profile.role != 'owner') return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => SessionDisplacedScreen(
              userId: profile.uid,
              isWipeRequested: status == DeviceSessionStatus.wipeRequested,
            ),
          ),
          (route) => false,
        );
      });
    });
  }

  Future<void> _checkBackupStatus() async {
    // 1. Run auto-backup scheduler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupProvider.notifier).checkAndRunAutoBackup();
    });

    // 2. Check for Recovery (Fresh Install logic)
    final settings = ref.read(settingsProvider);
    if (settings.lastBackupAt == null && !settings.hasCheckedBackupDiscovery) {
      final authService = AuthService();
      final user = await authService.signInSilently();

      if (user != null) {
        // Logged in but no local backup record -> Check Drive
        final driveService = DriveBackupService();
        try {
          final backup = await driveService.downloadLatestBackup();
          if (backup != null && mounted) {
            // Found a backup on Drive! Show Restore Prompt
            _showRestorePrompt(backup);
          } else {
            // No backup found or not logged in, but we've checked
            ref.read(settingsProvider.notifier).setHasCheckedBackupDiscovery(true);
          }
        } catch (e) {
          debugPrint('Silent backup check failed: $e');
        }
      }
    }
  }

  void _showRestorePrompt(java_io.File backupFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StandardDialog(
        title: 'Cadangan Ditemukan',
        message:
            'Kami menemukan cadangan data Anda di Google Drive. Apakah Anda ingin memulihkannya sekarang?',
        secondaryActionLabel: 'Nanti',
        primaryActionLabel: 'Pulihkan sekarang',
        onPrimaryAction: () {
          // Tetap set checked meskipun pulihkan, agar tidak muncul lagi jika gagal/cancel nantinya
          ref
              .read(settingsProvider.notifier)
              .setHasCheckedBackupDiscovery(true);
          Navigator.pop(context); // Close dialog first
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestoreScreen(backupFile: backupFile),
            ),
          );
        },
        onSecondaryAction: () {
          ref
              .read(settingsProvider.notifier)
              .setHasCheckedBackupDiscovery(true);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onFabPressed(int currentIndex) {
    if (currentIndex == 0) {
      setState(() => _isMenuExpanded = !_isMenuExpanded);
    } else if (currentIndex == 2) { // Now Pelanggan
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePelangganScreen()),
      );
    } else if (currentIndex == 1) { // Now Inventaris
      final activeKatalogTab = ref.read(katalogActiveTabProvider);
      if (activeKatalogTab == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateBarangScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateServiceMasterScreen(),
          ),
        );
      }
    } else if (currentIndex == 3) {
      // Toggle History Search
      final isActive = ref.read(historySearchActiveProvider);
      ref.read(historySearchActiveProvider.notifier).set(!isActive);
      if (isActive) {
        // Clear search when closing
        ref.read(historySearchQueryProvider.notifier).set('');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = ref.watch(navigationProvider);

    // 🔄 Ensure SyncWorker is started when MainScreen is active
    ref.watch(syncWorkerProvider);

    // Sync PageController with provider
    ref.listen(navigationProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return PopScope(
      canPop: false, // 🔑 Intercept pop manually
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_isMenuExpanded) {
          setState(() => _isMenuExpanded = false);
        } else if (currentIndex != 0) {
          ref.read(navigationProvider.notifier).setIndex(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                // 🔍 Dismiss keyboard and clear search results when switching screens
                FocusManager.instance.primaryFocus?.unfocus();

                // Clear search queries for all features
                ref.read(homeSearchQueryProvider.notifier).clear();
                ref.read(pelangganListProvider.notifier).updateSearch('');
                ref.read(stokListProvider.notifier).search('');
                ref.invalidate(serviceMasterListProvider);

                ref.read(historySearchQueryProvider.notifier).set('');
                ref.read(historySearchActiveProvider.notifier).set(false);

                ref.read(navigationProvider.notifier).setIndex(index);
                if (_isMenuExpanded) setState(() => _isMenuExpanded = false);
              },
              children: [
                const HomeScreen(),
                KatalogScreen(mainPageController: _pageController),
                const PelangganScreen(),
                const HistoryScreen(),
              ],
            ),
            if (_isMenuExpanded) _buildExpandedMenu(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _onFabPressed(currentIndex),
          backgroundColor: _isMenuExpanded ? Colors.grey : AppColors.amethyst,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: RotationTransition(turns: animation, child: child),
              );
            },
            child: _getFabIcon(currentIndex),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  SolarIconsOutline.home,
                  'Beranda',
                  currentIndex,
                ),
                _buildNavItem(
                  1,
                  SolarIconsOutline.box,
                  'Inventaris',
                  currentIndex,
                ),
                const SizedBox(width: 40), // Space for FAB
                _buildNavItem(
                  2,
                  SolarIconsOutline.usersGroupTwoRounded,
                  'Pelanggan',
                  currentIndex,
                ),
                _buildNavItem(
                  3,
                  SolarIconsOutline.history,
                  'Riwayat',
                  currentIndex,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    int currentIndex,
  ) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.amethyst : Colors.grey;

    return InkWell(
      onTap: () {
        ref.read(navigationProvider.notifier).setIndex(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getFabIcon(int currentIndex) {
    if (_isMenuExpanded) {
      return const Icon(
        Icons.close,
        key: ValueKey('close'),
        color: Colors.white,
      );
    }
    switch (currentIndex) {
      case 0:
        return const Icon(Icons.add, key: ValueKey('add'), color: Colors.white);
      case 2: // Now Pelanggan
        return const Icon(
          LucideIcons.userPlus,
          key: ValueKey('user'),
          color: Colors.white,
        );
      case 1: // Now Inventaris
        final activeKatalogTab = ref.watch(katalogActiveTabProvider);
        return Icon(
          activeKatalogTab == 0 ? LucideIcons.packagePlus : LucideIcons.filePlus,
          key: ValueKey('katalog_$activeKatalogTab'),
          color: Colors.white,
        );
      case 3:
        final isHistorySearch = ref.watch(historySearchActiveProvider);
        return Icon(
          isHistorySearch ? Icons.close : SolarIconsOutline.magnifier,
          key: const ValueKey('history_search'),
          color: Colors.white,
        );
      default:
        return const Icon(
          Icons.add,
          key: ValueKey('default'),
          color: Colors.white,
        );
    }
  }

  Widget _buildExpandedMenu() {
    final double centerX = MediaQuery.of(context).size.width / 2;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Stack(
          children: [
            // ── Background Blur ──
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isMenuExpanded = false),
                child: BackdropFilter(
                  filter: java_ui.ImageFilter.blur(
                    sigmaX: 10 * value,
                    sigmaY: 10 * value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4 * value),
                  ),
                ),
              ),
            ),

            // ── Left Option: Servis ──
            Positioned(
              bottom: 120 + (30 * (1 - value)),
              left: centerX - 120,
              child: Opacity(
                opacity: value,
                child: _MenuOption(
                  icon: AppIcons.service,
                  label: 'Servis',
                  onTap: () {
                    setState(() => _isMenuExpanded = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateTransactionScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Right Option: Jual Barang ──
            Positioned(
              bottom: 120 + (30 * (1 - value)),
              right: centerX - 120,
              child: Opacity(
                opacity: value,
                child: _MenuOption(
                  icon: SolarIconsOutline.cartLarge,
                  label: 'Jual Barang',
                  onTap: () {
                    setState(() => _isMenuExpanded = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateSaleScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.amethyst,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
