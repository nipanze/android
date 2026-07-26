// lib/features/auth/presentation/pages/register_page.dart
//
// A single-page wizard that covers all auth entry-points described in the
// design mockups:
//
//   Step 0 – Welcome        (choose Phone or Email)
//   Step 1 – Phone entry    (dial-code prefix + number)
//   Step 2 – OTP            (6-digit pin, bypass-aware)
//   Step 3 – Profile setup  (name, email optional, country, password)
//   Step 4 – Success        ("You're in! 🎉")
//
//   Email path:
//   Step 5 – Email login    (email + password, "Forgot password?")
//
//   Returning-phone path:
//   Step 1 → 2 → (resolved) sign-in with password
//
// The wizard is driven entirely by [_WizardStep] — no Navigator pushes, so
// the GoRouter redirect for AuthAuthenticated still owns the exit-to-home.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/language_selector_sheet.dart';
import '../widgets/starfield_background.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step enum
// ─────────────────────────────────────────────────────────────────────────────
enum _WizardStep {
  welcome,        // 0
  phoneEntry,     // 1
  otp,            // 2 – OTP verification (bypass: any 6-digit)
  profileSetup,   // 3 – name / email (opt) / country / password
  success,        // 4 – "You're in!"
  emailLogin,     // 5 – classic email + password login
}

