import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dotted_border/dotted_border.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_extension.dart';
import '../../../core/providers/pengaturan_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/widgets/security_dialogs.dart';
import '../../../core/widgets/atelier_header.dart';

class FiturScreen extends ConsumerStatefulWidget {
  const FiturScreen({super.key});

  @override
  ConsumerState<FiturScreen> createState() => _FiturScreenState();
}

class _FiturScreenState extends ConsumerState<FiturScreen> {
  Future<void> _pickQrisImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final qrisDir = Directory(p.join(appDir.path, 'qris'));
      if (!await qrisDir.exists()) await qrisDir.create(recursive: true);

      final settings = ref.read(settingsProvider);
      // Cleanup old file
      if (settings.qrisImagePath != null) {
        final oldFile = File(settings.qrisImagePath!);
        if (await oldFile.exists()) await oldFile.delete();
      }

      final fileName =
          'qris_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
      final newPath = p.join(qrisDir.path, fileName);

      await File(image.path).copy(newPath);
      await ref.read(settingsProvider.notifier).setQrisImagePath(newPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar QRIS berhasil diunggah'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _removeQrisImage() async {
    final settings = ref.read(settingsProvider);
    if (settings.qrisImagePath != null) {
      final oldFile = File(settings.qrisImagePath!);
      if (await oldFile.exists()) await oldFile.delete();
    }
    await ref.read(settingsProvider.notifier).setQrisImagePath(null);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gambar QRIS dihapus')));
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final bio = BiometricService();
    final notifier = ref.read(settingsProvider.notifier);

    if (value) {
      // Step 1: Check hardware
      final available = await bio.isAvailable();
      if (!mounted) return;

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hardware biometrik tidak tersedia atau belum didaftarkan',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Step 2: Setup PIN
      final pin = await SecurityDialogs.showPINSetup(context);
      if (pin == null) return;

      // Step 3: Authenticate
      final bioOk = await bio.authenticate();
      if (!mounted) return;

      if (bioOk) {
        await bio.savePin(pin);
        await notifier.setBiometricEnabled(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Keamanan internal diaktifkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      // Step 4: Verify to disable
      final ok = await SecurityDialogs.verify(
        context,
        reason: 'Verifikasi untuk mematikan keamanan',
      );
      if (!mounted) return;

      if (ok) {
        await bio.clearPin();
        await notifier.setBiometricEnabled(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Keamanan internal dinonaktifkan'),
              backgroundColor: AppColors.amethyst,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          const SliverAtelierHeaderSub(
            title: 'Fitur Tambahan',
            subtitle: 'Aktifkan modul tambahan untuk efisiensi bengkel.',
            showBackButton: true,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OTOMATISASI', style: theme.sectionLabelStyle),
                  const SizedBox(height: 16),

                  _FeatureToggle(
                    title: 'Pemindai Barcode',
                    subtitle: 'Pencarian produk & jasa menggunakan kamera',
                    icon: Icons.qr_code_scanner,
                    value: settings.barcodeEnabled,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setBarcodeEnabled(v),
                  ),
                  const SizedBox(height: 12),
                  _FeatureToggle(
                    title: 'Metode QRIS Static',
                    subtitle: 'Tampilkan QRIS statis pada kuitansi',
                    icon: Icons.qr_code,
                    value: settings.qrisEnabled,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setQrisEnabled(v),
                  ),

                  if (settings.qrisEnabled) ...[
                    const SizedBox(height: 16),
                    if (settings.qrisImagePath != null)
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.amethyst.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(settings.qrisImagePath!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                IconButton.filled(
                                  onPressed: _pickQrisImage,
                                  icon: const Icon(Icons.edit, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.amethyst
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: _removeQrisImage,
                                  icon: const Icon(Icons.close, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      DottedBorder(
                        options: RoundedRectDottedBorderOptions(
                          color: AppColors.amethyst.withValues(alpha: 0.5),
                          strokeWidth: 2,
                          dashPattern: const [8, 4],
                          radius: const Radius.circular(16),
                        ),
                        child: InkWell(
                          onTap: _pickQrisImage,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  SolarIconsOutline.upload,
                                  color: AppColors.amethyst.withValues(
                                    alpha: 0.6,
                                  ),
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Unggah Gambar QRIS',
                                  style: TextStyle(
                                    color: AppColors.amethyst.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Klik untuk memilih gambar dari galeri',
                                  style: TextStyle(
                                    color: Colors.grey.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 40),
                  Text('KOMUNIKASI', style: theme.sectionLabelStyle),
                  const SizedBox(height: 16),
                  _FeatureToggle(
                    title: 'Notifikasi WhatsApp',
                    subtitle: 'Kirim struk/pengingat via WhatsApp API',
                    icon: Icons.chat_outlined,
                    value: true,
                    onChanged: (v) {},
                    isLocked: true,
                  ),

                  const SizedBox(height: 40),
                  Text('KEAMANAN', style: theme.sectionLabelStyle),
                  const SizedBox(height: 16),
                  _FeatureToggle(
                    title: 'Kunci Biometrik & PIN',
                    subtitle:
                        'Amankan aplikasi dengan sidik jari & PIN 6 angka',
                    icon: Icons.security_rounded,
                    value: settings.isBiometricEnabled,
                    onChanged: _toggleBiometric,
                  ),

                  const Spacer(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLocked;

  const _FeatureToggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        secondary: Icon(
          icon,
          color: isLocked ? Colors.grey : theme.colorScheme.primary,
        ),
        value: value,
        onChanged: isLocked ? null : onChanged,
        activeThumbColor: theme.colorScheme.primary,
      ),
    );
  }
}
