import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../../core/constants/app_theme_extension.dart';
import '../../../core/providers/pengaturan_provider.dart';
import '../../../core/providers/system_providers.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/widgets/atelier_header.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/constants/app_strings.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  late TextEditingController _namaBengkelCtrl;
  late TextEditingController _alamatBengkelCtrl;
  late TextEditingController _waBengkelCtrl;
  late TextEditingController _namaOwnerCtrl;
  late TextEditingController _phoneOwnerCtrl;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _namaBengkelCtrl = TextEditingController(text: settings.workshopName);
    _alamatBengkelCtrl = TextEditingController(text: settings.workshopAddress);
    _waBengkelCtrl = TextEditingController(text: settings.workshopWhatsapp);
    _namaOwnerCtrl = TextEditingController(text: settings.ownerName);
    _phoneOwnerCtrl = TextEditingController(text: settings.ownerPhone);
  }

  @override
  void dispose() {
    _namaBengkelCtrl.dispose();
    _alamatBengkelCtrl.dispose();
    _waBengkelCtrl.dispose();
    _namaOwnerCtrl.dispose();
    _phoneOwnerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final notifier = ref.read(settingsProvider.notifier);
    await notifier.updateWorkshopInfo(
      name: _namaBengkelCtrl.text.trim(),
      address: _alamatBengkelCtrl.text.trim(),
      whatsapp: _waBengkelCtrl.text.trim(),
    );
    await notifier.updateOwnerInfo(
      name: _namaOwnerCtrl.text.trim(),
      phone: _phoneOwnerCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.profile.saveSuccess),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAtelierHeaderSub(
            title: AppStrings.profile.title,
            subtitle: AppStrings.profile.subtitle,
            showBackButton: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.profile.workshopInfo, style: theme.sectionLabelStyle),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaBengkelCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: AppStrings.profile.workshopName,
                        prefixIcon: const Icon(Icons.storefront),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Nama bengkel wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatBengkelCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: AppStrings.profile.workshopAddress,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _waBengkelCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.profile.workshopWA,
                        prefixIcon: const Icon(Icons.phone),
                        hintText: '62812...',
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [IndonesianPhoneFormatter()],
                    ),

                    const SizedBox(height: 32),
                    Text(AppStrings.profile.ownerInfo, style: theme.sectionLabelStyle),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaOwnerCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: AppStrings.profile.ownerName,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Nama owner wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneOwnerCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.profile.ownerPhone,
                        prefixIcon: const Icon(Icons.phone_android),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [IndonesianPhoneFormatter()],
                    ),

                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(AppStrings.common.saveChanges),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(
                          SolarIconsOutline.logout,
                          color: Colors.red,
                        ),
                        label: Text(AppStrings.common.logoutAccount),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.common.logoutAccount),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Semua data lokal akan dibersihkan demi keamanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.common.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.common.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(logoutProvider)();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
