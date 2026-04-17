import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/bengkel_service.dart';
import 'create_bengkel_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _joinController = TextEditingController();
  final _pinController = TextEditingController();
  final _bengkelService = BengkelService();
  bool _isJoining = false;
  bool _obscurePin = true;
  String? _joinError;
  String? _pinError;

  @override
  void dispose() {
    _joinController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidianBase : AppColors.atelierBase,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.precisionViolet.withValues(alpha: isDark ? 0.05 : 0.03),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      'Selamat Datang! 👋',
                      style: GoogleFonts.manrope(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: isDark ? Colors.white : AppColors.obsidianBase,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pilih konfigurasi akses untuk memulai eksplorasi platform ServisLog+.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    _OptionCard(
                      isDark: isDark,
                      icon: SolarIconsBold.shop,
                      iconColor: AppColors.precisionViolet,
                      title: 'Buat Workshop Baru',
                      subtitle: 'Bertindak sebagai Owner dengan otorisasi penuh untuk manajemen tim dan keuangan.',
                      badge: 'EKSEKUTIF',
                      badgeColor: AppColors.precisionViolet,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateBengkelScreen()),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _OptionCard(
                      isDark: isDark,
                      icon: SolarIconsBold.usersGroupTwoRounded,
                      iconColor: AppColors.neonGreen,
                      title: 'Gabung ke Workshop',
                      subtitle: 'Bergabung ke workshop yang ada sebagai Administrasi atau Teknisi ahli.',
                      badge: 'OPERASIONAL',
                      badgeColor: AppColors.neonGreen,
                      onTap: () => _showJoinDialog(context, isDark),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Identitas akun tidak sesuai?',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => ref.read(authServiceProvider).signOut(),
                            child: Text(
                              'Log Out dari Akun',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.precisionViolet..withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceLow : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Gabung ke Workshop',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : AppColors.obsidianBase,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan ID Workshop dan Kode PIN otentikasi yang diberikan oleh Owner.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    TextField(
                      controller: _joinController,
                      decoration: InputDecoration(
                        labelText: 'ID Workshop',
                        hintText: 'Contoh: PREMIUM-XXXXXX',
                        prefixIcon: const Icon(SolarIconsOutline.key),
                        errorText: _joinError,
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.precisionViolet, width: 2),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (_) => setModalState(() => _joinError = null),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _pinController,
                      obscureText: _obscurePin,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Kode PIN Workshop',
                        hintText: '6 digit angka sandi',
                        prefixIcon: const Icon(SolarIconsOutline.lock),
                        counterText: '',
                        errorText: _pinError,
                        suffixIcon: IconButton(
                          onPressed: () => setModalState(() => _obscurePin = !_obscurePin),
                          icon: Icon(
                            _obscurePin ? SolarIconsOutline.eyeClosed : SolarIconsOutline.eye,
                            size: 20,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.precisionViolet, width: 2),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                      ),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (_) => setModalState(() => _pinError = null),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isJoining
                    ? null
                    : () {
                        final id = _joinController.text.trim();
                        final pin = _pinController.text.trim();
                        if (id.isEmpty || pin.length != 6) {
                          setState(() {
                            _joinError = id.isEmpty ? 'ID Workshop wajib diisi' : null;
                            _pinError = pin.length != 6 ? 'PIN harus 6 digit' : null;
                          });
                          return;
                        }
                        _joinBengkel(id, pin);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.precisionViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  shadowColor: AppColors.precisionViolet.withValues(alpha: 0.3),
                ),
                child: _isJoining
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : Text(
                        'Konfirmasi & Bergabung',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinBengkel(String bengkelId, String pin) async {
    setState(() => _isJoining = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Sesi berakhir, silahkan login kembali.');
      
      await _bengkelService.joinBengkel(
        bengkelId: bengkelId,
        uid: user.uid,
        name: user.displayName ?? 'Staf',
        email: user.email ?? '',
        role: 'staff',
        pin: pin,
      );
      
      if (mounted) {
        ref.invalidate(authStateProvider);
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final err = e.toString().toLowerCase();
          if (err.contains('tidak ditemukan')) {
            _joinError = 'ID Workshop tidak valid';
          } else if (err.contains('pin salah')) {
            _pinError = 'PIN otentikasi salah';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sistem bermasalah: $e'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }
}

class _OptionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _OptionCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade200,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.manrope(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : AppColors.obsidianBase,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
