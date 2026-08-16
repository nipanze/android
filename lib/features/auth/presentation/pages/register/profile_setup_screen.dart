// lib/features/auth/presentation/pages/register/profile_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import 'shared.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key, 
    required this.isReturningUser,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.referralCodeController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.formKey,
    required this.isLoading,
    required this.errorMsg,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onBack,
    required this.onSubmit,
    this.avatarBytes,
    this.onPickAvatar,
  });

  final bool isReturningUser;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final TextEditingController referralCodeController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final Uint8List? avatarBytes;
  final VoidCallback? onPickAvatar;

  bool _isFormValid() {
    if (isReturningUser) {
      return passwordController.text.length >= 8;
    }
    final name = nameController.text.trim();
    if (name.isEmpty) return false;

    final pwd = passwordController.text;
    if (pwd.length < 8) return false;

    final confirm = confirmController.text;
    if (confirm.isEmpty || confirm != pwd) return false;

    final email = emailController.text.trim();
    if (email.isNotEmpty) {
      if (!email.contains('@') || !email.contains('.')) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    StepProgressHeader(onBack: onBack, currentStep: 3),
                    const SizedBox(height: 24),

                    // ── Titles ─────────────────────────────────────────────
                    Text(
                      isReturningUser ? l10n.welcomeBack : l10n.tellUsAboutYou,
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
                          ? l10n.loginToAccount
                          : l10n.completeProfileSubtitle,
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
                                  color: AppColors.accent,
                                  width: 2.5,
                                ),
                                color: cardBgColor,
                                image: avatarBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(avatarBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: avatarBytes == null
                                  ? const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 30,
                                      color: AppColors.accent,
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
                                  color: AppColors.accent,
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
                      ErrorBanner(message: errorMsg!),
                    ],
                    const SizedBox(height: 20),

                    if (!isReturningUser) ...[
                      // Full Name
                      ProfileField(
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
                      ProfileField(
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

                      ProfileField(
                        label: 'Referral code (optional)',
                        controller: referralCodeController,
                        icon: Icons.campaign_outlined,
                        hintText: 'NIPANZE-GAVA123',
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        cardBorderColor: cardBorderColor,
                        titleColor: titleColor,
                        subtitleColor: subtitleColor,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9-]'),
                          ),
                          LengthLimitingTextInputFormatter(32),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Password creation
                      ProfileField(
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
                      ProfileField(
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
                      ProfileField(
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
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        nameController,
                        emailController,
                        passwordController,
                        confirmController,
                      ]),
                      builder: (context, _) {
                        final isValid = _isFormValid();
                        return SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                (isLoading || !isValid) ? null : onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.accent.withValues(alpha: 0.35),
                              disabledForegroundColor:
                                  Colors.white.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const ButtonLoader()
                                : Text(
                                    isReturningUser ? l10n.logIn : l10n.finish,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        );
                      },
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
class ProfileField extends StatelessWidget {
  const ProfileField({super.key, 
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
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
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
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

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
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: titleColor,
          ),
          cursorColor: AppColors.accent,
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
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