// ─────────────────────────────────────────────────────────────────────────────
// LoginPage
// ─────────────────────────────────────────────────────────────────────────────
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.startAtSignUp = false});

  /// When true the wizard starts at phoneEntry (used by RegisterPage redirect).
  final bool startAtSignUp;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  // ── wizard state ──────────────────────────────────────────────────────────
  late _WizardStep _step;
  final bool _isReturningUser = false;
  bool _isCheckingPhone = false;

  // ── phone step controllers ────────────────────────────────────────────────
  CountryInfo _selectedCountry = EastAfricaCountries.defaultCountry;
  final _phoneController = TextEditingController();

  // ── OTP step ─────────────────────────────────────────────────────────────
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  Timer? _resendTimer;
  int _resendSeconds = 0;

  // ── profile setup controllers ─────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _optEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  File? _avatarFile;

  // ── email login controllers ───────────────────────────────────────────────
  final _emailLoginController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  bool _obscureEmailPassword = true;

  // ── form keys ─────────────────────────────────────────────────────────────
  final _phoneFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  final _emailLoginFormKey = GlobalKey<FormState>();

  // ── animation ─────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _step = _WizardStep.phoneEntry; // Registration always starts at phone entry
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _nameController.dispose();
    _optEmailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailLoginController.dispose();
    _emailPasswordController.dispose();
    _resendTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _goTo(_WizardStep next) async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() => _step = next);
    unawaited(_fadeCtrl.forward());
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  String get _fullPhone =>
      '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

  String _otpValue() =>
      _otpControllers.map((c) => c.text).join();

  bool _isOtpValid() {
    final val = _otpValue();
    return val.length == 6 && RegExp(r'^\d{6}$').hasMatch(val);
  }

  void _prefillDefaultOtp() {
    const defaultOtp = '123456';
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = defaultOtp[i];
    }
  }

  void _clearOtp() {
    _prefillDefaultOtp();
    _otpFocusNodes.first.requestFocus();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Phone flow: after user taps "Send Code"
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onSendCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _isCheckingPhone = true);
    final bloc = context.read<AuthBloc>();
    final phone = _fullPhone;

    final resolvedEmail =
        await bloc.state.repository?.checkPhoneRegistered(phone);
    if (mounted) {
      setState(() => _isCheckingPhone = false);
    }
    if (!mounted) return;

    if (resolvedEmail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'This phone number is already registered. Please log in instead.',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Log In',
            textColor: Colors.white,
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
      );
      return;
    }

    // New user → proceed to OTP
    _prefillDefaultOtp();
    _startResendTimer();
    await _goTo(_WizardStep.otp);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OTP flow: user taps "Verify"
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onVerifyOtp() async {
    if (!_isOtpValid()) return;
    await _goTo(_WizardStep.profileSetup);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile setup submit
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onProfileSubmit() async {
    if (!_profileFormKey.currentState!.validate()) return;

    final optEmail = _optEmailController.text.trim();
    if (optEmail.isNotEmpty) {
      final bloc = context.read<AuthBloc>();
      final existingEmail =
          await bloc.state.repository?.checkPhoneRegistered(optEmail);
      if (!mounted) return;
      if (existingEmail != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'This email address is already registered. Please use another email or log in.',
              style: TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Log In',
              textColor: Colors.white,
              onPressed: () => context.go(AppRoutes.login),
            ),
          ),
        );
        return;
      }
    }

    // New user: register
    context.read<AuthBloc>().add(AuthPhoneSignUpRequested(
          phone: _fullPhone,
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          countryCode: _selectedCountry.code,
          email: optEmail.isEmpty ? null : optEmail,
        ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Avatar picker
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F101C) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF9E9EB8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF181928) : const Color(0xFFF1F5F9);
    final cardBorder =
        isDark ? const Color(0xFF28293D) : const Color(0xFFE2E8F0);
    const purple = Color(0xFF7C3AED);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: cardBorder),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2D2D42)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose photo',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select where to pick your profile photo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: purple.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Take a photo',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor)),
                          Text('Use your camera',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: subtitleColor)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF7C3AED), size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.photo_library_rounded,
                          color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Choose from gallery',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor)),
                          Text('Pick an existing photo',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: subtitleColor)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: subtitleColor, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked != null && mounted) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Email login submit
  // ─────────────────────────────────────────────────────────────────────────
  void _onEmailLoginSubmit() {
    if (!_emailLoginFormKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthSignInRequested(
          email: _emailLoginController.text.trim(),
          password: _emailPasswordController.text,
        ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWelcome = _step == _WizardStep.welcome;
    return Scaffold(
      backgroundColor: isWelcome ? const Color(0xFF0A0A12) : null,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // GoRouterRefreshStream handles redirect; we just jump to success
            // only if we're mid-wizard (not yet on success screen).
            if (_step != _WizardStep.success) {
              _goTo(_WizardStep.success);
            }
          }
          // Error is displayed inline per-step
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final errorMsg = state is AuthError ? state.message : null;

          final step = _buildStep(isLoading, errorMsg);
          // Welcome screen handles its own SafeArea + full-bleed gradient
          if (isWelcome) {
            return FadeTransition(opacity: _fadeAnim, child: step);
          }
          return SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: step,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(bool isLoading, String? errorMsg) {
    return switch (_step) {
      _WizardStep.welcome => _WelcomeScreen(
          onContinueWithPhone: () => _goTo(_WizardStep.phoneEntry),
          onContinueWithEmail: () => _goTo(_WizardStep.emailLogin),
          onCreateAccount: () => _goTo(_WizardStep.phoneEntry),
        ),
      _WizardStep.phoneEntry => _PhoneEntryScreen(
          formKey: _phoneFormKey,
          selectedCountry: _selectedCountry,
          controller: _phoneController,
          isLoading: isLoading || _isCheckingPhone,
          onCountryTap: _showCountrySheet,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.welcome);
            }
          },
          onNext: _onSendCode,
        ),
      _WizardStep.otp => _OtpScreen(
          phone: _fullPhone,
          isReturningUser: _isReturningUser,
          controllers: _otpControllers,
          focusNodes: _otpFocusNodes,
          isLoading: isLoading,
          resendSeconds: _resendSeconds,
          errorMsg: errorMsg,
          onBack: () => _goTo(_WizardStep.phoneEntry),
          onVerify: _onVerifyOtp,
          onResend: () {
            _clearOtp();
            _startResendTimer();
          },
        ),
      _WizardStep.profileSetup => _ProfileSetupScreen(
          isReturningUser: _isReturningUser,
          nameController: _nameController,
          emailController: _optEmailController,
          passwordController: _passwordController,
          confirmController: _confirmController,
          obscurePassword: _obscurePassword,
          obscureConfirm: _obscureConfirm,
          formKey: _profileFormKey,
          isLoading: isLoading,
          errorMsg: errorMsg,
          onTogglePassword: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onToggleConfirm: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          avatarFile: _avatarFile,
          onPickAvatar: _pickAvatar,
          onBack: () => _goTo(_WizardStep.otp),
          onSubmit: _onProfileSubmit,
        ),
      _WizardStep.success => _SuccessScreen(
          onGoToMarketplace: () => context.go(AppRoutes.marketplace),
        ),
      _WizardStep.emailLogin => _EmailLoginScreen(
          formKey: _emailLoginFormKey,
          emailController: _emailLoginController,
          passwordController: _emailPasswordController,
          obscurePassword: _obscureEmailPassword,
          isLoading: isLoading,
          errorMsg: errorMsg,
          onTogglePassword: () =>
              setState(() => _obscureEmailPassword = !_obscureEmailPassword),
          onBack: () => _goTo(_WizardStep.welcome),
          onSubmit: _onEmailLoginSubmit,
          onForgotPassword: () => context.push(AppRoutes.resetPassword),
          onCreateAccount: () => _goTo(_WizardStep.phoneEntry),
        ),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Country selection bottom sheet
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _showCountrySheet() async {
    final picked = await showModalBottomSheet<CountryInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountrySheet(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedCountry = picked;
      });
    }
  }
}

