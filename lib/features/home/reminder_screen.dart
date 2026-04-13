import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/reminder_provider.dart';
import '../../core/providers/pengaturan_provider.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/services/document_service.dart';
import '../../domain/entities/transaction.dart';

class ReminderScreen extends ConsumerWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(reminderTransactionsProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, theme),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: reminders.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            SolarIconsOutline.bellOff,
                            size: 80,
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Belum ada pengingat.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pelanggan yang masuk masa servis akan muncul di sini.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final trx = reminders[index];
                      return _ReminderCard(trx: trx, settings: settings);
                    }, childCount: reminders.length),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final isDark = theme.brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, statusBarHeight + 12, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.amethyst, const Color(0x009C27B0)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                LucideIcons.chevronLeft,
                color: isDark ? Colors.white : Colors.black87,
              ),
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PENGINGAT SERVIS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -1,
              ),
            ),
            Text(
              'Daftar pelanggan yang perlu segera dihubungi.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final Transaction trx;
  final SettingsState settings;

  const _ReminderCard({required this.trx, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOverdue = trx.isOverdue;
    final statusColor = isOverdue ? Colors.red : Colors.orange;
    final nextDate = trx.nextServiceDate;
    final dateStr = nextDate != null
        ? DateFormat('dd MMM yyyy').format(nextDate)
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              color: statusColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    isOverdue
                        ? SolarIconsBold.dangerSquare
                        : SolarIconsBold.bell,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOverdue ? 'TERLAMBAT SERVIS' : 'SUDAH WAKTUNYA SERVIS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trx.customerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amethyst.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                trx.vehiclePlate,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.amethyst,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              trx.vehicleModel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              SolarIconsOutline.calendar,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Estimasi:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        if (trx.targetServiceKm != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                SolarIconsOutline.rulerAngular,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'KM Target:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${trx.targetServiceKm} KM',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // WhatsApp Button
                  Material(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () async {
                        await DocumentService.sendReminderWhatsApp(
                          phone: trx.customerPhone,
                          transaction: trx,
                          bengkelName: settings.workshopName,
                        );

                        // 🔥 Anti-Spam: Update waktu pengiriman terakhir
                        // Ini akan otomatis menyembunyikan kartu ini dari daftar selama 7 hari
                        trx.lastReminderSentAt = DateTime.now();
                        await ref
                            .read(transactionListProvider.notifier)
                            .updateTransaction(trx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          SolarIconsBold.outgoingCall,
                          color: Colors.green,
                        ),
                      ),
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
