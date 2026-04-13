import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/atelier_header.dart';
import '../../core/providers/master_providers.dart';
import '../../domain/entities/service_master.dart';

class CreateServiceMasterScreen extends ConsumerStatefulWidget {
  final ServiceMaster? itemToEdit;
  final String? initialName;
  const CreateServiceMasterScreen({super.key, this.itemToEdit, this.initialName});

  @override
  ConsumerState<CreateServiceMasterScreen> createState() =>
      _CreateServiceMasterScreenState();
}

class _CreateServiceMasterScreenState
    extends ConsumerState<CreateServiceMasterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _kategoriController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.itemToEdit?.name ?? widget.initialName,
    );
    _hargaController = TextEditingController(
      text: widget.itemToEdit?.basePrice.toString() ?? '0',
    );
    _kategoriController = TextEditingController(
      text: widget.itemToEdit?.category ?? 'Umum',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _kategoriController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final item = ServiceMaster(
        name: _namaController.text.trim(),
        basePrice: int.tryParse(_hargaController.text) ?? 15000,
        category: _kategoriController.text.trim(),
      );

      if (widget.itemToEdit != null) {
        item.id = widget.itemToEdit!.id;
        ref.read(serviceMasterListProvider.notifier).updateItem(item);
      } else {
        ref.read(serviceMasterListProvider.notifier).addItem(item);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.itemToEdit != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAtelierHeaderSub(
            title: isEdit ? 'Edit Layanan' : 'Tambah Layanan',
            subtitle: isEdit ? 'PERBAIKI DATA' : 'TAMBAH DATA BARU',
            showBackButton: true,
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFormCard(
                      children: [
                        TextFormField(
                          controller: _namaController,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                          ),
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nama Jasa',
                            prefixIcon: Icon(SolarIconsOutline.penNewSquare),
                          ),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _kategoriController,
                          style: GoogleFonts.plusJakartaSans(),
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            prefixIcon: Icon(SolarIconsOutline.layers),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _hargaController,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: AppColors.amethyst,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Harga Jasa',
                            prefixIcon: Icon(SolarIconsOutline.wadOfMoney),
                            suffixText: 'IDR',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 68),
                        backgroundColor: AppColors.amethyst,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        isEdit ? 'SIMPAN PERUBAHAN' : 'SIMPAN LAYANAN',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.amethyst.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
