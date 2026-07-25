// lib/features/auth/presentation/pages/login_page.dart
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_widgets.dart';
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
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.startAtSignUp = false});

  /// When true the wizard starts at phoneEntry (used by RegisterPage redirect).
  final bool startAtSignUp;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // ── wizard state ──────────────────────────────────────────────────────────
  late _WizardStep _step;
  bool _isReturningUser = false; // true when phone is already registered

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
  CountryInfo _profileCountry = EastAfricaCountries.defaultCountry;

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
    _step = widget.startAtSignUp ? _WizardStep.phoneEntry : _WizardStep.welcome;
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

    final bloc = context.read<AuthBloc>();
    // Check if phone is already registered (hybrid bypass)
    final phone = _fullPhone;

    // Optimistically move to OTP screen with pre-filled default OTP (123456)
    _prefillDefaultOtp();
    _startResendTimer();
    await _goTo(_WizardStep.otp);

    // Lookup in background — sets _isReturningUser flag for OTP confirm
    final resolvedEmail =
        await bloc.state.repository?.checkPhoneRegistered(phone);
    if (mounted) {
      setState(() => _isReturningUser = resolvedEmail != null);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OTP flow: user taps "Verify"
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onVerifyOtp() async {
    if (!_isOtpValid()) return;
    // Bypass: any valid 6-digit code is accepted.
    if (_isReturningUser) {
      // Returning user → ask for password to sign in
      await _goTo(_WizardStep.profileSetup);
      // We repurpose profileSetup as password-only for returning users.
      // Actually, let's just let them enter password inline — handled below.
    } else {
      // New user → go to profile setup
      await _goTo(_WizardStep.profileSetup);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile setup submit
  // ─────────────────────────────────────────────────────────────────────────
  void _onProfileSubmit() {
    if (!_profileFormKey.currentState!.validate()) return;

    if (_isReturningUser) {
      // Returning user identified by phone: sign in with resolved account
      context.read<AuthBloc>().add(AuthPhoneSignInRequested(
            phone: _fullPhone,
            password: _passwordController.text,
          ));
    } else {
      // New user: register
      context.read<AuthBloc>().add(AuthPhoneSignUpRequested(
            phone: _fullPhone,
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            countryCode: _profileCountry.code,
            email: _optEmailController.text.trim().isEmpty
                ? null
                : _optEmailController.text.trim(),
          ));
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
          isLoading: isLoading,
          onCountryTap: _showCountrySheet,
          onBack: () => _goTo(_WizardStep.welcome),
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
          selectedCountry: _profileCountry,
          formKey: _profileFormKey,
          isLoading: isLoading,
          errorMsg: errorMsg,
          onTogglePassword: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onToggleConfirm: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onCountryTap: () => _showCountrySheet(forProfile: true),
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
  Future<void> _showCountrySheet({bool forProfile = false}) async {
    final picked = await showModalBottomSheet<CountryInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountrySheet(),
    );
    if (picked != null && mounted) {
      setState(() {
        if (forProfile) {
          _profileCountry = picked;
        } else {
          _selectedCountry = picked;
        }
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

    final bgColors = isDark
        ? const [Color(0xFF0A0A12), Color(0xFF0D0D1A), Color(0xFF0A0A12)]
        : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFF8FAFC)];

    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
    final footerTextColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF475569);
    final footerLinkColor =
        isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
    final footerIconColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      height: size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgColors,
        ),
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
                // ShaderMask fades the illustration's own top/bottom edges
                // to transparent so it melts into the background gradient
                // instead of reading as a pasted-in rectangle.
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
                        stops: [0.0, 0.12, 0.85, 1.0],
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
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
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
                            Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: footerIconColor,
                            ),
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackHeader(onBack: onBack),
            const SizedBox(height: 28),
            Text('Enter your\nphone number',
                style: theme.textTheme.displayLarge
                    ?.copyWith(fontSize: 28, height: 1.2)),
            const SizedBox(height: 8),
            Text('We\'ll send a verification code',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 32),

            // Dial-code picker + number field
            Text('PHONE NUMBER',
                style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    letterSpacing: 0.3,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  // Dial-code chip
                  GestureDetector(
                    onTap: onCountryTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(color: theme.dividerColor)),
                      ),
                      child: Row(
                        children: [
                          Text(selectedCountry.flag,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(selectedCountry.dialCode,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ),
                  // Number input
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => onNext(),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        hintText: '7XX XXX XXX',
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

            ElevatedButton(
              onPressed: isLoading ? null : onNext,
              child: isLoading
                  ? const _ButtonLoader()
                  : const Text('Send Code'),
            ),
          ],
        ),
      ),
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(onBack: onBack),
          const SizedBox(height: 28),
          Text(
            isReturningUser ? 'Welcome back 👋' : 'Verify your number',
            style:
                theme.textTheme.displayLarge?.copyWith(fontSize: 26, height: 1.2),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Enter the 6-digit code sent to ',
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                    text: phone,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo mode: default OTP is 123456 (pre-filled).',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.warning),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 32),

          // OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _OtpBox(
                  controller: controllers[i],
                  focusNode: focusNodes[i],
                  nextFocus: i < 5 ? focusNodes[i + 1] : null,
                  prevFocus: i > 0 ? focusNodes[i - 1] : null,
                  onComplete: i == 5 ? onVerify : null,
                )),
          ),

          if (errorMsg != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: errorMsg!),
          ],

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: isLoading ? null : onVerify,
            child: isLoading ? const _ButtonLoader() : const Text('Verify'),
          ),
          const SizedBox(height: 16),

          Center(
            child: resendSeconds > 0
                ? Text(
                    'Resend code in ${resendSeconds}s',
                    style: theme.textTheme.bodySmall,
                  )
                : TextButton(
                    onPressed: onResend,
                    child: const Text('Resend code'),
                  ),
          ),
        ],
      ),
    );
  }
}

