// 🛡️ ServisLog+ Hybrid Security Policy — Critical Action Guard
// Wrapper untuk critical actions yang wajib re-auth
// Actions: delete, editPaid, export, viewFinancials, manageStaff, changeSettings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/session_manager.dart';
import '../services/biometric_service.dart';

// 🛡️ Critical Action Guard Widget
class CriticalActionGuard extends ConsumerStatefulWidget {
  final VoidCallback onVerified;
  final CriticalActionType actionType;
  final Widget child;
  final String? customReason;
  final bool showTooltip;
  
  const CriticalActionGuard({
    required this.onVerified,
    required this.actionType,
    required this.child,
    this.customReason,
    this.showTooltip = true,
    super.key,
  });
  
  @override
  ConsumerState<CriticalActionGuard> createState() => _CriticalActionGuardState();
}

class _CriticalActionGuardState extends ConsumerState<CriticalActionGuard> {
  bool _isProcessing = false;
  
  @override
  Widget build(BuildContext context) {
    if (widget.showTooltip) {
      return Tooltip(
        message: _getActionDescription(),
        child: _buildGestureDetector(),
      );
    }
    return _buildGestureDetector();
  }
  
  Widget _buildGestureDetector() {
    return GestureDetector(
      onTap: _isProcessing ? null : _handleTap,
      child: widget.child,
    );
  }
  
  Future<void> _handleTap() async {
    setState(() => _isProcessing = true);
    
    try {
      await _requireCriticalAuth();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  
  Future<void> _requireCriticalAuth() async {
    final sessionManager = ref.read(sessionManagerProvider);
    final biometricService = ref.read(biometricServiceProvider);
    
    // 1. Check access level
    final accessLevel = await sessionManager.getAccessLevel();
    if (accessLevel == AccessLevel.blocked) {
      if (mounted) _showBlockedDialog();
      return;
    }
    
    // 2. Check if action is allowed (Zone check)
    final canPerform = await sessionManager.canPerformAction(widget.actionType);
    if (!canPerform) {
      if (mounted) _showRestrictedDialog();
      return;
    }
    
    // 3. Re-auth dengan biometric (3x retry → Master Password fallback)
    final reason = widget.customReason ?? _getAuthReason();
    final result = await biometricService.verifyWithRetry(
      reason: reason,
      maxRetry: 3,
    );
    
    if (result.success) {
      widget.onVerified();
    } else {
      // 🚀 Fallback to Master Password (PIN 6-digit)
      if (!mounted) return;
      final pinVerified = await _showMasterPasswordDialog();
      if (pinVerified) {
        widget.onVerified();
      } else {
        if (mounted) _showVerificationFailed();
      }
    }
  }
  
  String _getAuthReason() {
    switch (widget.actionType) {
      case CriticalActionType.deleteTransaction:
        return 'Verifikasi untuk menghapus transaksi';
      case CriticalActionType.editPaidFee:
        return 'Verifikasi untuk edit biaya lunas';
      case CriticalActionType.exportData:
        return 'Verifikasi untuk export data';
      case CriticalActionType.viewFinancials:
        return 'Verifikasi untuk akses laporan keuangan';
      case CriticalActionType.manageStaff:
        return 'Verifikasi untuk kelola tim';
      case CriticalActionType.changeSettings:
        return 'Verifikasi untuk ubah pengaturan';
    }
  }
  
  String _getActionDescription() {
    switch (widget.actionType) {
      case CriticalActionType.deleteTransaction:
        return 'Hapus Transaksi (Verifikasi Required)';
      case CriticalActionType.editPaidFee:
        return 'Edit Biaya Lunas (Verifikasi Required)';
      case CriticalActionType.exportData:
        return 'Export Data (Verifikasi Required)';
      case CriticalActionType.viewFinancials:
        return 'Laporan Keuangan (Verifikasi Required)';
      case CriticalActionType.manageStaff:
        return 'Kelola Tim (Verifikasi Required)';
      case CriticalActionType.changeSettings:
        return 'Ubah Pengaturan (Verifikasi Required)';
    }
  }
  
  void _showBlockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_outline, color: Colors.red, size: 48),
        title: const Text('Aksi Ditolak'),
        content: const Text('Perangkat offline terlalu lama. Sila perbarui sesi Anda dengan menghubungkan ke internet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
  
  void _showRestrictedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.amber, size: 48),
        title: const Text('Akses Dibatasi'),
        content: const Text('Mode Baca Saja (Offline > 8 jam). Fitur ini sementara tidak dapat digunakan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
  
  void _showVerificationFailed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verifikasi gagal untuk ${_getAuthReason()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  Future<bool> _showMasterPasswordDialog() async {
    final controller = TextEditingController();
    bool isVisible = false;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          icon: const Icon(Icons.admin_panel_settings, color: Colors.indigo, size: 48),
          title: const Text('Master Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gunakan PIN 6-Digit Master Password Anda sebagai fallback verifikasi harian.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: !isVisible,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => isVisible = !isVisible),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final manager = ref.read(sessionManagerProvider);
                final isValid = await manager.verifyMasterPassword(controller.text);
                if (context.mounted) {
                  Navigator.pop(context, isValid);
                }
              },
              child: const Text('Verifikasi'),
            ),
          ],
        ),
      ),
    );
    
    return result ?? false;
  }
}

