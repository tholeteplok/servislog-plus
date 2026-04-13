import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/widgets/the_ceremony_dialog.dart';
import '../../core/widgets/qr_view_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:intl/intl.dart';
import 'create_transaction_screen.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/providers/master_providers.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/widgets/atelier_list_card.dart';
import '../../core/providers/home_provider.dart';
import '../../domain/entities/transaction.dart';
import '../statistik/statistik_screen.dart';
import 'transaction_detail_screen.dart';
import 'package:servislog_core/core/providers/stats_provider.dart';
import '../pengaturan/pengaturan_screen.dart';
import '../pengaturan/sub/fitur_screen.dart';
import '../../core/providers/pengaturan_provider.dart';
import '../../core/providers/pelanggan_provider.dart';
import '../../core/providers/stok_provider.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/providers/katalog_provider.dart';
import '../../domain/entities/pelanggan.dart';
import '../../domain/entities/stok.dart';
import '../../domain/entities/vehicle.dart';
import '../pelanggan/pelanggan_detail_screen.dart';
import '../../core/providers/reminder_provider.dart';
import 'reminder_screen.dart';
import '../../core/widgets/sync_status_indicator.dart';
import '../../core/services/session_manager.dart';
import '../../core/widgets/atelier_skeleton.dart';
import '../../core/widgets/atelier_header.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedTransactionListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _handleDelete(BuildContext context, Transaction trx) {
    final messenger = ScaffoldMessenger.of(context);
    
    // Perform soft delete
    ref.read(paginatedTransactionListProvider.notifier).deleteTransaction(trx.id, trx.uuid);

    // Show SnackBar with Undo
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Transaksi ${trx.trxNumber} dihapus'),
        action: SnackBarAction(
          label: 'BATAL',
          onPressed: () {
            ref.read(paginatedTransactionListProvider.notifier).undoDelete();
          },
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 Sync search controller with provider (e.g. when cleared via navigation)
    ref.listen(homeSearchQueryProvider, (previous, next) {
      if (next.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });

    final paginatedState = ref.watch(paginatedTransactionListProvider);
    final transactions = paginatedState.items;
    final stats = ref.watch(statsProvider);
    final settings = ref.watch(settingsProvider);
    final searchQueryText = ref.watch(homeSearchQueryProvider);
    final searchQuery = searchQueryText.toLowerCase();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- GLOBAL SEARCH DATA ---
    final allPelanggan = ref.watch(pelangganListProvider);
    final allStok = ref.watch(stokListProvider);
    final allVehiclesAsync = ref.watch(vehicleListProvider);
    final allVehicles = allVehiclesAsync.valueOrNull ?? [];

    // Results filtered by search query
    final filteredPelanggan = searchQuery.isEmpty
        ? <Pelanggan>[]
        : allPelanggan
              .where(
                (p) =>
                    p.nama.toLowerCase().contains(searchQuery) ||
                    p.telepon.contains(searchQuery),
              )
              .take(5)
              .toList();

    final filteredVehicles = searchQuery.isEmpty
        ? <Vehicle>[]
        : allVehicles
              .where(
                (v) =>
                    v.plate.toLowerCase().contains(searchQuery) ||
                    v.model.toLowerCase().contains(searchQuery),
              )
              .take(5)
              .toList();

    final filteredStok = searchQuery.isEmpty
        ? <Stok>[]
        : allStok
              .where(
                (s) =>
                    s.nama.toLowerCase().contains(searchQuery) ||
                    (s.sku?.toLowerCase().contains(searchQuery) ?? false),
              )
              .take(5)
              .toList();

    final filteredHistory = searchQuery.isEmpty
        ? <Transaction>[]
        : transactions
              .where(
                (t) =>
                    t.trxNumber.toLowerCase().contains(searchQuery) ||
                    t.customerName.toLowerCase().contains(searchQuery) ||
                    t.vehiclePlate.toLowerCase().contains(searchQuery),
              )
              .take(5)
              .toList();

    final hasAnyResults =
        filteredPelanggan.isNotEmpty ||
        filteredVehicles.isNotEmpty ||
        filteredStok.isNotEmpty ||
        filteredHistory.isNotEmpty;
    final isSearching = searchQuery.isNotEmpty;

    // Filter today's transactions for the list with search support (Normal View)
    final todayTrx = transactions.where((t) {
      final matchesToday = _isToday(t.createdAt) && !t.isDeleted;
      if (!matchesToday) return false;

      // --- FIX: Exclude LUNAS (Paid) transactions from Dashboard ---
      if (t.serviceStatus == ServiceStatus.lunas) return false;

      if (searchQuery.isEmpty) return true;

      return t.vehicleModel.toLowerCase().contains(searchQuery) ||
          t.vehiclePlate.toLowerCase().contains(searchQuery) ||
          t.customerName.toLowerCase().contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAtelierHeader(
            title: settings.workshopName,
            subtitle: DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                .format(DateTime.now()),
            showBackButton: false,
            searchController: _searchController,
            searchHint: 'Cari transaksi hari ini...',
            onSearchChanged: (val) {
              ref.read(homeSearchQueryProvider.notifier).update(val);
            },
            actions: [
              const _InlineZoneBadge(),
              const SizedBox(width: 8),
              const SyncStatusIndicator(),
              if (settings.qrisEnabled) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (settings.qrisImagePath != null) {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha: 0.8),
                        builder: (_) => QRViewView(
                          imagePath: settings.qrisImagePath!,
                          workshopName: settings.workshopName,
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('QRIS Belum Diatur'),
                          content: const Text(
                              'Fitur QRIS aktif tetapi gambar belum diunggah. Atur sekarang?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FiturScreen(),
                                  ),
                                );
                              },
                              child: const Text('Atur Gambar'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  icon: const Icon(SolarIconsOutline.qrCode,
                      color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PengaturanScreen()),
                ),
                icon: const Icon(SolarIconsOutline.settings,
                    color: Colors.white, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),


          // ── ASYMMETRIC BENTO GRID (Now Below Header) ──
          if (!isSearching)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StatistikScreen(),
                              ),
                            ),
                            child: _BentoCard(
                              title: 'PENDAPATAN HARI INI',
                              value: _formatCurrencyShort(
                                stats.todayPendapatan.toDouble(),
                              ),
                              subValue: 'Total Pendapatan',
                              icon: SolarIconsBold.wadOfMoney,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReminderScreen(),
                              ),
                            ),
                            child: _BentoCard(
                              title: 'REMINDER',
                              value: ref
                                  .watch(reminderCountProvider)
                                  .toString(),
                              subValue: 'Mendatang',
                              icon: SolarIconsBold.bell,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _BentoCard(
                            title: 'PENGUNJUNG',
                            value: stats.todayVisitorCount.toString(),
                            subValue:
                                '${stats.todayActiveCount} Diproses',
                            icon: SolarIconsBold.usersGroupTwoRounded,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // 1. Set sort filter to Low to High (Tersedikit)
                              ref
                                  .read(stokSortNotifierProvider.notifier)
                                  .setSort(StokSort.lowToHigh);

                              // 2. Ensure Katalog sub-tab is on 'Barang'
                              ref
                                  .read(katalogActiveTabProvider.notifier)
                                  .set(0);

                              // 3. Switch global tab to index 2 (Katalog)
                              ref
                                  .read(navigationProvider.notifier)
                                  .setIndex(2);
                            },
                            child: _BentoCard(
                              title: 'INVENTARIS',
                              icon: (stats.lowStockCount +
                                          stats.emptyStockCount >
                                      0)
                                  ? SolarIconsBold.box
                                  : SolarIconsBold.checkCircle,
                              color: (stats.lowStockCount +
                                          stats.emptyStockCount >
                                      0)
                                  ? Colors.orange
                                  : Colors.green,
                              border: null, // No-Line Rule
                              valueWidget: (stats.lowStockCount +
                                          stats.emptyStockCount >
                                      0)
                                  ? Row(
                                      children: [
                                        if (stats.lowStockCount > 0) ...[
                                          Text(
                                            stats.lowStockCount.toString(),
                                            style:
                                                GoogleFonts.manrope(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      Colors.orange.shade700,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (stats.emptyStockCount > 0)
                                          Text(
                                            stats.emptyStockCount.toString(),
                                            style:
                                                GoogleFonts.manrope(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.red.shade700,
                                                ),
                                          ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Icon(
                                          SolarIconsBold.checkCircle,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Aman',
                                          style: GoogleFonts.manrope(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                              subValue: 'Status Inventaris',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),


          // ── SEARCH RESULTS OR NORMAL VIEW ──
          if (isSearching) ...[
            if (hasAnyResults) ...[
              // RESULTS SECTIONS
              _buildSearchSection(
                context,
                ref,
                'PELANGGAN & PLAT',
                [...filteredPelanggan, ...filteredVehicles],
                (item) {
                  if (item is Pelanggan) {
                    return _buildPelangganResult(context, item);
                  }
                  if (item is Vehicle) {
                    return _buildVehicleResult(context, item);
                  }
                  return const SizedBox();
                },
                onViewAll: () =>
                    ref.read(navigationProvider.notifier).setIndex(1),
              ),
              _buildSearchSection(
                context,
                ref,
                'INVENTARIS',
                filteredStok,
                (item) => _buildStokResult(context, ref, item as Stok),
                onViewAll: () {
                  ref.read(stokListProvider.notifier).search(searchQueryText);
                  ref.read(navigationProvider.notifier).setIndex(2);
                },
              ),
              _buildSearchSection(
                context,
                ref,
                'RIWAYAT TRANSAKSI',
                filteredHistory,
                (item) => _buildTransactionResult(context, item as Transaction),
                onViewAll: () =>
                    ref.read(navigationProvider.notifier).setIndex(3),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ] else
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        SolarIconsOutline.magnifier,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada hasil untuk "$searchQueryText"',
                        style: GoogleFonts.plusJakartaSans(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ] else ...[
            // ── Today's Visitors Section ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Aktivitas Hari Ini",
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(navigationProvider.notifier).setIndex(3),
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            todayTrx.isEmpty
                ? (paginatedState.isInitialLoading
                    ? SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => AtelierSkeleton.transactionCard(),
                            childCount: 5,
                          ),
                        ),
                      )
                    : SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                SolarIconsOutline.ghost,
                                size: 48,
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada pengunjung hari ini.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == todayTrx.length) {
                          return paginatedState.isLoadingMore
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: AtelierSkeleton.transactionCard(),
                                  ),
                                )
                              : const SizedBox(height: 100);
                        }
                        return _ActivityCard(
                          trx: todayTrx[index],
                          onDelete: () => _handleDelete(context, todayTrx[index]),
                        );
                      },
                      childCount: todayTrx.length + 1,
                    ),
                  ),
          ],

          // ── Bottom Banner: Monthly Goal ──
          if (!isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceLighter
                        : AppColors.amethyst.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: const AssetImage(
                        'assets/images/bg_pattern.png',
                      ), // Fallback pattern
                      opacity: 0.05,
                      alignment: Alignment.bottomRight,
                      fit: BoxFit.none,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Bulanan',
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${(stats.monthlyPendapatan / (settings.monthlyTarget > 0 ? settings.monthlyTarget : 1) * 100).ceil().clamp(0, 100)}% progress',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            if (settings.monthlyTarget > stats.monthlyPendapatan)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Sisa target: ${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(settings.monthlyTarget - stats.monthlyPendapatan)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 80), // GAP FOR CENTERED FAB
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(
                            SolarIconsOutline.graphUp,
                            color: Colors.white24,
                            size: 32,
                          ),
                          Text(
                            'Kinerja Baik!',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCurrencyShort(double amount) {
    if (amount >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp${(amount / 1000).toInt()}rb';
    }
    return 'Rp${amount.toInt()}';
  }

  // ── SEARCH RESULT BUILDERS ──

  Widget _buildSearchSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<dynamic> items,
    Widget Function(dynamic) itemBuilder, {
    required VoidCallback onViewAll,
  }) {
    final theme = Theme.of(context);
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: itemBuilder(items[index]),
            ),
            childCount: items.length,
          ),
        ),
      ],
    );
  }

  Widget _buildPelangganResult(BuildContext context, Pelanggan p) {
    return _ResultCard(
      title: p.nama,
      subtitle: p.telepon,
      icon: SolarIconsOutline.user,
      color: Colors.blue,
      badge: 'Pelanggan', // UX-05
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PelangganDetailScreen(pelanggan: p),
          ),
        );
      },
    );
  }

  Widget _buildVehicleResult(BuildContext context, Vehicle v) {
    return _ResultCard(
      title: v.plate,
      subtitle: v.model,
      icon: AppIcons.motorcycle,
      color: AppColors.amethyst,
      badge: 'Kendaraan', // UX-05
      onTap: () {
        final owner = v.owner.target;
        if (owner != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PelangganDetailScreen(pelanggan: owner),
            ),
          );
        }
      },
    );
  }

  Widget _buildStokResult(BuildContext context, WidgetRef ref, Stok s) {
    return _ResultCard(
      title: s.nama,
      subtitle:
          '${s.kategori} • Rp ${NumberFormat('#,###').format(s.hargaJual)}',
      icon: SolarIconsOutline.box,
      color: s.jumlah == 0
          ? AppColors.error
          : (s.isLowStock ? Colors.amber : AppColors.success),
      onTap: () {
        ref.read(stokListProvider.notifier).search(s.nama);
        ref.read(navigationProvider.notifier).setIndex(2);
      },
    );
  }

  Widget _buildTransactionResult(BuildContext context, Transaction t) {
    return _ResultCard(
      title: t.trxNumber,
      subtitle: '${t.customerName} • ${t.vehiclePlate}',
      icon: SolarIconsOutline.billList,
      color: Colors.green,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: t),
          ),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  // UX-05 FIX: Badge opsional untuk membedakan tipe hasil pencarian
  final String? badge;

  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                SolarIconsOutline.arrowRight,
                size: 16,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              // UX-05 FIX: Tampilkan badge kategori jika ada
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String? value;
  final Widget? valueWidget;
  final String subValue;
  final IconData icon;
  final Color color;
  final BoxBorder? border;

  const _BentoCard({
    required this.title,
    this.value,
    this.valueWidget,
    required this.subValue,
    required this.icon,
    required this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: border ?? Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Watermark Icon
            Positioned(
              bottom: -20,
              right: -20,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  icon,
                  size: 100,
                  color: isDark ? Colors.white : color,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (valueWidget != null)
                    valueWidget!
                  else
                    Text(
                      value ?? '',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  Text(
                    subValue,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends ConsumerStatefulWidget {
  final Transaction trx;
  final VoidCallback? onDelete;

  const _ActivityCard({
    required this.trx,
    this.onDelete,
  });

  @override
  ConsumerState<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends ConsumerState<_ActivityCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _ActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startTimerIfNeeded();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (widget.trx.serviceStatus == ServiceStatus.dikerjakan) {
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getDurationText(DateTime startTime) {
    final diff = DateTime.now().difference(startTime);
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return '${diff.inMinutes}m';
  }

  void _showStatusPicker(BuildContext context, Transaction trx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'UPDATE STATUS',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            _buildStatusTile(
              context,
              trx,
              ServiceStatus.antri,
              'Akan Dikerjakan (Antri)',
              SolarIconsOutline.clockCircle,
              Colors.blue,
            ),
            _buildStatusTile(
              context,
              trx,
              ServiceStatus.dikerjakan,
              'Sedang Dikerjakan',
              SolarIconsOutline.pills,
              AppColors.amethyst,
            ),
            _buildStatusTile(
              context,
              trx,
              ServiceStatus.selesai,
              'Sudah Selesai (Ready)',
              SolarIconsOutline.checkCircle,
              Colors.orange,
            ),
            _buildStatusTile(
              context,
              trx,
              ServiceStatus.lunas,
              'Lunas & Ambil (Selesai)',
              SolarIconsOutline.wadOfMoney,
              Colors.green,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                SolarIconsOutline.trashBinMinimalistic,
                color: Colors.red,
              ),
              title: Text(
                'Hapus Transaksi',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete?.call();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
}

  Widget _buildStatusTile(
    BuildContext context,
    Transaction trx,
    ServiceStatus status,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = trx.serviceStatus == status;
    return ListTile(
      leading: Icon(icon, color: isSelected ? color : Colors.grey),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
          color: isSelected ? color : null,
        ),
      ),
      trailing: isSelected
          ? Icon(SolarIconsBold.checkCircle, color: color)
          : null,
      onTap: () async {
        Navigator.pop(context);
        if (status == ServiceStatus.lunas) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => TheCeremonyDialog(transaction: trx),
          );
        } else {
          final messenger = ScaffoldMessenger.of(context);
          await ref
              .read(transactionListProvider.notifier)
              .updateTransactionStatus(trx, status);
          ref.invalidate(statsProvider);
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Status diperbarui ke ${status.name.toUpperCase()}',
                ),
                backgroundColor: color,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trx = widget.trx;

    // Status color & Label
    Color statusColor;
    String statusLabel;
    switch (trx.serviceStatus) {
      case ServiceStatus.dikerjakan:
        statusColor = AppColors.amethyst;
        statusLabel = 'DI SERVIS';
        break;
      case ServiceStatus.antri:
        statusColor = Colors.blue;
        statusLabel = 'ANTRI';
        break;
      case ServiceStatus.selesai:
        statusColor = Colors.orange;
        statusLabel = 'SELESAI';
        break;
      case ServiceStatus.lunas:
        statusColor = Colors.green;
        statusLabel = 'LUNAS';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('activity_${trx.uuid}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            SolarIconsOutline.trashBinMinimalistic,
            color: Colors.red,
          ),
        ),
        onDismissed: (_) => widget.onDelete?.call(),
        child: AtelierListGroup(
          children: [
            AtelierListTile(
              customLeading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  image: trx.pelanggan.target?.photoLocalPath != null
                      ? DecorationImage(
                          image: ResizeImage(
                            FileImage(
                              File(trx.pelanggan.target!.photoLocalPath!),
                            ),
                            width: 120,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: trx.pelanggan.target?.photoLocalPath == null
                    ? Icon(
                        trx.vehicleModel.toLowerCase().contains('car')
                            ? AppIcons.car
                            : AppIcons.motorcycle,
                        color: statusColor,
                      )
                    : null,
              ),
              customTitle: Row(
                children: [
                  Text(
                    trx.vehiclePlate,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (trx.serviceStatus == ServiceStatus.dikerjakan &&
                      trx.startTime != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            SolarIconsOutline.clockCircle,
                            size: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getDurationText(trx.startTime!),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: trx.customerName,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              onTap: () {
                if (trx.serviceStatus == ServiceStatus.antri ||
                    trx.serviceStatus == ServiceStatus.dikerjakan) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateTransactionScreen(initialTransaction: trx),
                    ),
                  );
                } else if (trx.serviceStatus == ServiceStatus.selesai) {
                  _showTechNoteSheet(context, trx);
                }
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                _showStatusPicker(context, trx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTechNoteSheet(BuildContext context, Transaction trx) {
    // Memberikan nilai default jika kosong sesuai permintaan user
    final noteController = TextEditingController(
      text: trx.mechanicNotes ?? "Servis selesai.",
    );
    final kmController = TextEditingController(
      text: trx.recommendationKm?.toString() ?? '1000',
    );
    int? selectedTime = trx.recommendationTimeMonth ?? 1;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Catatan Teknisi',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tambahkan detail teknis & rekomendasi servis.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Kondisi & Tindakan',
                  hintText: 'Contoh: Kampas rem tipis, sudah diganti...',
                  prefixIcon: const Icon(SolarIconsOutline.pen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Rekomendasi Servis Kembali',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: kmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Kilometer (+KM)',
                        hintText: '2000',
                        prefixIcon: const Icon(SolarIconsOutline.ruler),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedTime,
                      decoration: InputDecoration(
                        labelText: 'Waktu (+Bulan)',
                        prefixIcon: const Icon(SolarIconsOutline.calendar),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: [1, 2, 3, 6, 12]
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m Bulan'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedTime = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        trx.mechanicNotes = noteController.text.isEmpty
                            ? null
                            : noteController.text;
                        trx.recommendationKm = int.tryParse(kmController.text);
                        trx.recommendationTimeMonth = selectedTime;

                        await ref
                            .read(transactionListProvider.notifier)
                            .updateTransaction(trx);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Catatan teknisi berhasil disimpan',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: AppColors.amethyst,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Simpan',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🛡️ Inline Zone Badge — compact chip sejajar icon header
// Hanya tampil di Zone 2 / 3 / Blocked. Tersembunyi di Zone 1 (Full Access).
// ─────────────────────────────────────────────────────────────────────────────
class _InlineZoneBadge extends ConsumerWidget {
  const _InlineZoneBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(accessLevelProvider);

    return levelAsync.when(
      data: (level) {
        if (level == AccessLevel.full) return const SizedBox.shrink();

        final (color, icon, label) = switch (level) {
          AccessLevel.readOnly => (
              Colors.amber,
              Icons.visibility_outlined,
              'Baca Saja',
            ),
          AccessLevel.readOnlyFinancial => (
              Colors.orange,
              Icons.warning_amber_rounded,
              'Akses Terbatas',
            ),
          AccessLevel.blocked => (
              Colors.redAccent,
              Icons.lock_clock_outlined,
              'Sesi Habis',
            ),
          _ => (Colors.green, Icons.check_circle_outline, ''),
        };

        if (label.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => _showDetail(context, level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 13),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  void _showDetail(BuildContext context, AccessLevel level) {
    final (color, title, body) = switch (level) {
      AccessLevel.readOnly => (
          Colors.amber,
          'Mode Baca Saja',
          'Perangkat offline > 8 jam.\nAnda masih bisa melihat data, tapi tidak bisa mengedit sampai sesi diperbarui.',
        ),
      AccessLevel.readOnlyFinancial => (
          Colors.orange,
          'Akses Terbatas',
          'Perangkat offline > 12 jam.\nFitur laporan keuangan dan edit biaya dibatasi sementara.',
        ),
      AccessLevel.blocked => (
          Colors.redAccent,
          'Sesi Kedaluwarsa',
          'Sesi keamanan telah berakhir (offline > 24 jam).\nHubungkan internet untuk verifikasi ulang.',
        ),
      _ => (Colors.green, '', ''),
    };

    if (title.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1528),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_clock_outlined, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Mengerti'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
