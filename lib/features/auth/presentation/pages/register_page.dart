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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../referrals/presentation/cubit/referral_cubit.dart';
import '../../data/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import 'register/country_sheet.dart';
import 'register/email_login_screen.dart';
import 'register/otp_screen.dart';
import 'register/phone_entry_screen.dart';
import 'register/profile_setup_screen.dart';
import 'register/success_screen.dart';
import 'register/welcome_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step enum
// ─────────────────────────────────────────────────────────────────────────────
enum _WizardStep {
  welcome, // 0
  phoneEntry, // 1
  otp, // 2 – OTP verification (bypass: any 6-digit)
  profileSetup, // 3 – name / email (opt) / country / password
  success, // 4 – "You're in!"
  emailLogin, // 5 – classic email + password login
}

// ─────────────────────────────────────────────────────────────────────────────
// LoginPage
// ─────────────────────────────────────────────────────────────────────────────
class RegisterPage extends StatefulWidget {
  const RegisterPage(
      {super.key, this.startAtSignUp = false, this.referralCode});

  /// When true the wizard starts at phoneEntry (used by RegisterPage redirect).
  final bool startAtSignUp;
  final String? referralCode;

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
  final _referralCodeController = TextEditingController();
  late final ReferralCubit _referralCubit;
  ReferralCodeValidationState _referralValidation =
      const ReferralCodeValidationState();
  Timer? _referralValidationTimer;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  Uint8List? _avatarBytes;

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
    _referralCubit = getIt<ReferralCubit>();
    _referralCodeController.addListener(_scheduleReferralValidation);
    unawaited(_loadReferralCode());
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
    _referralCodeController.dispose();
    _referralValidationTimer?.cancel();
    _referralCubit.close();
    _emailLoginController.dispose();
    _emailPasswordController.dispose();
    _resendTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final incoming = widget.referralCode?.trim();
    final cached = prefs.getString('pending_referral_code')?.trim();
    final code = incoming?.isNotEmpty == true ? incoming : cached;
    if (code == null || code.isEmpty) return;
    await prefs.setString('pending_referral_code', code);
    if (!mounted) return;
    _referralCodeController.text = code.toUpperCase();
  }

  void _scheduleReferralValidation() {
    final code = _referralCodeController.text.trim();
    _referralValidationTimer?.cancel();
    if (code.isEmpty) {
      if (_referralValidation.status != ReferralValidationStatus.initial) {
        setState(
            () => _referralValidation = const ReferralCodeValidationState());
      }
      return;
    }

    setState(() {
      _referralValidation = const ReferralCodeValidationState(
        status: ReferralValidationStatus.validating,
        message: 'Checking referral code...',
      );
    });

    _referralValidationTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_validateReferralCode(code));
    });
  }

  Future<ReferralCodeValidationState> _validateReferralCode(String code) async {
    final validation = await _referralCubit.validateReferralCode(code);
    if (!mounted) return validation;
    if (_referralCodeController.text.trim() == code) {
      setState(() => _referralValidation = validation);
    }
    return validation;
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

  String _otpValue() => _otpControllers.map((c) => c.text).join();

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
    final authRepository = getIt<AuthRepository>();
    final phone = _fullPhone;

    final resolvedEmail = await authRepository.checkPhoneRegistered(phone);
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
      final existingEmail =
          await getIt<AuthRepository>().checkLoginRegistered(optEmail);
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

    final referralCode = _referralCodeController.text.trim();
    if (referralCode.isNotEmpty) {
      final validation = _referralValidation.isValid
          ? _referralValidation
          : await _validateReferralCode(referralCode);
      if (!mounted) return;
      if (!validation.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message ?? 'Referral code is invalid.'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
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
          referralCode: referralCode.isEmpty ? null : referralCode,
          avatarBytes: _avatarBytes,
        ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Avatar picker
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F101C) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF9E9EB8) : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF181928) : const Color(0xFFF1F5F9);
    final cardBorder =
        isDark ? const Color(0xFF28293D) : const Color(0xFFE2E8F0);
    const purple = AppColors.accent;

    final option = await showModalBottomSheet<String>(
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
                color:
                    isDark ? const Color(0xFF2D2D42) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n?.choosePhoto ?? 'Choose photo',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n?.selectPhotoSource ??
                  'Select where to pick your profile photo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => Navigator.pop(ctx, 'camera'),
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
                          Text(l10n?.takePhoto ?? 'Take a photo',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor)),
                          Text(l10n?.useCamera ?? 'Use your camera',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: subtitleColor)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.accent, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => Navigator.pop(ctx, 'gallery'),
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
                          color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n?.chooseFromGallery ?? 'Choose from gallery',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor)),
                          Text(
                              l10n?.pickExistingPhoto ??
                                  'Pick an existing photo',
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
            if (_avatarBytes != null) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => Navigator.pop(ctx, 'remove'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n?.removePhoto ?? 'Remove photo',
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger)),
                            Text(
                                l10n?.removePhotoSubtitle ??
                                    'Delete current profile picture',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: subtitleColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (option == null || !mounted) return;

    if (option == 'remove') {
      setState(() => _avatarBytes = null);
      return;
    }

    final source =
        option == 'camera' ? ImageSource.camera : ImageSource.gallery;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        setState(() => _avatarBytes = bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.couldNotSelectImage(e.toString()) ??
                  'Could not select image: $e',
            ),
          ),
        );
      }
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
            unawaited(_clearPendingReferralCode());
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

  Future<void> _clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_referral_code');
  }

  Widget _buildStep(bool isLoading, String? errorMsg) {
    return switch (_step) {
      _WizardStep.welcome => WelcomeScreen(
          onContinueWithPhone: () => _goTo(_WizardStep.phoneEntry),
          onContinueWithEmail: () => _goTo(_WizardStep.emailLogin),
          onCreateAccount: () => _goTo(_WizardStep.phoneEntry),
        ),
      _WizardStep.phoneEntry => PhoneEntryScreen(
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
      _WizardStep.otp => OtpScreen(
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
      _WizardStep.profileSetup => ProfileSetupScreen(
          isReturningUser: _isReturningUser,
          nameController: _nameController,
          emailController: _optEmailController,
          passwordController: _passwordController,
          confirmController: _confirmController,
          referralCodeController: _referralCodeController,
          obscurePassword: _obscurePassword,
          obscureConfirm: _obscureConfirm,
          formKey: _profileFormKey,
          isLoading: isLoading,
          errorMsg: errorMsg,
          onTogglePassword: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onToggleConfirm: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          avatarBytes: _avatarBytes,
          onPickAvatar: _pickAvatar,
          referralValidation: _referralValidation,
          onBack: () => _goTo(_WizardStep.otp),
          onSubmit: _onProfileSubmit,
        ),
      _WizardStep.success => SuccessScreen(
          onGoToMarketplace: () => context.go(AppRoutes.marketplace),
        ),
      _WizardStep.emailLogin => EmailLoginScreen(
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
      builder: (_) => const CountrySheet(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedCountry = picked;
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ── 0. Welcome ───────────────────────────────────────────────────────────────
