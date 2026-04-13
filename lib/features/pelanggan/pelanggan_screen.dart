import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/pelanggan_provider.dart';
import '../../core/widgets/atelier_list_card.dart';
import '../../core/widgets/standard_dialog.dart';
import '../../domain/entities/pelanggan.dart';
import 'pelanggan_detail_screen.dart';
import '../../core/providers/navigation_provider.dart';
import '../../core/widgets/atelier_header.dart';

class PelangganScreen extends ConsumerStatefulWidget {
  const PelangganScreen({super.key});

  @override
  ConsumerState<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends ConsumerState<PelangganScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 Listen to navigation changes to clear search
    ref.listen(navigationProvider, (previous, next) {
      if (next != 1) {
        // 1 is Pelanggan tab
        _searchController.clear();
      }
    });

    final theme = Theme.of(context);
    final pelangganList = ref.watch(pelangganListProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAtelierHeader(
            title: 'Data Pelanggan',
            subtitle: 'Simpan dan kelola data pelanggan workshop Anda.',
            showBackButton: false,
            searchController: _searchController,
            searchHint: 'Cari nama atau nomor telepon...',
            onSearchChanged: (val) =>
                ref.read(pelangganListProvider.notifier).updateSearch(val),
            actions: [
              IconButton(
                onPressed: () => ref.invalidate(pelangganListProvider),
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

          pelangganList.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          SolarIconsOutline.usersGroupTwoRounded,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada data pelanggan.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final p = pelangganList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PelangganCard(pelanggan: p),
                      );
                    }, childCount: pelangganList.length),
                  ),
                ),
        ],
      ),
    );
  }
}

class _PelangganCard extends ConsumerWidget {
  final Pelanggan pelanggan;
  const _PelangganCard({required this.pelanggan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AtelierListGroup(
      children: [
        AtelierListTile(
          customLeading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.precisionViolet.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              image: pelanggan.photoLocalPath != null
                  ? DecorationImage(
                      image: ResizeImage(
                        FileImage(File(pelanggan.photoLocalPath!)),
                        width: 150,
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: pelanggan.photoLocalPath == null
                ? Text(
                    pelanggan.nama.characters.isNotEmpty
                        ? pelanggan.nama.characters.first.toUpperCase()
                        : '?',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.precisionViolet,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),
          title: pelanggan.nama,
          subtitle: pelanggan.telepon,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PelangganDetailScreen(pelanggan: pelanggan),
            ),
          ),
          onLongPress: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StandardDialog(
        icon: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            SolarIconsOutline.trashBinTrash,
            color: Colors.red,
            size: 36,
          ),
        ),
        title: 'Hapus Pelanggan?',
        message: 'Yakin ingin menghapus data ${pelanggan.nama}? Tindakan ini tidak bisa dibatalkan.',
        primaryActionLabel: 'Hapus',
        primaryActionColor: Colors.red,
        onPrimaryAction: () {
          ref.read(pelangganListProvider.notifier).remove(pelanggan.id);
          Navigator.pop(context);
        },
        secondaryActionLabel: 'Batal',
      ),
    );
  }
}
