import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/providers/sale_providers.dart';
import '../../core/providers/master_providers.dart';
import '../../core/providers/pelanggan_provider.dart';
import '../../core/providers/media_provider.dart';
import '../../core/widgets/glass_card.dart';
import '../../domain/entities/pelanggan.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/sale.dart';
import 'create_pelanggan_screen.dart';
import 'create_vehicle_screen.dart';
import '../home/create_transaction_screen.dart';

class PelangganDetailScreen extends ConsumerWidget {
  final Pelanggan pelanggan;
  const PelangganDetailScreen({super.key, required this.pelanggan});

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final mediaService = ref.read(mediaServiceProvider);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ubah Foto Profil',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  context,
                  icon: SolarIconsOutline.camera,
                  label: 'Kamera',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                _buildPickerOption(
                  context,
                  icon: SolarIconsOutline.gallery,
                  label: 'Galeri',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await mediaService.pickImage(source);
      if (image != null) {
        final path = await mediaService.saveImageLocally(image);
        if (path != null) {
          ref
              .read(pelangganListProvider.notifier)
              .updatePhoto(pelanggan.id, path);
        }
      }
    }
  }

  Widget _buildPickerOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.amethyst.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: AppColors.amethyst, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch for updates to this specific pelanggan
    final p = ref
        .watch(pelangganListProvider)
        .firstWhere((e) => e.id == pelanggan.id, orElse: () => pelanggan);

    final vehicles = ref.watch(customerVehiclesProvider(p.id));
    final transactions = ref.watch(customerTransactionsProvider(p.id));
    final sales = ref.watch(customerSalesProvider(p.nama));

    // Combine and sort history
    final history = [...transactions, ...sales];
    history.sort((a, b) {
      final dateA = (a is Transaction) ? a.createdAt : (a as Sale).createdAt;
      final dateB = (b is Transaction) ? b.createdAt : (b as Sale).createdAt;
      return dateB.compareTo(dateA);
    });

    // Calculate total spending
    final totalSpending =
        transactions.fold(0.0, (sum, item) => sum + item.totalAmount) +
        sales.fold(0.0, (sum, item) => sum + item.totalPrice);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, ref, theme, p),
          _buildStatsRow(
            theme,
            vehicles.length,
            transactions.length,
            totalSpending,
          ),
          _buildInfoSection(theme, p),
          _buildVehiclesSection(context, theme, p, vehicles),
          _buildHistoryHeader(context, theme),
          _buildHistoryList(context, theme, history),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Pelanggan p,
  ) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final isDark = theme.brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, statusBarHeight + 12, 20, 24),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient(context),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.chevronLeft,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        AppIcons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreatePelangganScreen(initialPelanggan: p),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        AppIcons.delete,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      onPressed: () => _confirmDelete(context, ref, p),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: p.photoLocalPath != null
                            ? FileImage(File(p.photoLocalPath!))
                            : null,
                        child: p.photoLocalPath == null
                            ? Text(
                                p.nama.isNotEmpty
                                    ? p.nama[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.amethyst,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.amethyst,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          SolarIconsOutline.camera,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              p.nama,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -1,
              ),
            ),
            Text(
              p.telepon,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    ThemeData theme,
    int vehicleCount,
    int visitCount,
    double totalSpending,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            _buildStatItem('Kendaraan', vehicleCount.toString()),
            _buildStatDivider(theme),
            _buildStatItem('Kunjungan', visitCount.toString()),
            _buildStatDivider(theme),
            _buildStatItem(
              'Total',
              NumberFormat.compactCurrency(
                locale: 'id',
                symbol: 'Rp',
              ).format(totalSpending),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.amethyst,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 30,
      color: theme.dividerColor.withValues(alpha: 0.1),
    );
  }

  Widget _buildInfoSection(ThemeData theme, Pelanggan p) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 2),
        child: Column(
          children: [
            _buildInfoTile(
              theme,
              icon: AppIcons.location,
              label: 'Alamat',
              value: p.alamat.isNotEmpty ? p.alamat : 'Belum diisi',
            ),
            if (p.catatan.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoTile(
                theme,
                icon: SolarIconsOutline.notes,
                label: 'Catatan',
                value: p.catatan,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amethyst.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.amethyst),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildVehiclesSection(
    BuildContext context,
    ThemeData theme,
    Pelanggan p,
    List<Vehicle> vehicles,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kendaraan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateVehicleScreen(pelanggan: p),
                    ),
                  ),
                  icon: const Icon(AppIcons.add, size: 18),
                  label: Text(
                    'Tambah',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.amethyst,
                  ),
                ),
              ],
            ),
          ),
          if (vehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.layoutGrid,
                        size: 48,
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Belum ada kendaraan terdaftar',
                        style: GoogleFonts.plusJakartaSans(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateVehicleScreen(
                            pelanggan: p,
                            initialVehicle: v,
                          ),
                        ),
                      ),
                      child: Container(
                        width: 280, // Increased width to fit button
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.amethyst.withValues(alpha: 0.8),
                              AppColors.amethyst,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amethyst.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              v.type.toLowerCase() == 'mobil'
                                  ? AppIcons.car
                                  : v.type.toLowerCase() == 'truk'
                                  ? AppIcons.truck
                                  : AppIcons.motorcycle,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    v.model,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    v.plate,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateTransactionScreen(
                                    initialPelanggan: p,
                                    initialVehicle: v,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.amethyst,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                '+ Servis',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(BuildContext context, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
        child: Text(
          'Riwayat Aktivitas',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    ThemeData theme,
    List<dynamic> history,
  ) {
    if (history.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Opacity(
            opacity: 0.5,
            child: Text(
              'Belum ada riwayat servis atau pembelian.',
              style: GoogleFonts.plusJakartaSans(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = history[index];
        final isService = item is Transaction;
        final date = isService ? item.createdAt : (item as Sale).createdAt;
        final title = isService ? item.vehicleModel : item.itemName;
        final subtitle = isService ? item.trxNumber : "Pembelian Barang";
        final amount = isService ? item.totalAmount : (item as Sale).totalPrice;
        final isFirst = index == 0;
        final isLast = index == history.length - 1;

        Color statusColor;
        IconData icon;
        if (isService) {
          switch (item.serviceStatus) {
            case ServiceStatus.antri:
              statusColor = Colors.blue;
              icon = SolarIconsOutline.clockCircle;
              break;
            case ServiceStatus.dikerjakan:
              statusColor = AppColors.amethyst;
              icon = SolarIconsOutline.settings;
              break;
            case ServiceStatus.selesai:
              statusColor = Colors.orange;
              icon = SolarIconsOutline.checkCircle;
              break;
            case ServiceStatus.lunas:
              statusColor = Colors.green;
              icon = SolarIconsOutline.wadOfMoney;
              break;
          }
        } else {
          statusColor = Colors.orange;
          icon = SolarIconsOutline.cartLarge;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 24),
              // Timeline Line & Indicator
              Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isFirst
                          ? Colors.transparent
                          : theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.2),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isLast
                          ? Colors.transparent
                          : theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: statusColor, size: 20),
                      ),
                      title: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtitle,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(date),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp',
                          decimalDigits: 0,
                        ).format(amount),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        );
      }, childCount: history.length),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Pelanggan p) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Hapus Pelanggan?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Semua data kendaraan terkait akan tetap ada, namun relasi pelanggan akan terputus. Lanjutkan?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: theme.hintColor),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(pelangganListProvider.notifier).remove(p.id);
              Navigator.pop(context); // dialog
              Navigator.pop(context); // detail screen
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
