// lib/features/auth/presentation/pages/login_page.dart
//
// Dedicated Login Page — matching the theme background of the registration mockup.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/country_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/language_selector_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _usePhone = true;

  // phone
  CountryInfo _country = EastAfricaCountries.defaultCountry;
  final _phoneCtrl = TextEditingController();
  final _phonePassCtrl = TextEditingController(text: 'Test1234!');
  bool _obscurePhone = true;

  // email
  final _emailCtrl = TextEditingController();
  final _emailPassCtrl = TextEditingController(text: 'Test1234!');
  bool _obscureEmail = true;

  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>();

  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    for (final c in [_phoneCtrl, _phonePassCtrl, _emailCtrl, _emailPassCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _phoneCtrl.dispose();
    _phonePassCtrl.dispose();
    _emailCtrl.dispose();
    _emailPassCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_usePhone) {
      return _phoneCtrl.text.trim().length >= 7 &&
          _phonePassCtrl.text.isNotEmpty;
    }
    return _emailCtrl.text.trim().contains('@') &&
        _emailPassCtrl.text.isNotEmpty;
  }

  void _submit() {
    if (!_canSubmit || !(_formKey.currentState?.validate() ?? false)) return;
    if (_usePhone) {
      context.read<AuthBloc>().add(AuthPhoneSignInRequested(
            phone: '${_country.dialCode}${_phoneCtrl.text.trim()}',
            password: _phonePassCtrl.text,
          ));
    } else {
      context.read<AuthBloc>().add(AuthSignInRequested(
            email: _emailCtrl.text.trim(),
            password: _emailPassCtrl.text,
          ));
    }
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<CountryInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountrySheet(),
    );
    if (picked != null && mounted) setState(() => _country = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF11131A) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFFADADB8) : const Color(0xFF475569);
    final hintColor = isDark ? const Color(0xFF4B5563) : const Color(0xFF94A3B8);
    final dividerColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    const purpleColor = Color(0xFF7C3AED);

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) context.go(AppRoutes.marketplace);
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final errorMsg = state is AuthError ? state.message : null;

          return SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // ── Header Row: Back arrow + Language Chip ───────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 20, color: titleColor),
                          onPressed: () =>
                              context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        // Language Selector Chip
                        ValueListenableBuilder<Locale?>(
                          valueListenable: LanguageService.instance.notifier,
                          builder: (context, _, __) {
                            final currentLang = LanguageService.instance.currentLanguage;
                            return GestureDetector(
                              onTap: () => showLanguageSelectorSheet(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(currentLang.flag, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentLang.code.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: subtitleColor,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Title ──────────────────────────────────────────────
                    Text(
                      l10n.welcomeBack,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.loginToAccount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Phone / Email tabs ─────────────────────────────────
                    _buildTabs(dividerColor, subtitleColor, purpleColor, l10n),
                    const SizedBox(height: 28),

                    // ── Error banner ──────────────────────────────────────
                    if (errorMsg != null) ...[
                      _ErrorBanner(message: errorMsg),
                      const SizedBox(height: 16),
                    ],

                    // ── Input fields ──────────────────────────────────────
                    if (_usePhone)
                      _buildPhoneField(cardBg, cardBorder, titleColor, subtitleColor, hintColor)
                    else
                      _buildEmailField(cardBg, cardBorder, titleColor, hintColor, l10n),
                    const SizedBox(height: 12),

                    _buildPasswordField(cardBg, cardBorder, titleColor, hintColor, l10n),
                    const SizedBox(height: 18),

                    // ── Remember me + Forgot ───────────────────────────────
                    Row(
                      children: [
                        _Checkbox(
                          value: _rememberMe,
                          borderColor: cardBorder,
                          activeColor: purpleColor,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.rememberMe,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: subtitleColor,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              context.push(AppRoutes.resetPassword),
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: purpleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Login button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_canSubmit && !isLoading) ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purpleColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              purpleColor.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                l10n.logIn,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Sign up footer ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.dontHaveAccount,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.register),
                          child: Text(
                            l10n.signUp,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: purpleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────────────────
  Widget _buildTabs(Color dividerColor, Color subtitleColor, Color purpleColor, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            _buildTab(
              icon: Icons.smartphone_rounded,
              label: l10n.phone,
              active: _usePhone,
              subtitleColor: subtitleColor,
              purpleColor: purpleColor,
              onTap: () => setState(() => _usePhone = true),
            ),
            _buildTab(
              icon: Icons.email_outlined,
              label: l10n.email,
              active: !_usePhone,
              subtitleColor: subtitleColor,
              purpleColor: purpleColor,
              onTap: () => setState(() => _usePhone = false),
            ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool active,
    required Color subtitleColor,
    required Color purpleColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 16,
                      color: active ? purpleColor : subtitleColor),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? purpleColor : subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 2,
              decoration: BoxDecoration(
                color: active ? purpleColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Phone field ──────────────────────────────────────────────────────────
  Widget _buildPhoneField(Color cardBg, Color cardBorder, Color titleColor, Color subtitleColor, Color hintColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickCountry,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_country.flag,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    _country.dialCode,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: subtitleColor),
                ],
              ),
            ),
          ),
          Container(
              height: 22,
              width: 1,
              color: cardBorder,
              margin: const EdgeInsets.symmetric(horizontal: 10)),
          Expanded(
            child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: '7XXXXXXXX',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: hintColor,
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
    );
  }

  // ── Email field ───────────────────────────────────────────────────────────
  Widget _buildEmailField(Color cardBg, Color cardBorder, Color titleColor, Color hintColor, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.email_outlined, size: 18, color: hintColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: l10n.email,
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: hintColor,
                ),
              ),
              validator: (v) {
                if (v == null || !v.trim().contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Password field ────────────────────────────────────────────────────────
  Widget _buildPasswordField(Color cardBg, Color cardBorder, Color titleColor, Color hintColor, AppLocalizations l10n) {
    final obscure = _usePhone ? _obscurePhone : _obscureEmail;
    final ctrl = _usePhone ? _phonePassCtrl : _emailPassCtrl;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 18, color: hintColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: ctrl,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: l10n.password,
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: hintColor,
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_usePhone) {
                setState(() => _obscurePhone = !_obscurePhone);
              } else {
                setState(() => _obscureEmail = !_obscureEmail);
              }
            },
            child: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small checkbox widget
// ─────────────────────────────────────────────────────────────────────────────
class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.value,
    required this.borderColor,
    required this.activeColor,
    required this.onChanged,
  });

  final bool value;
  final Color borderColor;
  final Color activeColor;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: borderColor, width: 1.5),
        activeColor: activeColor,
        checkColor: Colors.white,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────
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
          const Icon(Icons.error_outline,
              color: AppColors.danger, size: 16),
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

// ─────────────────────────────────────────────────────────────────────────────
// Country selector bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _CountrySheet extends StatefulWidget {
  const _CountrySheet();

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _searchCtrl = TextEditingController();
  List<CountryInfo> _filtered = EastAfricaCountries.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = EastAfricaCountries.all
          .where((c) =>
              c.name.toLowerCase().contains(lower) ||
              c.dialCode.contains(lower))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _filter,
                  decoration: InputDecoration(
                    hintText: 'Search country…',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 18),
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
                  controller: scroll,
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