// Extension so we can pass a nullable repo from state (not really used)
extension on AuthState {
  dynamic get repository => null;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ── 0. Welcome ───────────────────────────────────────────────────────────────
class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({
    required this.onContinueWithPhone,
    required this.onContinueWithEmail,
    required this.onCreateAccount,
  });

  final VoidCallback onContinueWithPhone;
  final VoidCallback onContinueWithEmail;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    final bgColor = isDark ? const Color(0xFF06080E) : const Color(0xFFFFFFFF);

    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
    final footerTextColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF475569);
    final footerLinkColor =
        isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);

    return Container(
      width: double.infinity,
      height: size.height,
      decoration: BoxDecoration(
        color: bgColor,
      ),
      // Stack lets the starfield/continent silhouette sit behind everything
      // without disturbing the existing Column layout below.
      child: Stack(
        children: [
          StarfieldBackground(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                // ── Top: Logo ─────────────────────────────────────────────
                const SizedBox(height: 16),
                _NipanzeLogo(),

                // ── Hero copy ─────────────────────────────────────────────
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Borrow. Lend. Grow.\nAcross East Africa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'A trusted marketplace connecting\nborrowers with lenders.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: subtitleColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Hero illustration ─────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.25, 0.75, 1.0],
                      ).createShader(rect),
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        isDark
                            ? 'assets/images/hero_illustration_dark.png'
                            : 'assets/images/hero_illustration_light.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // ── CTA + footer ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 50),
                  child: Column(
                    children: [
                      // Primary CTA
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: onContinueWithPhone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 20),
                          label: const Text(
                            'Continue with Phone',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Terms footer
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                       
                            const SizedBox(width: 8),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: footerTextColor,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(
                                      text:
                                          'By continuing, you agree to our\n'),
                                  TextSpan(
                                    text: 'Terms of Use',
                                    style: TextStyle(
                                      color: footerLinkColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: footerLinkColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
}

// ── Nipanze logo image ────────────────────────────────────────────────────────
class _NipanzeLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/nipanze_logo.png',
      height: 110,
      fit: BoxFit.contain,
    );
  }
}


// ── 1. Phone Entry ────────────────────────────────────────────────────────────
class _PhoneEntryScreen extends StatelessWidget {
  const _PhoneEntryScreen({
    required this.formKey,
    required this.selectedCountry,
    required this.controller,
    required this.isLoading,
    required this.onCountryTap,
    required this.onBack,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final CountryInfo selectedCountry;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onCountryTap;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
    final cardBgColor =
        isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
    final cardBorderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Header: Back button + 3-step progress bar ────────────────
                    _StepProgressHeader(onBack: onBack, currentStep: 1),
                    const SizedBox(height: 36),

                    // ── Titles ─────────────────────────────────────────────────
                    Text(
                      'Enter your phone number',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'ll send you a verification code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Phone Input Field Card ─────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorderColor),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          // Country selector chip
                          GestureDetector(
                            onTap: onCountryTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    selectedCountry.flag,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedCountry.dialCode,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: subtitleColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Vertical divider line
                          Container(
                            height: 28,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            color: cardBorderColor,
                          ),
                          // Phone input
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: titleColor,
                              ),
                              onFieldSubmitted: (_) => onNext(),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                hintText: '7XXXXXXXX',
                                hintStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  color: isDark
                                      ? const Color(0xFF4B5563)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().length < 7) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Security Callout Card ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFFA78BFA),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your number is safe with us',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'We never share your number with anyone.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 24),

                    // ── Primary Action Button ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF7C3AED).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const _ButtonLoader()
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// ── 2. OTP ────────────────────────────────────────────────────────────────────
class _OtpScreen extends StatelessWidget {
  const _OtpScreen({
    required this.phone,
    required this.isReturningUser,
    required this.controllers,
    required this.focusNodes,
    required this.isLoading,
    required this.resendSeconds,
    required this.errorMsg,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
  });

  final String phone;
  final bool isReturningUser;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isLoading;
  final int resendSeconds;
  final String? errorMsg;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Header: Back button + Step 2 indicator ─────────────────
                  _StepProgressHeader(onBack: onBack, currentStep: 2),
                  const SizedBox(height: 36),

                  // ── Titles ─────────────────────────────────────────────────
                  Text(
                    isReturningUser ? 'Welcome back 👋' : 'Verify your number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone.isNotEmpty ? phone : '+256 7XX XXX XXX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Demo hint ─────────────────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text(
                          'Demo mode: default OTP is 123456 (pre-filled).',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── 6-Digit OTP Box Row ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (i) => _OtpBox(
                        controller: controllers[i],
                        focusNode: focusNodes[i],
                        nextFocus: i < 5 ? focusNodes[i + 1] : null,
                        prevFocus: i > 0 ? focusNodes[i - 1] : null,
                        onComplete: i == 5 ? onVerify : null,
                      ),
                    ),
                  ),

                  if (errorMsg != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: errorMsg!),
                  ],

                  const SizedBox(height: 32),

                  // ── Resend Code Countdown Line ─────────────────────────────
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                      children: [
                        const TextSpan(text: "Didn't receive code? "),
                        if (resendSeconds > 0) ...[
                          const TextSpan(
                            text: 'Resend',
                            style: TextStyle(
                              color: Color(0xFFA78BFA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' in 00:${resendSeconds.toString().padLeft(2, '0')}',
                            style: TextStyle(color: subtitleColor),
                          ),
                        ] else ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: onResend,
                              child: const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFFA78BFA),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 24),

                  // ── Primary Action Button ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF7C3AED).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const _ButtonLoader()
                          : const Text(
                              'Verify & Continue',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

// OTP single box with dynamic focus & border highlights
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    this.prevFocus,
    this.onComplete,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final FocusNode? prevFocus;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBgColor =
        isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
    final cardBorderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        final hasValue = controller.text.isNotEmpty;
        final isActive = isFocused || hasValue;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 58,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? const Color(0xFF7C3AED) : cardBorderColor,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              cursorColor: const Color(0xFF7C3AED),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
              onChanged: (v) {
                if (v.length == 1) {
                  if (nextFocus != null) {
                    nextFocus!.requestFocus();
                  } else {
                    onComplete?.call();
                  }
                } else if (v.isEmpty && prevFocus != null) {
                  prevFocus!.requestFocus();
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ── 3. Profile Setup ──────────────────────────────────────────────────────────
class _ProfileSetupScreen extends StatelessWidget {
  const _ProfileSetupScreen({
    required this.isReturningUser,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.formKey,
    required this.isLoading,
    required this.errorMsg,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onBack,
    required this.onSubmit,
    this.avatarFile,
    this.onPickAvatar,
  });

  final bool isReturningUser;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final File? avatarFile;
  final VoidCallback? onPickAvatar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
    final cardBgColor =
        isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
    final cardBorderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: IntrinsicHeight(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Header ─────────────────────────────────────────────
                    _StepProgressHeader(onBack: onBack, currentStep: 3),
                    const SizedBox(height: 24),

                    // ── Titles ─────────────────────────────────────────────
                    Text(
                      isReturningUser
                          ? 'Enter your password'
                          : 'Tell us about you',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isReturningUser
                          ? 'Login to your account'
                          : 'Create your profile & set a password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),

                    if (!isReturningUser) ...[
                      const SizedBox(height: 20),

                      // ── Avatar Picker ───────────────────────────────────
                      GestureDetector(
                        onTap: onPickAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF7C3AED),
                                  width: 2.5,
                                ),
                                color: cardBgColor,
                                image: avatarFile != null
                                    ? DecorationImage(
                                        image: FileImage(avatarFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: avatarFile == null
                                  ? const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 30,
                                      color: Color(0xFF7C3AED),
                                    )
                                  : null,
                            ),
                            // Edit badge
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cardBgColor,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (errorMsg != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: errorMsg!),
                    ],
                    const SizedBox(height: 20),

                    if (!isReturningUser) ...[
                      // Full Name
                      _ProfileField(
                        label: 'Full name',
                        controller: nameController,
                        icon: Icons.person_outline_rounded,
                        hintText: 'John Doe',
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        cardBorderColor: cardBorderColor,
                        titleColor: titleColor,
                        subtitleColor: subtitleColor,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Email (optional)
                      _ProfileField(
                        label: 'Email (optional)',
                        controller: emailController,
                        icon: Icons.mail_outline_rounded,
                        hintText: 'johndoe@gmail.com',
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        cardBorderColor: cardBorderColor,
                        titleColor: titleColor,
                        subtitleColor: subtitleColor,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password creation
                      _ProfileField(
                        label: 'Create password',
                        controller: passwordController,
                        icon: Icons.lock_outline_rounded,
                        hintText: '••••••••',
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        cardBorderColor: cardBorderColor,
                        titleColor: titleColor,
                        subtitleColor: subtitleColor,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: subtitleColor,
                          ),
                          onPressed: onTogglePassword,
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      _ProfileField(
                        label: 'Confirm password',
                        controller: confirmController,
                        icon: Icons.lock_outline_rounded,
                        hintText: '••••••••',
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        cardBorderColor: cardBorderColor,
                        titleColor: titleColor,
                        subtitleColor: subtitleColor,
                        obscureText: obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => onSubmit(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: subtitleColor,
                          ),
                          onPressed: onToggleConfirm,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirm your password';
                          }
                          if (v != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      // Returning user password field only
                      _ProfileField(
                        label: 'Password',
                        controller: passwordController,
                        icon: Icons.lock_outline_rounded,
                        hintText: '••••••••',
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        cardBorderColor: cardBorderColor,
                        titleColor: titleColor,
                        subtitleColor: subtitleColor,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => onSubmit(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: subtitleColor,
                          ),
                          onPressed: onTogglePassword,
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                    ],

                    const Spacer(),
                    const SizedBox(height: 24),

                    // ── Action Button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF7C3AED).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const _ButtonLoader()
                            : Text(
                                isReturningUser ? 'Sign in' : 'Finish',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Reusable styled input field used by the Profile Setup screen.
class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hintText,
    required this.isDark,
    required this.cardBgColor,
    required this.cardBorderColor,
    required this.titleColor,
    required this.subtitleColor,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool isDark;
  final Color cardBgColor;
  final Color cardBorderColor;
  final Color titleColor;
  final Color subtitleColor;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: subtitleColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: titleColor,
          ),
          cursorColor: const Color(0xFF7C3AED),
          decoration: InputDecoration(
            filled: true,
            fillColor: cardBgColor,
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(icon, size: 18, color: subtitleColor),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFFEF4444), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}



// ── 5. Success ────────────────────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.onGoToMarketplace});
  final VoidCallback onGoToMarketplace;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
    final cardBgColor =
        isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
    final cardBorderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // ── Big green checkmark ───────────────────────────────────────
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF22C55E),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF22C55E),
                size: 60,
              ),
            ),
            const SizedBox(height: 32),

            // ── Title ─────────────────────────────────────────────────────
            Text(
              "You're in! 🎉",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: titleColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your account has been created\nsuccessfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // ── Feature cards ─────────────────────────────────────────────
            _SuccessFeatureCard(
              icon: Icons.people_alt_rounded,
              iconBgColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              iconColor: const Color(0xFFA78BFA),
              title: 'Explore loan requests',
              subtitle: 'Find borrowers and lenders\nin your country.',
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            const SizedBox(height: 12),
            _SuccessFeatureCard(
              icon: Icons.verified_user_rounded,
              iconBgColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
              iconColor: const Color(0xFF22C55E),
              title: 'Safe & secure',
              subtitle: 'We protect your data and\ntransactions.',
              cardBgColor: cardBgColor,
              cardBorderColor: cardBorderColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),

            const Spacer(),
            const SizedBox(height: 8),

            // ── CTA button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onGoToMarketplace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Go to Marketplace',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SuccessFeatureCard extends StatelessWidget {
  const _SuccessFeatureCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.cardBgColor,
    required this.cardBorderColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color cardBgColor;
  final Color cardBorderColor;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: subtitleColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ── 5. Email Login ────────────────────────────────────────────────────────────
class _EmailLoginScreen extends StatelessWidget {
  const _EmailLoginScreen({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMsg,
    required this.onTogglePassword,
    required this.onBack,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onCreateAccount,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onTogglePassword;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackHeader(onBack: onBack),
            const SizedBox(height: 16),
            const AuthBrandMark(),
            const SizedBox(height: 28),
            Text('Welcome back 👋',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            Text('Login to your account',
                style: theme.textTheme.bodyMedium),
            if (errorMsg != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: errorMsg!),
            ],
            const SizedBox(height: 28),

            AuthField(
              fieldKey: const Key('email_field'),
              label: 'Email',
              controller: emailController,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            AuthField(
              fieldKey: const Key('password_field'),
              label: 'Password',
              controller: passwordController,
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 17,
                ),
                onPressed: onTogglePassword,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                return null;
              },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),

            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child:
                  isLoading ? const _ButtonLoader() : const Text('Sign in'),
            ),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(child: Divider(color: theme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child:
                    Text('new here', style: theme.textTheme.bodySmall),
              ),
              Expanded(child: Divider(color: theme.dividerColor)),
            ]),
            const SizedBox(height: 16),

            AuthSecondaryButton(
              label: 'Create an account',
              onPressed: onCreateAccount,
            ),
            const SizedBox(height: 28),

            Text(
              'Nipanze is a technology marketplace. We do not hold, pool, or move your funds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country Selection Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CountrySheet extends StatefulWidget {
  const _CountrySheet();

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _query = '';

  List<CountryInfo> get _filtered => EastAfricaCountries.all
      .where((c) =>
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.dialCode.contains(_query) ||
          c.code.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Select Country',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search country…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final c = _filtered[i];
                    return ListTile(
                      leading: Text(c.flag,
                          style: const TextStyle(fontSize: 26)),
                      title: Text(c.name,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                      subtitle: Text(c.dialCode,
                          style: theme.textTheme.bodySmall),
                      trailing: Text(c.currency,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.accentDark,
                              fontWeight: FontWeight.w600)),
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────
class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _StepProgressHeader extends StatelessWidget {
  const _StepProgressHeader({
    required this.onBack,
    required this.currentStep,
  });

  final VoidCallback onBack;
  final int currentStep;
  static const int totalSteps = 3;


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final stepNumber = index + 1;
              final isActive = stepNumber == currentStep;
              return Container(
                width: 32,
                height: 4,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF7C3AED)
                      : (isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
        ValueListenableBuilder<Locale?>(
          valueListenable: LanguageService.instance.notifier,
          builder: (context, _, __) {
            final currentLang = LanguageService.instance.currentLanguage;
            final cardBgColor = isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
            final cardBorderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
            final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final subtitleColor = isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
            return GestureDetector(
              onTap: () => showLanguageSelectorSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currentLang.flag, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 3),
                    Text(
                      currentLang.code.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: subtitleColor,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}


class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonLoader extends StatelessWidget {
  const _ButtonLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}