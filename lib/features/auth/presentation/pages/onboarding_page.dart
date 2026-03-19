// lib/features/auth/presentation/pages/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.account_balance_wallet_outlined,
      accentColor: AppColors.accent,
      title: 'Lend Your\nIdle Capital',
      body:
          'Put your savings to work. Fund real borrowers in Uganda and earn competitive returns — directly, with no middlemen.',
      tag: 'FOR LENDERS',
    ),
    _OnboardingSlide(
      icon: Icons.trending_up_rounded,
      accentColor: AppColors.primary,
      title: 'Borrow on\nYour Terms',
      body:
          'Set your own rate. Get funded by multiple lenders in days, not weeks. No collateral, no branch visits.',
      tag: 'FOR BORROWERS',
    ),
    _OnboardingSlide(
      icon: Icons.shield_outlined,
      accentColor: AppColors.tierPlatinum,
      title: 'Non-Custodial.\nAlways Yours.',
      body:
          'We never hold your funds. Every shilling flows peer-to-peer through verified accounts, audited in real time.',
      tag: 'BUILT FOR TRUST',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _fadeController.reset();
    setState(() => _currentPage = index);
    _fadeController.forward();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/auth/login');
    }
  }

  void _skip() => context.go('/auth/login');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ───────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: isLast ? null : _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              ),
            ),

            // ── Page view ─────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (_, index) => _SlidePage(
                  slide: _slides[index],
                  isActive: index == _currentPage,
                  fadeAnimation: _fadeAnimation,
                ),
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? slide.accentColor
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Primary CTA
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: slide.accentColor,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () => context.go('/auth/login'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
    );
  }
}

// ── Slide data model ────────────────────────────────────────────────────────

class _OnboardingSlide {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String body;
  final String tag;

  const _OnboardingSlide({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.body,
    required this.tag,
  });
}

// ── Single slide widget ─────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _OnboardingSlide slide;
  final bool isActive;
  final Animation<double> fadeAnimation;

  const _SlidePage({
    required this.slide,
    required this.isActive,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        // Clamp so the card never dominates on small screens
        final cardHeight = (h * 0.38).clamp(140.0, 260.0);
        final topGap     = (h * 0.04).clamp(8.0,  28.0);
        final midGap     = (h * 0.04).clamp(8.0,  28.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: FadeTransition(
            opacity: isActive ? fadeAnimation : const AlwaysStoppedAnimation(1),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topGap),

                  // ── Illustration card ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: slide.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: slide.accentColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: slide.accentColor.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                        ),
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: slide.accentColor.withValues(alpha: 0.18),
                              width: 1,
                            ),
                          ),
                        ),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: slide.accentColor.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide.icon,
                            size: 40,
                            color: slide.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: midGap),

                  // ── Tag ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: slide.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      slide.tag,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: slide.accentColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Title ─────────────────────────────────────────────
                  Text(
                    slide.title,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Body ──────────────────────────────────────────────
                  Text(
                    slide.body,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}