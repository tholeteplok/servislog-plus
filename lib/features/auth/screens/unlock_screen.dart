import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../../core/services/encryption_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/bengkel_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/objectbox_provider.dart';
import 'sync_restore_screen.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  final String bengkelId;
  final VoidCallback onUnlocked;

  const UnlockScreen({
    super.key,
    required this.bengkelId,
    required this.onUnlocked,
  });

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _pinController = TextEditingController();
  final _encryption = EncryptionService();
  final _biometric = BiometricService();
  final _bengkel = BengkelService();

  bool _isUnwrapping = false;
  bool _hasBiometric = false;
  bool _showRestore = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final savedKey = await _encryption.getSavedDerivedKey(widget.bengkelId);
    if (savedKey != null) {
      final available = await _biometric.isAvailable();
      if (available) {
        setState(() => _hasBiometric = true);
        _tryBiometricUnlock();
      }
    }
  }

  void _handleSuccessfulUnlock() {
    final db = ref.read(dbProvider);

    // UX-04 FIX: txCount == 0 saja tidak cukup — bengkel baru yang baru
    // daftar memang belum punya transaksi, tapi juga belum punya pelanggan
    // atau stok. Hanya device baru yang "pinjam" data dari device lama yang
    // perlu ditawari restore.
    //
    // Strategi: cek apakah ada SALAH SATU data master (pelanggan ATAU stok).
    // Jika ada, ini bukan device baru → langsung masuk app.
    final txCount = db.transactionBox.count();
    final pelangganCount = db.pelangganBox.count();
    final stokCount = db.stokBox.count();

    final hasAnyMasterData = pelangganCount > 0 || stokCount > 0;
    final isLikelyNewDevice = txCount == 0 && !hasAnyMasterData;

    if (isLikelyNewDevice) {
      // Tampilkan pilihan restore hanya jika benar-benar device baru/kosong
      setState(() => _showRestore = true);
    } else {
      widget.onUnlocked();
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final success = await _biometric.authenticate(
      reason: 'Buka Workshop Encrypted Data',
    );

    if (success) {
      setState(() => _isUnwrapping = true);
      try {
        final savedKey = await _encryption.getSavedDerivedKey(widget.bengkelId);
        final bengkelDoc = await _bengkel.getBengkel(widget.bengkelId);
        final data = bengkelDoc.data() as Map<String, dynamic>?;
        final wrappedKey = data?['masterKey'] as String?;

        if (savedKey != null && wrappedKey != null) {
          final ok = await _encryption.unwrapWithSavedKey(wrappedKey, savedKey);
          if (ok) {
            _handleSuccessfulUnlock();
            return;
          }
        }
        setState(() => _errorText = 'Gagal memulihkan kunci dekripsi.');
      } catch (e) {
        setState(() => _errorText = 'Error: $e');
      } finally {
        setState(() => _isUnwrapping = false);
      }
    }
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text;
    if (pin.length != 6) return;

    setState(() {
      _isUnwrapping = true;
      _errorText = '';
    });

    try {
      final bengkelDoc = await _bengkel.getBengkel(widget.bengkelId);
      final data = bengkelDoc.data() as Map<String, dynamic>?;
      final wrappedKey = data?['masterKey'] as String?;

      if (wrappedKey == null) {
        throw Exception('Bengkel tidak memiliki Master Key');
      }

      final success = await _encryption.unwrapAndSaveMasterKey(
        wrappedKey,
        pin,
        widget.bengkelId,
        // LGK-06 FIX: Push wrapped key baru ke Firestore setelah
        // migrasi legacy → PBKDF2 berhasil, agar device lain tidak
        // terus menggunakan legacy key.
        onMigrationComplete: (newWrappedKey) async {
          try {
            final bengkelRef = _bengkel.firestore
                .collection('bengkel')
                .doc(widget.bengkelId);
            // Push ke sub-collection secrets/masterKey (struktur sesuai bengkel_service)
            await bengkelRef.collection('secrets').doc('masterKey').set({
              'value': newWrappedKey,
              'updatedAt': DateTime.now().toIso8601String(),
              'version': 'v2_pbkdf2',
            }, SetOptions(merge: true));
            // Juga update root doc jika masih pakai legacy field
            await bengkelRef.update({'masterKey': newWrappedKey});
          } catch (e) {
            debugPrint('⚠️ Firestore migration push gagal: $e');
          }
        },
      );

      if (success) {
        _handleSuccessfulUnlock();
      } else {
        setState(() => _errorText = 'PIN Workshop salah');
        _pinController.clear();
      }
    } catch (e) {
      setState(() => _errorText = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isUnwrapping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showRestore) {
      return SyncRestoreScreen(
        bengkelId: widget.bengkelId,
        onFinish: widget.onUnlocked,
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0D0B14), const Color(0xFF1A1528)]
                : [const Color(0xFFF3EEFF), const Color(0xFFE8DEFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    SolarIconsOutline.lock,
                    size: 48,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Workshop Terkunci',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1528),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan 6 digit PIN Workshop Anda untuk mengakses data.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),

                // PIN Input (JetBrains Mono for numbers)
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 32,
                    letterSpacing: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1528),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    if (val.length == 6) _unlockWithPin();
                  },
                ),

                if (_errorText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorText,
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 48),

                if (_isUnwrapping)
                  const CircularProgressIndicator(color: Color(0xFF7C3AED))
                else if (_hasBiometric)
                  TextButton.icon(
                    onPressed: _tryBiometricUnlock,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Gunakan Biometrik'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                    ),
                  ),
                
                const Spacer(),
                
                TextButton(
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  child: Text(
                    'Keluar Akun',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