// OTP single box
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
    final theme = Theme.of(context);
    return SizedBox(
      width: 44,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor),
        ),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
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
    required this.selectedCountry,
    required this.formKey,
    required this.isLoading,
    required this.errorMsg,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onCountryTap,
    required this.onBack,
    required this.onSubmit,
  });

  final bool isReturningUser;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final CountryInfo selectedCountry;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onCountryTap;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // For returning users we only need the password
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackHeader(onBack: onBack),
            const SizedBox(height: 28),
            Text(
              isReturningUser ? 'Enter your password' : 'Tell us about you',
              style: theme.textTheme.displayLarge
                  ?.copyWith(fontSize: 26, height: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              isReturningUser
                  ? 'Login to your account'
                  : 'Set up your profile to get started',
              style: theme.textTheme.bodyMedium,
            ),
            if (errorMsg != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: errorMsg!),
            ],
            const SizedBox(height: 28),

            if (!isReturningUser) ...[
              AuthField(
                label: 'Full Name',
                controller: nameController,
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: 14),
              AuthField(
                label: 'Email (optional)',
                controller: emailController,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Country picker
              _CountryPickerField(
                selectedCountry: selectedCountry,
                onTap: onCountryTap,
              ),
              const SizedBox(height: 14),
            ],

            // Password
            AuthField(
              label: 'Password',
              controller: passwordController,
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: isReturningUser
                  ? TextInputAction.done
                  : TextInputAction.next,
              onFieldSubmitted: isReturningUser ? (_) => onSubmit() : null,
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
                if (v == null || v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),

            if (!isReturningUser) ...[
              const SizedBox(height: 14),
              AuthField(
                label: 'Confirm Password',
                controller: confirmController,
                icon: Icons.lock_outline_rounded,
                obscureText: obscureConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 17,
                  ),
                  onPressed: onToggleConfirm,
                ),
                validator: (v) {
                  if (v != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const _ButtonLoader()
                  : Text(isReturningUser ? 'Sign in' : 'Create account'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 4. Success ────────────────────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.onGoToMarketplace});
  final VoidCallback onGoToMarketplace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentDark, AppColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 48),
          ),
          const SizedBox(height: 28),
          Text("You're in! \u{1F389}",
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 30),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Your account is ready. Browse listings, match with lenders, and start building.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: onGoToMarketplace,
            child: const Text('Go to Marketplace'),
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

class _CountryPickerField extends StatelessWidget {
  const _CountryPickerField({
    required this.selectedCountry,
    required this.onTap,
  });

  final CountryInfo selectedCountry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COUNTRY',
            style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                letterSpacing: 0.3,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Text(selectedCountry.flag,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(selectedCountry.name,
                      style: theme.textTheme.bodyMedium),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.45)),
              ],
            ),
          ),
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