import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/pengaturan_provider.dart';

class OnboardingIntroScreen extends ConsumerStatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  ConsumerState<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends ConsumerState<OnboardingIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    ref.read(settingsProvider.notifier).setHasSeenOnboarding(true);
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidianBase : Colors.white,
      body: Stack(
        children: [
          // Background Aura
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.precisionViolet.withValues(alpha: isDark ? 0.05 : 0.03),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      _buildIntroPage(
                        isDark: isDark,
                        image: 'assets/illustrations/onboarding_mgmt.png',
                        title: 'Manajemen Bengkel\nDigital & Efisien',
                        subtitle: 'Kelola Inventaris, Teknisi, dan rincian Pendapatan dalam satu sistem terintegrasi.',
                      ),
                      _buildIntroPage(
                        isDark: isDark,
                        image: 'assets/illustrations/onboarding_security.png',
                        title: 'Keamanan Data\nStandar Korporat',
                        subtitle: 'Proteksi sesi perangkat dan enkripsi data cloud untuk ketenangan bisnis Anda.',
                      ),
                      _buildIntroPage(
                        isDark: isDark,
                        image: 'assets/illustrations/onboarding_sync.png',
                        title: 'Sinkronisasi Cloud\nReal-time',
                        subtitle: 'Akses data bengkel dari mana saja dengan sinkronisasi instan antar tim.',
                      ),
                    ],
                  ),
                ),

                // Bottom Content
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => _buildIndicator(index == _currentPage, isDark),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Buttons
                      Row(
                        children: [
                          if (_currentPage < 2)
                            TextButton(
                              onPressed: _finishOnboarding,
                              child: Text(
                                'Lewati',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                          const Spacer(),
                          
                          // Primary Action Button
                          GestureDetector(
                            onTap: _nextPage,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: EdgeInsets.symmetric(
                                horizontal: _currentPage == 2 ? 32 : 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.precisionViolet,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.precisionViolet.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage == 2 ? 'Mulai Sekarang' : 'Lanjut',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_currentPage < 2) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.precisionViolet 
            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildIntroPage({
    required bool isDark,
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration with Ambient Glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.precisionViolet.withValues(alpha: 0.1),
                      AppColors.precisionViolet.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Image.asset(
                image,
                height: 280,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppColors.obsidianBase,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
