import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/barcode_scanner_dialog.dart';
import '../../core/providers/katalog_provider.dart';
import '../../domain/entities/stok.dart';
import '../../domain/entities/service_master.dart';
import '../../core/providers/master_providers.dart';
import '../../core/providers/stok_provider.dart';
import 'create_barang_screen.dart';
import 'create_service_master_screen.dart';
import 'stok_history_screen.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/widgets/atelier_header.dart';

class KatalogScreen extends ConsumerStatefulWidget {
  final PageController? mainPageController;
  const KatalogScreen({super.key, this.mainPageController});
  @override
  ConsumerState<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends ConsumerState<KatalogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(katalogActiveTabProvider);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(katalogActiveTabProvider.notifier).set(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const BarcodeScannerDialog(),
    );

    if (result != null && mounted) {
      _searchController.text = result;
      // Trigger search
      if (_tabController.index == 0) {
        ref.read(stokListProvider.notifier).search(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 Listen to navigation changes to clear search
    ref.listen(navigationProvider, (previous, next) {
      if (next != 2) {
        // 2 is Katalog tab
        _searchController.clear();
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stokList = ref.watch(stokListProvider);
    final serviceListAsync = ref.watch(serviceMasterListProvider);
    final serviceList = serviceListAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAtelierHeader(
            title: 'Inventaris',
            subtitle: 'Kelola stok dan layanan jasa workshop Anda.',
            showBackButton: false,
            searchController: _searchController,
            searchHint: _tabController.index == 0
                ? 'Cari item inventaris...'
                : 'Cari layanan jasa...',
            onSearchChanged: (v) {
              if (_tabController.index == 0) {
                ref.read(stokListProvider.notifier).search(v);
              }
            },
            actions: [
              if (_tabController.index == 0) ...[
                IconButton(
                  onPressed: _openScanner,
                  icon: const Icon(SolarIconsOutline.scanner,
                      color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                onPressed: () => ref.invalidate(serviceMasterListProvider),
                icon: const Icon(SolarIconsOutline.refresh,
                    color: Colors.white, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverAppBar(
            pinned: true,
            toolbarHeight: 0,
            collapsedHeight: 0,
            automaticallyImplyLeading: false,
            backgroundColor: theme.colorScheme.surface,
            bottom: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 4,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelColor: theme.colorScheme.primary,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Barang'),
                Tab(text: 'Layanan Jasa'),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // 🛠️ FIX: Only trigger page navigation for HORIZONTAL overscroll.
            // This prevents vertical list overscroll (hitting top/bottom) from accidentally flipping screens.
            if (notification is OverscrollNotification &&
                notification.metrics.axis == Axis.horizontal &&
                widget.mainPageController != null) {
              if (notification.overscroll < 0 && _tabController.index == 0) {
                // Swipe Right (drag right) -> Go to Home (index 0)
                widget.mainPageController!.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else if (notification.overscroll > 0 &&
                  _tabController.index == 1) {
                // Swipe Left (drag left) -> Go to Pelanggan (index 2)
                widget.mainPageController!.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
            return false;
          },
          child: TabBarView(
            controller: _tabController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildBarangTab(stokList, theme),
              _buildJasaTab(serviceList, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarangTab(List<Stok> stokList, ThemeData theme) {
    final sortedStok = ref.watch(sortedStokProvider);
    final currentSort = ref.watch(stokSortNotifierProvider);

    if (stokList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.box,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada item inventaris.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // --- Sorting Bar ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _buildSortChip('Semua', StokSort.none, currentSort),
              _buildSortChip('Tersedikit', StokSort.lowToHigh, currentSort),
              _buildSortChip('Terbanyak', StokSort.highToLow, currentSort),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            itemCount: sortedStok.length,
            itemBuilder: (context, index) {
              final item = sortedStok[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StokCard(item: item, currencyFormat: _currencyFormat),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, StokSort sort, StokSort currentSort) {
    final isSelected = sort == currentSort;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) ref.read(stokSortNotifierProvider.notifier).setSort(sort);
        },
        selectedColor: AppColors.amethyst.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          color: isSelected ? AppColors.amethyst : Colors.grey,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: isSelected
              ? AppColors.amethyst.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildJasaTab(List<ServiceMaster> serviceList, ThemeData theme) {
    if (serviceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.penNewSquare,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada data layanan jasa.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: serviceList.length,
      itemBuilder: (context, index) {
        final item = serviceList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ServiceCard(item: item, currencyFormat: _currencyFormat),
        );
      },
    );
  }
}

class _StokCard extends StatelessWidget {
  final Stok item;
  final NumberFormat currencyFormat;

  const _StokCard({required this.item, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Status colors
    final isLow = item.isLowStock && item.jumlah > 0;
    final isEmpty = item.jumlah == 0;
    final Color badgeColor = isEmpty
        ? AppColors.error
        : (isLow ? Colors.amber : AppColors.success);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amethyst.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            clipBehavior: Clip.antiAlias,
            child: item.photoLocalPath != null
                ? Image.file(
                    File(item.photoLocalPath!),
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(SolarIconsOutline.gallery, size: 24),
                  )
                : const Icon(
                    SolarIconsOutline.box,
                    size: 24,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(width: 16),
          // Middle: Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.kategori,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                if (item.sku != null)
                  Text(
                    'SKU-${item.sku!}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(item.hargaJual),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.amethyst,
                  ),
                ),
              ],
            ),
          ),
          // Right: Stock Badge & Menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${item.jumlah} pcs',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              _buildPopupMenu(context),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return PopupMenuButton<String>(
          icon: const Icon(SolarIconsOutline.menuDots, size: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateBarangScreen(itemToEdit: item),
                  ),
                );
                break;
              case 'tambah':
                _showRestockDialog(context, ref);
                break;
              case 'history':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StokHistoryScreen(stok: item),
                  ),
                );
                break;
              case 'hapus':
                _confirmDelete(context, ref);
                break;
            }
          },
          itemBuilder: (context) => [
            _buildMenuItem('edit', SolarIconsOutline.penNewSquare, 'Ubah Data'),
            _buildMenuItem(
              'tambah',
              SolarIconsOutline.addSquare,
              'Tambah Stok',
            ),
            _buildMenuItem(
              'history',
              SolarIconsOutline.history,
              'Riwayat Stok',
            ),
            const PopupMenuDivider(),
            _buildMenuItem(
              'hapus',
              SolarIconsOutline.trashBinTrash,
              'Hapus',
              isDestructive: true,
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDestructive ? Colors.red : AppColors.amethyst,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isDestructive ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Tambah Stok',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan jumlah stok tambahan untuk ${item.nama}:',
              style: GoogleFonts.plusJakartaSans(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                suffixText: 'pcs',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'BATAL',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                ref
                    .read(stokListProvider.notifier)
                    .restock(item.uuid, amount, 'Restock cepat dari menu');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amethyst,
            ),
            child: Text(
              'SIMPAN',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Hapus Barang?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${item.nama} dari inventaris?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'BATAL',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(stokListProvider.notifier).deleteItem(item.id);
              Navigator.pop(context);
            },
            child: Text(
              'HAPUS',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceMaster item;
  final NumberFormat currencyFormat;

  const _ServiceCard({required this.item, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amethyst.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: const Icon(
                SolarIconsOutline.penNewSquare,
                size: 32,
                color: AppColors.amethyst,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.category ?? 'Umum',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(item.basePrice),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.amethyst,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(),
                _buildPopupMenu(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return PopupMenuButton<String>(
          icon: const Icon(SolarIconsOutline.menuDots, size: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateServiceMasterScreen(itemToEdit: item),
                  ),
                );
                break;
              case 'hapus':
                _confirmDelete(context, ref);
                break;
            }
          },
          itemBuilder: (context) => [
            _buildMenuItem('edit', SolarIconsOutline.penNewSquare, 'Ubah Data'),
            const PopupMenuDivider(),
            _buildMenuItem(
              'hapus',
              SolarIconsOutline.trashBinTrash,
              'Hapus',
              isDestructive: true,
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDestructive ? Colors.red : AppColors.amethyst,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isDestructive ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Hapus Jasa?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${item.name} dari katalog?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'BATAL',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(serviceMasterListProvider.notifier).deleteItem(item.id);
              Navigator.pop(context);
            },
            child: Text(
              'HAPUS',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
